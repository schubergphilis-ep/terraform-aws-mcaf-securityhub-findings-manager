mock_provider "aws" {
  override_data {
    target = data.aws_region.current
    values = {
      name = "eu-west-1"
    }
  }

  override_data {
    target = data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/fake-role-for-tests"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::aws:policy/fake-policy"
    }
  }

  mock_resource "aws_cloudwatch_event_rule" {
    defaults = {
      arn = "arn:aws:events:eu-west-1:123456789012:rule/fake-rule-for-tests"
    }
  }

  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:eu-west-1:123456789012:fake-queue"
      url = "https://sqs.eu-west-1.amazonaws.com/123456789012/fake-queue"
    }
  }
}

override_module {
  target = module.findings_manager_bucket
  outputs = {
    id   = "securityhub-findings-manager-artifacts"
    name = "securityhub-findings-manager-artifacts"
    arn  = "arn:aws:s3:::securityhub-findings-manager-artifacts"
  }
}

override_module {
  target = module.access_logs
  outputs = {
    name = "securityhub-findings-manager-artifacts-access-logs"
    arn  = "arn:aws:s3:::securityhub-findings-manager-artifacts-access-logs"
  }
}

override_module {
  target = module.findings_manager_events_lambda
  outputs = {
    name = "securityhub-findings-manager-events"
    arn  = "arn:aws:lambda:eu-west-1:123456789012:function:securityhub-findings-manager-events"
  }
}

override_module {
  target = module.findings_manager_trigger_lambda
  outputs = {
    name = "securityhub-findings-manager-trigger"
    arn  = "arn:aws:lambda:eu-west-1:123456789012:function:securityhub-findings-manager-trigger"
  }
}

override_module {
  target = module.findings_manager_worker_lambda
  outputs = {
    name = "securityhub-findings-manager-worker"
    arn  = "arn:aws:lambda:eu-west-1:123456789012:function:securityhub-findings-manager-worker"
  }
}

run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "core_resources_created" {
  command = plan

  variables {
    kms_key_arn    = "arn:aws:kms:eu-west-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    s3_bucket_name = "securityhub-findings-manager-test"
    rules_filepath = "examples/rules.yaml"
  }

  assert {
    condition     = aws_cloudwatch_event_rule.securityhub_findings_events.name != ""
    error_message = "EventBridge rule should be created"
  }

  assert {
    condition     = aws_sqs_queue.findings_manager_rule_q.name == "SecurityHubFindingsManagerRuleQueue"
    error_message = "SQS queue should be created"
  }

  assert {
    condition     = aws_sqs_queue.dlq_for_findings_manager_rule_q.name != ""
    error_message = "DLQ should be created"
  }

  assert {
    condition     = length(module.access_logs) == 1
    error_message = "Expected the access logs bucket to be created when s3_access_logging is enabled (default)."
  }

  assert {
    condition     = local.access_logs_bucket_name == "securityhub-findings-manager-test-access-logs"
    error_message = "Expected the access logs bucket to be named '<s3_bucket_name>-access-logs'."
  }
}

run "access_logging_long_bucket_name" {
  command = plan

  variables {
    kms_key_arn    = "arn:aws:kms:eu-west-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    s3_bucket_name = "mns-core-audit-securityhub-findings-manager-artifacts"
    rules_filepath = "examples/rules.yaml"
  }

  assert {
    condition     = local.access_logs_bucket_name == "mns-core-audit-securityhub-findings-manager-artifac-access-logs"
    error_message = "Expected s3_bucket_name to be truncated so the access logs bucket name fits the 63 character limit."
  }
}

run "access_logging_long_bucket_name_trailing_hyphen" {
  command = plan

  variables {
    kms_key_arn    = "arn:aws:kms:eu-west-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    s3_bucket_name = "mns-core-audit-securityhub-findings-manager-bucket-prod"
    rules_filepath = "examples/rules.yaml"
  }

  assert {
    condition     = local.access_logs_bucket_name == "mns-core-audit-securityhub-findings-manager-bucket-access-logs"
    error_message = "Expected the trailing '-' left by truncating s3_bucket_name to be trimmed."
  }
}

run "access_logging_disabled" {
  command = plan

  variables {
    kms_key_arn       = "arn:aws:kms:eu-west-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    s3_access_logging = { enabled = false }
    s3_bucket_name    = "securityhub-findings-manager-test"
    rules_filepath    = "examples/rules.yaml"
  }

  assert {
    condition     = length(module.access_logs) == 0
    error_message = "Expected no access logs bucket to be created when s3_access_logging is disabled."
  }
}

run "access_logging_invalid_retention" {
  command = plan

  variables {
    kms_key_arn       = "arn:aws:kms:eu-west-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    s3_access_logging = { expiration_days = 30 }
    s3_bucket_name    = "securityhub-findings-manager-test"
    rules_filepath    = "examples/rules.yaml"
  }

  expect_failures = [
    var.s3_access_logging,
  ]
}
