locals {
  # Check if Jira integration is enabled (at least 1 instance defined)
  jira_integration_enabled = var.jira_integration != null && length([
    for instance_key, instance in var.jira_integration.instances : instance
    if instance.enabled != false
  ]) > 0

  # Check if Jira autoclose is enabled (requires the Jira integration itself to be enabled).
  jira_autoclose_enabled = local.jira_integration_enabled && try(var.jira_integration.autoclose_enabled, false)

  # Collect all SecretsManager ARNs from all enabled instances
  jira_secretsmanager_arns = var.jira_integration != null ? [
    for instance_key, instance in var.jira_integration.instances : instance.credentials_secretsmanager_arn
    if instance.enabled != false && instance.credentials_secretsmanager_arn != null && instance.credentials_secretsmanager_arn != "REDACTED"
  ] : []

  # Collect all SSM parameter ARNs from all enabled instances
  jira_ssm_arns = var.jira_integration != null ? [
    for instance_key, instance in var.jira_integration.instances : instance.credentials_ssm_secret_arn
    if instance.enabled != false && instance.credentials_ssm_secret_arn != null && instance.credentials_ssm_secret_arn != "REDACTED"
  ] : []

  jira_instances = var.jira_integration == null ? {} : var.jira_integration.instances

  # Per-instance config shipped to the Jira lambda as the JIRA_INSTANCES_CONFIG environment
  # variable. Lambda caps the total size of all environment variables at 4 KB, which a config with
  # many instances can exceed, so attributes that convey nothing are dropped instead of being
  # serialised as `null`, `{}`, `[]` or `false`. The lambda reads each of them with a matching
  # `.get()` default, so an absent key produces the same behaviour as the value dropped here.
  #
  # enabled is the exception and is always emitted, so a disabled instance can never end up one
  # dropped key away from being silently re-enabled.
  jira_instances_config = {
    for instance_key, instance in local.jira_instances : instance_key => merge(
      {
        enabled     = instance.enabled
        project_key = instance.project_key
      },
      instance.credentials_secretsmanager_arn == null ? {} : { credentials_secretsmanager_arn = instance.credentials_secretsmanager_arn },
      instance.credentials_ssm_secret_arn == null ? {} : { credentials_ssm_secret_arn = instance.credentials_ssm_secret_arn },
      instance.default_instance == false ? {} : { default_instance = instance.default_instance },
      instance.include_intermediate_transition == null ? {} : { include_intermediate_transition = instance.include_intermediate_transition },
      instance.issue_type == null ? {} : { issue_type = instance.issue_type },
      length(instance.include_account_ids) == 0 ? {} : { include_account_ids = instance.include_account_ids },
      length(instance.issue_custom_fields) == 0 ? {} : { issue_custom_fields = instance.issue_custom_fields },
    )
  }
}

data "aws_iam_policy_document" "jira_lambda_iam_role" {
  count = local.jira_integration_enabled ? 1 : 0

  statement {
    sid = "TrustEventsToStoreLogEvent"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${local.account_region}:${local.account_id}:*"
    ]
  }

  # Grant access to ALL SecretsManager secrets from all instances
  dynamic "statement" {
    for_each = length(local.jira_secretsmanager_arns) > 0 ? { "SecretManagerAccess" = true } : {}

    content {
      sid       = "SecretManagerAccess"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = local.jira_secretsmanager_arns
    }
  }

  # Grant access to ALL SSM parameters from all instances
  dynamic "statement" {
    for_each = length(local.jira_ssm_arns) > 0 ? { "SSMParameterAccess" = true } : {}

    content {
      sid       = "SSMParameterAccess"
      actions   = ["ssm:GetParameter", "ssm:GetParameterHistory"]
      resources = local.jira_ssm_arns
    }
  }

  statement {
    sid = "SecurityHubAccess"
    actions = [
      "securityhub:BatchUpdateFindings"
    ]
    resources = [
      "arn:aws:securityhub:${local.account_region}:${local.account_id}:hub/default"
    ]
    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "securityhub:ASFFSyntaxPath/Workflow.Status"
      values = local.jira_autoclose_enabled ? (
        try(var.jira_integration.autoclose_suppressed_findings, false) ?
        ["NOTIFIED", "RESOLVED", "SUPPRESSED"] :
        ["NOTIFIED", "RESOLVED"]
      ) : ["NOTIFIED"]
    }
  }

  statement {
    sid = "LambdaKMSAccess"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*"
    ]
    effect = "Allow"
    resources = [
      local.kms_key_arn
    ]
  }
}

# Upload the zip archive to S3
resource "aws_s3_object" "jira_lambda_deployment_package" {
  count = local.jira_integration_enabled ? 1 : 0

  bucket      = module.findings_manager_bucket.id
  key         = "lambda_${var.jira_integration.lambda_settings.name}_${var.lambda_runtime}.zip"
  kms_key_id  = local.kms_key_arn
  region      = var.region
  source      = "${path.module}/files/pkg/lambda_findings-manager-jira_${var.lambda_runtime}.zip"
  source_hash = filemd5("${path.module}/files/pkg/lambda_findings-manager-jira_${var.lambda_runtime}.zip")
  tags        = var.tags
}

# Lambda function to create Jira ticket for Security Hub findings and set the workflow state to NOTIFIED
module "jira_lambda" {
  #checkov:skip=CKV_AWS_272:Code signing not used for now
  count = local.jira_integration_enabled ? 1 : 0

  source  = "schubergphilis-ep/mcaf-lambda/aws"
  version = "~> 3.0.0"

  name                        = var.jira_integration.lambda_settings.name
  create_s3_dummy_object      = false
  description                 = "Lambda to create jira ticket and set the Security Hub workflow status to notified"
  handler                     = "findings_manager_jira.lambda_handler"
  kms_key_arn                 = local.kms_key_arn
  log_retention               = 365
  memory_size                 = var.jira_integration.lambda_settings.memory_size
  region                      = var.region
  runtime                     = var.lambda_runtime
  s3_bucket                   = module.findings_manager_bucket.name
  s3_key                      = aws_s3_object.jira_lambda_deployment_package[0].key
  s3_object_version           = aws_s3_object.jira_lambda_deployment_package[0].version_id
  security_group_egress_rules = var.jira_integration.security_group_egress_rules
  source_code_hash            = aws_s3_object.jira_lambda_deployment_package[0].checksum_sha256
  subnet_ids                  = var.subnet_ids
  tags                        = var.tags
  timeout                     = var.jira_integration.lambda_settings.timeout

  # Since the value is read from a public SSM parameter,
  # it is explicitly marked as nonsensitive to provide visibility in terraform plans.
  layers = [nonsensitive(local.powertools_layer_arn)]

  environment = {
    # Multi-instance configuration as JSON, with unset optional attributes omitted
    JIRA_INSTANCES_CONFIG = jsonencode(local.jira_instances_config)

    # Global settings
    EXCLUDE_ACCOUNT_FILTER    = jsonencode(var.jira_integration.exclude_account_ids)
    JIRA_AUTOCLOSE_COMMENT    = var.jira_integration.autoclose_comment
    JIRA_AUTOCLOSE_TRANSITION = var.jira_integration.autoclose_transition_name

    # Logging settings
    LOG_LEVEL                   = var.jira_integration.lambda_settings.log_level
    POWERTOOLS_LOGGER_LOG_EVENT = "false"
    POWERTOOLS_SERVICE_NAME     = "securityhub-findings-manager-jira"
  }

  execution_role = {
    create_policy = true
    policy        = data.aws_iam_policy_document.jira_lambda_iam_role[0].json
  }
}
