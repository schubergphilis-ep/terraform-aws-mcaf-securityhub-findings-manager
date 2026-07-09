data "aws_iam_policy_document" "findings_manager_lambda_iam_role" {
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

  statement {
    sid       = "S3GetObjectAccess"
    actions   = ["s3:GetObject"]
    resources = ["${module.findings_manager_bucket.arn}/*"]
  }

  statement {
    sid       = "S3ListBucketObjects"
    actions   = ["s3:ListBucket"]
    resources = ["${module.findings_manager_bucket.arn}/*"]
  }

  statement {
    sid       = "EC2DescribeRegionsAccess"
    actions   = ["ec2:DescribeRegions"]
    resources = ["*"]
  }

  statement {
    sid = "SecurityHubAccess"
    actions = [
      "securityhub:BatchUpdateFindings",
      "securityhub:GetFindings"
    ]
    resources = [
      "arn:aws:securityhub:${local.account_region}:${local.account_id}:hub/default"
    ]
  }

  statement {
    sid = "SecurityHubAccessList"
    actions = [
      "securityhub:ListFindingAggregators"
    ]
    resources = ["*"]
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
      var.kms_key_arn
    ]
  }

  statement {
    sid = "LambdaSQSAllow"
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    effect    = "Allow"
    resources = [aws_sqs_queue.findings_manager_rule_q.arn]
  }

}

# Push the Lambda code zip deployment package to s3
resource "aws_s3_object" "findings_manager_lambdas_deployment_package" {
  bucket      = module.findings_manager_bucket.id
  key         = "lambda_securityhub-findings-manager_${var.lambda_runtime}.zip"
  kms_key_id  = var.kms_key_arn
  region      = var.region
  source      = "${path.module}/files/pkg/lambda_securityhub-findings-manager_${var.lambda_runtime}.zip"
  source_hash = filemd5("${path.module}/files/pkg/lambda_securityhub-findings-manager_${var.lambda_runtime}.zip")
  tags        = var.tags
}

################################################################################
# Events Lambda
################################################################################

# Lambda function to manage Security Hub findings in response to an EventBridge event
module "findings_manager_events_lambda" {
  #checkov:skip=CKV_AWS_272:Code signing not used for now
  source  = "schubergphilis-ep/mcaf-lambda/aws"
  version = "~> 3.0.0"

  name                        = var.findings_manager_events_lambda.name
  create_s3_dummy_object      = false
  description                 = "Lambda to manage Security Hub findings in response to an EventBridge event"
  handler                     = "securityhub_events.lambda_handler"
  kms_key_arn                 = var.kms_key_arn
  layers                      = [local.powertools_layer_arn]
  log_retention               = 365
  memory_size                 = var.findings_manager_events_lambda.memory_size
  region                      = var.region
  runtime                     = var.lambda_runtime
  s3_bucket                   = module.findings_manager_bucket.name
  s3_key                      = aws_s3_object.findings_manager_lambdas_deployment_package.key
  s3_object_version           = aws_s3_object.findings_manager_lambdas_deployment_package.version_id
  security_group_egress_rules = var.findings_manager_events_lambda.security_group_egress_rules
  source_code_hash            = aws_s3_object.findings_manager_lambdas_deployment_package.checksum_sha256
  subnet_ids                  = var.subnet_ids
  tags                        = var.tags
  timeout                     = var.findings_manager_events_lambda.timeout

  environment = {
    S3_BUCKET_NAME              = module.findings_manager_bucket.name
    S3_OBJECT_NAME              = var.rules_s3_object_name
    LOG_LEVEL                   = var.findings_manager_events_lambda.log_level
    POWERTOOLS_LOGGER_LOG_EVENT = "false"
    POWERTOOLS_SERVICE_NAME     = "securityhub-findings-manager-events"
  }

  execution_role = {
    create_policy = true
    policy        = data.aws_iam_policy_document.findings_manager_lambda_iam_role.json
  }
}

