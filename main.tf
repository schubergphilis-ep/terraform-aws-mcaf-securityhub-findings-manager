locals {
  account_id     = data.aws_caller_identity.current.account_id
  account_region = var.region != null ? var.region : data.aws_region.current.region
  kms_key_arn    = var.kms_key_arn != null ? var.kms_key_arn : module.kms_key[0].arn

  # Use a AWS provided layer to include Powertools to simplify the redistribution process.
  # Also see https://docs.powertools.aws.dev/lambda/python/latest/#lambda-layer.
  # See https://docs.aws.amazon.com/powertools/python/latest/getting-started/install/ for the available layer versions.
  powertools_layer_parts = split(":", data.aws_ssm_parameter.powertools_layer_arn.value)

  powertools_layer_arn = (
    var.powertools_layer_version != null
    ? "${join(":", slice(local.powertools_layer_parts, 0, length(local.powertools_layer_parts) - 1))}:${var.powertools_layer_version}"
    : data.aws_ssm_parameter.powertools_layer_arn.value
  )
}

# Data Source to get the access to Account ID in which Terraform is authorized and the region configured on the provider
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_ssm_parameter" "powertools_layer_arn" {
  name = "/aws/service/powertools/python/x86_64/${var.lambda_runtime}/latest"
}
