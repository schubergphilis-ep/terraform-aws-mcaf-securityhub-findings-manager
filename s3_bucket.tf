locals {
  # S3 bucket names are limited to 63 characters: truncate the bucket name to fit the "-access-logs" suffix,
  # and trim any "-" or "." the truncation leaves at the end
  access_logs_bucket_name = var.s3_bucket_name != null ? "${trim(substr(var.s3_bucket_name, 0, 51), "-.")}-access-logs" : null
}

# S3 bucket to store Lambda artifacts and the rules list
module "findings_manager_bucket" {
  #checkov:skip=CKV_AWS_145:Bug in CheckOV https://github.com/bridgecrewio/checkov/issues/3847
  #checkov:skip=CKV_AWS_19:Bug in CheckOV https://github.com/bridgecrewio/checkov/issues/3847
  source  = "schubergphilis-ep/mcaf-s3/aws"
  version = "~> 4.0.0"

  name        = var.s3_bucket_name
  name_prefix = var.s3_bucket_name != null ? null : "findings-manager-"
  kms_key_arn = local.kms_key_arn
  region      = var.region
  tags        = var.tags

  lifecycle_rule = [
    {
      id      = "default"
      enabled = true

      abort_incomplete_multipart_upload = {
        days_after_initiation = 7
      }

      expiration = {
        expired_object_delete_marker = true
      }

      noncurrent_version_expiration = {
        noncurrent_days = 7
      }
    }
  ]

  logging = var.s3_access_logging.enabled ? {
    target_bucket = module.access_logs[0].name
    target_prefix = "logs/"
    target_object_key_format = {
      format_type           = "partitioned"
      partition_date_source = "EventTime"
    }
  } : null
}

# S3 bucket to store the server access logs of the findings manager bucket
module "access_logs" {
  count = var.s3_access_logging.enabled ? 1 : 0

  source  = "schubergphilis-ep/mcaf-s3/aws"
  version = "~> 4.0.0"

  name        = local.access_logs_bucket_name
  name_prefix = var.s3_bucket_name != null ? null : "findings-manager-access-logs-"
  region      = var.region
  tags        = var.tags

  lifecycle_rule = [
    {
      id      = "RetentionPolicy"
      enabled = true

      abort_incomplete_multipart_upload = {
        days_after_initiation = 3
      }

      expiration = {
        days = var.s3_access_logging.expiration_days
      }

      noncurrent_version_expiration = {
        noncurrent_days = 7
      }

      transition = [
        {
          days          = var.s3_access_logging.transition_days
          storage_class = var.s3_access_logging.transition_storage_class
        }
      ]
    },
    {
      id         = "expired-delete-markers"
      enabled    = true
      expiration = { expired_object_delete_marker = true }
    },
  ]

  logging_source_bucket_arns = [module.findings_manager_bucket.arn]
}