# Primary EventBridge rule: matches newly-imported, actionable Security Hub findings.
#
# It fires on findings that are:
#   - RecordState ACTIVE               -> the finding still applies to a live resource
#   - Workflow.Status NEW or NOTIFIED  -> still open / awaiting action
#   - Severity.Label != INFORMATIONAL  -> ignore purely informational noise
#   - Compliance.Status != PASSED (or absent) -> the control is failing, not remediated
#
# The RecordState ACTIVE filter is what keeps this rule mutually exclusive from the autoclose
# rules below (which handle ARCHIVED, PASSED, RESOLVED and SUPPRESSED findings). Without it, an
# archived finding would match both this rule and securityhub_findings_deleted_resources
resource "aws_cloudwatch_event_rule" "securityhub_findings_events" {
  name        = "rule-${var.findings_manager_events_lambda.name}"
  description = "Detects open findings needing action: record state ACTIVE, workflow NEW/NOTIFIED, severity above informational, control not passing."
  region      = var.region
  tags        = var.tags

  event_pattern = <<EOF
{
  "source": ["aws.securityhub"],
  "detail-type": ["Security Hub Findings - Imported"],
  "detail": {
    "findings": {
      "Workflow": {
        "Status": ["NEW", "NOTIFIED"]
      },
      "RecordState": ["ACTIVE"],
      "Severity": {
        "Label": [{
          "anything-but": "INFORMATIONAL"
        }]
      },
      "Compliance": {
        "Status": [
        {"anything-but": "PASSED"},
        { "exists": false }
        ]
      }
    }
  }
}
EOF
}

# Autoclose rule: matches remediated findings (NOTIFIED + PASSED + ACTIVE).
# Only created when the Jira integration and autoclose are both enabled.
#
# When the underlying issue behind a finding is fixed, Security Hub flips Compliance.Status
# from FAILED to PASSED while the finding is still ACTIVE and Workflow.Status is NOTIFIED
# (a Jira ticket was already opened for it). Such findings must trigger autoclose of that
# ticket, but they are deliberately excluded from the primary rule above by its
# "anything-but: PASSED" filter, so this dedicated rule catches them.
#
# This rule can also not be merged into securityhub_findings_resolved_events: that rule has no
# Compliance.Status filter, so adding NOTIFIED to it would match a freshly-created ticket's
# own NOTIFIED event and immediately close the ticket we just opened.
resource "aws_cloudwatch_event_rule" "securityhub_findings_passed_events" {
  count = local.jira_autoclose_enabled ? 1 : 0

  name        = "rule-passed-${var.findings_manager_events_lambda.name}"
  description = "Detects remediated findings: workflow NOTIFIED (jira ticket exists), record state ACTIVE, control now PASSED."
  region      = var.region
  tags        = var.tags

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Workflow = {
          Status = ["NOTIFIED"]
        }
        RecordState = ["ACTIVE"]
        Compliance = {
          Status = ["PASSED"]
        }
      }
    }
  })
}

# Autoclose rule: matches findings for archived (deleted / no-longer-active) resources.
# Only created when the Jira integration and autoclose are both enabled.
#
# When a resource is deleted (or its finding is otherwise archived) Security Hub sets
# RecordState = ARCHIVED and the Jira ticket should be autoclosed. This deliberately does not
# filter on Compliance.Status: findings from products without a compliance concept (GuardDuty,
# Inspector, Macie, IAM Access Analyzer) have no Compliance field.
#
# Scoped to Workflow.Status NEW/NOTIFIED so it stays mutually exclusive from
# securityhub_findings_resolved_events (RESOLVED/SUPPRESSED) and, via the primary rule's
# RecordState ACTIVE filter, from securityhub_findings_events.
resource "aws_cloudwatch_event_rule" "securityhub_findings_deleted_resources" {
  count = local.jira_autoclose_enabled ? 1 : 0

  name        = "rule-deleted-${var.findings_manager_events_lambda.name}"
  description = "Detects archived findings (deleted/inactive resources): record state ARCHIVED, workflow status NEW or NOTIFIED, any compliance status."
  region      = var.region
  tags        = var.tags

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Workflow = {
          Status = ["NEW", "NOTIFIED"]
        }
        RecordState = ["ARCHIVED"]
      }
    }
  })
}

# Autoclose rule: matches findings that have been closed (RESOLVED, optionally SUPPRESSED).
# Only created when the Jira integration and autoclose are both enabled.
#
# This handles the "closed by decision" path, as opposed to the "remediated" and "deleted"
# paths covered by the two rules above:
#   - Workflow.Status RESOLVED           -> a human marked the finding resolved
#   - Workflow.Status SUPPRESSED         -> only included when autoclose_suppressed_findings
#                                           is enabled, so suppressing a finding also closes
#                                           its Jira ticket
#
# The ProductFields.PreviousComplianceStatus "anything-but: PASSED" (or absent) filter avoids
# reacting to findings that were already passing before being resolved - there is no
# meaningful ticket to close for those.
resource "aws_cloudwatch_event_rule" "securityhub_findings_resolved_events" {
  count = local.jira_autoclose_enabled ? 1 : 0

  name        = "rule-resolved-${var.findings_manager_events_lambda.name}"
  description = "Detects findings closed by decision: workflow RESOLVED (or SUPPRESSED if enabled), control not already passing before closure."
  region      = var.region
  tags        = var.tags

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Workflow = {
          Status = concat(
            ["RESOLVED"],
            try(var.jira_integration.autoclose_suppressed_findings, false) ? ["SUPPRESSED"] : []
          )
        }
        ProductFields = {
          PreviousComplianceStatus = [
            { "anything-but" : "PASSED" },
            { "exists" : false }
          ]
        }
      }
    }
  })
}

