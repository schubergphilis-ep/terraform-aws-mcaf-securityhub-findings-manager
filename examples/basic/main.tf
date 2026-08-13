provider "aws" {}

# It can take a long time before S3 notifications become active
# You may want to deploy an empty set of rules before the actual ones or do a trick with yaml comments
module "aws_securityhub_findings_manager" {
  source = "../../"

  rules_filepath = "${path.module}/../rules.yaml"
  tags           = { Terraform = true }

  kms_key_configuration = {
    iam_arns_administrator = ["arn:aws:iam::123456789012:role/key-admin"]
  }
}
