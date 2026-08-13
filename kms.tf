data "aws_iam_policy_document" "kms_key_policy" {
  count = var.kms_key_arn == null ? 1 : 0

  statement {
    sid = "AllowCloudWatchLogsForFindingsManager"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
    ]
    effect    = "Allow"
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${local.account_region}.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"

      values = [
        "arn:aws:logs:${local.account_region}:${data.aws_caller_identity.current.account_id}:*"
      ]
    }
  }

  statement {
    sid = "AllowFindingsManagerViaS3AndSqs"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
    ]
    effect    = "Allow"
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"

      values = [
        "s3.${local.account_region}.amazonaws.com",
        "sqs.${local.account_region}.amazonaws.com",
      ]
    }
  }

  statement {
    sid = "AllowFindingsManagerViaLambda"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
    ]
    effect    = "Allow"
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"

      values = ["lambda.${local.account_region}.amazonaws.com"]
    }
  }

  statement {
    sid = "AllowFindingsManagerViaSecretStores"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]
    effect    = "Allow"
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"

      values = [
        "events.${local.account_region}.amazonaws.com",
        "secretsmanager.${local.account_region}.amazonaws.com",
        "ssm.${local.account_region}.amazonaws.com",
      ]
    }
  }
}

module "kms_key" {
  count = var.kms_key_arn == null ? 1 : 0

  source  = "schubergphilis-ep/mcaf-kms/aws"
  version = "~> 3.0.0"

  region      = var.region
  name        = var.kms_key_configuration.name
  description = "KMS key used for encrypting all Security Hub Findings Manager resources"
  tags        = var.tags

  default_policy = {
    iam_arns_administrator  = var.kms_key_configuration.iam_arns_administrator
    source_policy_documents = [data.aws_iam_policy_document.kms_key_policy[0].json]
  }
}