# Allow Eventbridge to invoke Security Hub Events Lambda function
resource "aws_lambda_permission" "eventbridge_invoke_findings_manager_events_lambda" {
  count = local.jira_integration_enabled ? 0 : 1

  action        = "lambda:InvokeFunction"
  function_name = var.findings_manager_events_lambda.name
  principal     = "events.amazonaws.com"
  region        = var.region
  source_arn    = aws_cloudwatch_event_rule.securityhub_findings_events.arn
}

# Add Security Hub Events Lambda function as a target to the EventBridge rule
resource "aws_cloudwatch_event_target" "findings_manager_events_lambda" {
  count = local.jira_integration_enabled ? 0 : 1

  arn    = module.findings_manager_events_lambda.arn
  region = var.region
  rule   = aws_cloudwatch_event_rule.securityhub_findings_events.name
}

################################################################################
# Trigger Lambda
################################################################################

# Lambda to manage Security Hub findings in response to S3 rules file uploads
module "findings_manager_trigger_lambda" {
  #checkov:skip=CKV_AWS_272:Code signing not used for now
  source  = "schubergphilis-ep/mcaf-lambda/aws"
  version = "~> 3.0.0"

  name                        = var.findings_manager_trigger_lambda.name
  create_s3_dummy_object      = false
  description                 = "Lambda to manage Security Hub findings in response to S3 rules file uploads"
  handler                     = "securityhub_trigger.lambda_handler"
  kms_key_arn                 = var.kms_key_arn
  layers                      = [local.powertools_layer_arn]
  log_retention               = 365
  memory_size                 = var.findings_manager_trigger_lambda.memory_size
  region                      = var.region
  runtime                     = var.lambda_runtime
  s3_bucket                   = module.findings_manager_bucket.name
  s3_key                      = aws_s3_object.findings_manager_lambdas_deployment_package.key
  s3_object_version           = aws_s3_object.findings_manager_lambdas_deployment_package.version_id
  security_group_egress_rules = var.findings_manager_trigger_lambda.security_group_egress_rules
  source_code_hash            = aws_s3_object.findings_manager_lambdas_deployment_package.checksum_sha256
  subnet_ids                  = var.subnet_ids
  tags                        = var.tags
  timeout                     = var.findings_manager_trigger_lambda.timeout

  environment = {
    S3_BUCKET_NAME              = module.findings_manager_bucket.name
    S3_OBJECT_NAME              = var.rules_s3_object_name
    LOG_LEVEL                   = var.findings_manager_trigger_lambda.log_level
    SQS_QUEUE_NAME              = aws_sqs_queue.findings_manager_rule_q.name
    POWERTOOLS_LOGGER_LOG_EVENT = "false"
    POWERTOOLS_SERVICE_NAME     = "securityhub-findings-manager-trigger"
  }

  execution_role = {
    create_policy = true
    policy        = data.aws_iam_policy_document.findings_manager_lambda_iam_role.json
  }
}

# Allow S3 to invoke S3 Trigger Lambda function
resource "aws_lambda_permission" "s3_invoke_findings_manager_trigger_lambda" {
  action         = "lambda:InvokeFunction"
  function_name  = var.findings_manager_trigger_lambda.name
  principal      = "s3.amazonaws.com"
  region         = var.region
  source_account = local.account_id
  source_arn     = module.findings_manager_bucket.arn
}

# Add Security Hub Trigger Lambda function as a target to rules S3 Object Creation Trigger Events
resource "aws_s3_bucket_notification" "findings_manager_trigger" {
  bucket = module.findings_manager_bucket.name
  region = var.region

  lambda_function {
    lambda_function_arn = module.findings_manager_trigger_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.rules_s3_object_name
    filter_suffix       = var.rules_s3_object_name
  }

  depends_on = [aws_lambda_permission.s3_invoke_findings_manager_trigger_lambda]
}

################################################################################
# Worker Lambda
################################################################################

# Lambda to manage Security Hub findings in response to S3 rules file uploads
module "findings_manager_worker_lambda" {
  #checkov:skip=CKV_AWS_272:Code signing not used for now
  source  = "schubergphilis-ep/mcaf-lambda/aws"
  version = "~> 3.0.0"

