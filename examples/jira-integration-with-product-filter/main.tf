locals {
  s3_bucket_name = "securityhub-findings-manager-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

provider "aws" {}

# Example: Create Jira tickets only for Security Hub findings.
#
# Product filtering comes in two flavours, which are mutually exclusive - set at most one of them:
#
#   include_product_names = ["Security Hub"] # allow list: only these products create tickets
#   exclude_product_names = ["Inspector"]    # deny list: every product except these creates tickets
#
# The deny list variant is shown below this module.
module "securityhub_findings_manager" {
  source = "../.."

  s3_bucket_name = local.s3_bucket_name

  jira_integration = {
    include_product_names = ["Security Hub"]

    instances = {
      "default" = {
        default_instance               = true
        project_key                    = "SEC"
        credentials_secretsmanager_arn = aws_secretsmanager_secret.jira_credentials.arn

        issue_custom_fields = {
          "customfield_10001" = "Security Team"
        }
      }
    }
  }

  kms_key_configuration = {
    iam_arns_administrator = ["arn:aws:iam::123456789012:role/key-admin"]
  }
}

# Example: Create Jira tickets for every product except Inspector.
module "securityhub_findings_manager_exclude_inspector" {
  source = "../.."

  s3_bucket_name = local.s3_bucket_name

  jira_integration = {
    exclude_product_names = ["Inspector"]

    instances = {
      "default" = {
        default_instance               = true
        project_key                    = "SEC"
        credentials_secretsmanager_arn = aws_secretsmanager_secret.jira_credentials.arn

        issue_custom_fields = {
          "customfield_10001" = "Security Team"
        }
      }
    }
  }

  kms_key_configuration = {
    iam_arns_administrator = ["arn:aws:iam::123456789012:role/key-admin"]
  }
}

# Secret for Jira credentials
resource "aws_secretsmanager_secret" "jira_credentials" {
  name       = "jira-credentials"
  kms_key_id = module.securityhub_findings_manager.kms_key_arn
}

# Example secret value (populate with your actual credentials)
# aws secretsmanager put-secret-value \
#   --secret-id jira-credentials \
#   --secret-string '{"jira_url":"https://your-domain.atlassian.net","jira_username":"your-email@example.com","jira_api_token":"your-api-token"}'
