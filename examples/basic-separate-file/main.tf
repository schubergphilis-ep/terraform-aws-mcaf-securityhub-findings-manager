locals {
  s3_bucket_name = "securityhub-findings-manager-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

provider "aws" {}

module "aws_securityhub_findings_manager" {
  source = "../../"

  s3_bucket_name = local.s3_bucket_name
  tags           = { Terraform = true }

  kms_key_configuration = {
    iam_arns_administrator = ["arn:aws:iam::123456789012:role/key-admin"]
  }
}

# It can take a long time before S3 notifications become active
# You may want to deploy this resource a few minutes after those above
resource "aws_s3_object" "rules" {
  bucket       = local.s3_bucket_name
  key          = "rules.yaml"
  content_type = "application/x-yaml"
  content      = file("${path.module}/../rules.yaml")
  source_hash  = filemd5("${path.module}/../rules.yaml")

  depends_on = [module.aws_securityhub_findings_manager]
}