  name                        = var.findings_manager_worker_lambda.name
  create_s3_dummy_object      = false
  description                 = "Lambda to manage Security Hub findings in response to rules on SQS"
  handler                     = "securityhub_trigger_worker.lambda_handler"
  kms_key_arn                 = var.kms_key_arn
  layers                      = [local.powertools_layer_arn]
  log_retention               = 365
  memory_size                 = var.findings_manager_worker_lambda.memory_size
  region                      = var.region
  runtime                     = var.lambda_runtime
  s3_bucket                   = module.findings_manager_bucket.name
  s3_key                      = aws_s3_object.findings_manager_lambdas_deployment_package.key
  s3_object_version           = aws_s3_object.findings_manager_lambdas_deployment_package.version_id
  security_group_egress_rules = var.findings_manager_worker_lambda.security_group_egress_rules
  source_code_hash            = aws_s3_object.findings_manager_lambdas_deployment_package.checksum_sha256
  subnet_ids                  = var.subnet_ids
  tags                        = var.tags
  timeout                     = var.findings_manager_worker_lambda.timeout

  environment = {
    LOG_LEVEL                   = var.findings_manager_worker_lambda.log_level
    POWERTOOLS_LOGGER_LOG_EVENT = "false"
    POWERTOOLS_SERVICE_NAME     = "securityhub-findings-manager-worker"
  }

  execution_role = {
    create_policy = true
    policy        = data.aws_iam_policy_document.findings_manager_lambda_iam_role.json
  }
}

# Upload rules list to S3
resource "aws_s3_object" "rules" {
  count = var.rules_filepath == "" ? 0 : 1

  bucket       = module.findings_manager_bucket.name
  key          = var.rules_s3_object_name
  content_type = "application/x-yaml"
  content      = file(var.rules_filepath)
  region       = var.region
  source_hash  = filemd5(var.rules_filepath)
  tags         = var.tags

  # Even with this in place, the creation sometimes doesn't get picked up on a first deploy
  depends_on = [aws_s3_bucket_notification.findings_manager_trigger]
}

# SQS queue to distribute the rules to the lambda worker
resource "aws_sqs_queue" "findings_manager_rule_q" {
  name                       = "SecurityHubFindingsManagerRuleQueue"
  kms_master_key_id          = var.kms_key_arn
  region                     = var.region
  visibility_timeout_seconds = var.findings_manager_worker_lambda.timeout
  # Queue visibility timeout needs to >= Function timeout
}

resource "aws_sqs_queue_policy" "findings_manager_rule_sqs_policy" {
  policy    = data.aws_iam_policy_document.findings_manager_rule_sqs_policy_doc.json
  queue_url = aws_sqs_queue.findings_manager_rule_q.id
  region    = var.region
}

resource "aws_sqs_queue" "dlq_for_findings_manager_rule_q" {
  name              = "DlqForSecurityHubFindingsManagerRuleQueue"
  kms_master_key_id = var.kms_key_arn
  region            = var.region
}

resource "aws_sqs_queue_redrive_policy" "redrive_policy" {
  queue_url = aws_sqs_queue.findings_manager_rule_q.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq_for_findings_manager_rule_q.arn
    maxReceiveCount     = 10
  })
  region = var.region
}

resource "aws_sqs_queue_redrive_allow_policy" "dead_letter_allow_policy" {
  queue_url = aws_sqs_queue.dlq_for_findings_manager_rule_q.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.findings_manager_rule_q.arn]
  })
  region = var.region
}

data "aws_iam_policy_document" "findings_manager_rule_sqs_policy_doc" {
  statement {
    actions = [
      "SQS:SendMessage"
    ]
    resources = [aws_sqs_queue.findings_manager_rule_q.arn]
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
    condition {
      test     = "ArnEquals"
      values   = [module.findings_manager_trigger_lambda.name]
      variable = "aws:SourceArn"
    }
  }
}

# The SQS queue with rules triggers the worker lambda
resource "aws_lambda_event_source_mapping" "sqs_to_worker" {
  enabled          = true
  event_source_arn = aws_sqs_queue.findings_manager_rule_q.arn
  function_name    = module.findings_manager_worker_lambda.name
  # assumes a rule processing time of 30 sec average (which is high)
  batch_size                         = var.findings_manager_worker_lambda.timeout / 30
  maximum_batching_window_in_seconds = 60
  region                             = var.region

  scaling_config {
    maximum_concurrency = 4 #  to prevent Security Hub API rate limits
  }
}
