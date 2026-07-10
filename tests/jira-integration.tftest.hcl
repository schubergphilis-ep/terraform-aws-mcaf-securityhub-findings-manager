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

  mock_resource "aws_sfn_state_machine" {
    defaults = {
      arn = "arn:aws:states:eu-west-1:123456789012:stateMachine:fake-state-machine"
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

override_module {
  target = module.jira_lambda[0]
  outputs = {
    name = "securityhub-findings-manager-jira"
    arn  = "arn:aws:lambda:eu-west-1:123456789012:function:securityhub-findings-manager-jira"
  }
}

override_module {
  target = module.jira_step_function_iam_role[0]
  outputs = {
    arn = "arn:aws:iam::123456789012:role/SecurityHubFindingsManagerJiraStepFunction"
  }
}

override_module {
  target = module.jira_eventbridge_iam_role[0]
  outputs = {
    arn = "arn:aws:iam::123456789012:role/SecurityHubFindingsManagerJiraEventBridge"
  }
}

run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "jira_disabled" {
  command = plan

  variables {
    kms_key_arn    = "arn:aws:kms:eu-west-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    s3_bucket_name = "securityhub-findings-manager-jira"
    rules_filepath = "examples/rules.yaml"

    jira_integration = null
  }

  assert {
    condition     = length(module.jira_lambda) == 0
    error_message = "Jira lambda should not be created when disabled"
  }
}

run "jira_enabled" {
  command = plan

  variables {
    kms_key_arn    = "arn:aws:kms:eu-west-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    s3_bucket_name = "securityhub-findings-manager-jira"
    rules_filepath = "examples/rules.yaml"

    jira_integration = {
      instances = {
        prod = {
          include_account_ids            = ["123456789000"]
          project_key                    = "SEC"
          credentials_secretsmanager_arn = "arn:aws:secretsmanager:eu-west-1:123456789012:secret:jira-creds"
        }
      }

      security_group_egress_rules = [{
        cidr_ipv4   = "0.0.0.0/0"
        description = "Allow all outbound traffic"
      }]
    }
  }

  assert {
    condition     = length(module.jira_lambda) == 1
    error_message = "Jira lambda should be created when enabled"
  }

  assert {
    condition     = length(aws_sfn_state_machine.jira_orchestrator) == 1
    error_message = "Step Function should be created"
  }

  assert {
    condition     = length(aws_cloudwatch_event_target.jira_orchestrator) == 1
    error_message = "EventBridge target should be created"
  }

  assert {
    condition     = length(aws_cloudwatch_event_target.jira_orchestrator_resolved) == 0
    error_message = "Resolved findings target should not exist when autoclose is disabled"
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.securityhub_findings_passed_events) == 0
    error_message = "Passed-findings rule should not exist when autoclose is disabled"
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.securityhub_findings_deleted_resources) == 0
    error_message = "Deleted-resources rule should not exist when autoclose is disabled"
  }

  assert {
    condition     = length(aws_cloudwatch_event_target.jira_orchestrator_passed) == 0
    error_message = "Passed-findings target should not exist when autoclose is disabled"
  }

  assert {
    condition     = length(aws_cloudwatch_event_target.jira_orchestrator_deleted_resources) == 0
    error_message = "Deleted-resources target should not exist when autoclose is disabled"
  }

  # The ChoiceSuppressor bypass for remediated (PASSED/NOT_AVAILABLE) findings is part of
  # the autoclose feature: without autoclose there is no close gate to feed, and
  # NOT_AVAILABLE findings (delivered by the primary rule regardless of autoclose) must
  # keep flowing through the suppression lambda.
  assert {
    condition     = !strcontains(jsonencode(jsondecode(aws_sfn_state_machine.jira_orchestrator[0].definition).States.ChoiceSuppressor.Choices), "NOT_AVAILABLE")
    error_message = "ChoiceSuppressor must not bypass suppression for NOT_AVAILABLE findings when autoclose is disabled"
  }
}

run "jira_multiple_instances" {
  command = plan

  variables {
    kms_key_arn    = "arn:aws:kms:eu-west-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    s3_bucket_name = "securityhub-findings-manager-jira-multi"
    rules_filepath = "examples/rules.yaml"

    jira_integration = {
      instances = {
        prod = {
          include_account_ids            = ["123456789000"]
          project_key                    = "SEC"
          credentials_secretsmanager_arn = "arn:aws:secretsmanager:eu-west-1:123456789012:secret:jira-prod-creds"
        }
        dev = {
          include_account_ids            = ["123456789001"]
          project_key                    = "DEV"
          credentials_secretsmanager_arn = "arn:aws:secretsmanager:eu-west-1:123456789012:secret:jira-dev-creds"
        }
      }

      security_group_egress_rules = [{
        cidr_ipv4   = "0.0.0.0/0"
        description = "Allow all outbound traffic"
      }]
    }
  }

  assert {
    condition     = length(module.jira_lambda) == 1
    error_message = "Jira lambda should be created when enabled"
  }

  assert {
    condition     = length(aws_sfn_state_machine.jira_orchestrator) == 1
    error_message = "Step Function should be created"
  }
}

run "jira_autoclose" {
  command = plan

  variables {
    kms_key_arn    = "arn:aws:kms:eu-west-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    s3_bucket_name = "securityhub-findings-manager-jira-autoclose"
    rules_filepath = "examples/rules.yaml"

    jira_integration = {
      autoclose_enabled         = true
      autoclose_comment         = "Auto-closing ticket"
      autoclose_transition_name = "Done"

      instances = {
        prod = {
          include_account_ids            = ["123456789000"]
          project_key                    = "SEC"
          credentials_secretsmanager_arn = "arn:aws:secretsmanager:eu-west-1:123456789012:secret:jira-creds"
        }
      }

      security_group_egress_rules = [{
        cidr_ipv4   = "0.0.0.0/0"
        description = "Allow all outbound traffic"
      }]
    }
  }

  assert {
    condition     = length(aws_cloudwatch_event_target.jira_orchestrator_resolved) == 1
    error_message = "Resolved findings target should be created when autoclose is enabled"
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.securityhub_findings_resolved_events) == 1
    error_message = "Resolved findings rule should be created when autoclose is enabled"
  }

  # --- Autoclose rules/targets are created ------------------------------------------------

  assert {
    condition     = length(aws_cloudwatch_event_rule.securityhub_findings_passed_events) == 1
    error_message = "Passed-findings rule should be created when autoclose is enabled"
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.securityhub_findings_deleted_resources) == 1
    error_message = "Deleted-resources rule should be created when autoclose is enabled"
  }

  assert {
    condition     = length(aws_cloudwatch_event_target.jira_orchestrator_passed) == 1
    error_message = "Passed-findings target should be created when autoclose is enabled"
  }

  assert {
    condition     = length(aws_cloudwatch_event_target.jira_orchestrator_deleted_resources) == 1
    error_message = "Deleted-resources target should be created when autoclose is enabled"
  }

  # --- Deleted-resources rule is product-agnostic  ----------
  # It must key on RecordState = ARCHIVED with NO Compliance filter, otherwise findings from
  # products without a Compliance field (GuardDuty, Inspector, Macie, IAM Access Analyzer)
  # would never autoclose.

  assert {
    condition     = contains(jsondecode(aws_cloudwatch_event_rule.securityhub_findings_deleted_resources[0].event_pattern).detail.findings.RecordState, "ARCHIVED")
    error_message = "Deleted-resources rule must match RecordState ARCHIVED"
  }

  assert {
    condition     = !contains(keys(jsondecode(aws_cloudwatch_event_rule.securityhub_findings_deleted_resources[0].event_pattern).detail.findings), "Compliance")
    error_message = "Deleted-resources rule must NOT filter on Compliance (would silently miss products with no Compliance field)"
  }

  assert {
    condition     = toset(jsondecode(aws_cloudwatch_event_rule.securityhub_findings_deleted_resources[0].event_pattern).detail.findings.Workflow.Status) == toset(["NEW", "NOTIFIED"])
    error_message = "Deleted-resources rule must match workflow NEW and NOTIFIED"
  }

  # --- Passed (remediated) rule shape -----------------------------------------------------

  assert {
    condition     = contains(jsondecode(aws_cloudwatch_event_rule.securityhub_findings_passed_events[0].event_pattern).detail.findings.Compliance.Status, "PASSED")
    error_message = "Passed-findings rule must match Compliance PASSED"
  }

  assert {
    condition     = contains(jsondecode(aws_cloudwatch_event_rule.securityhub_findings_passed_events[0].event_pattern).detail.findings.RecordState, "ACTIVE")
    error_message = "Passed-findings rule must match RecordState ACTIVE"
  }

  # --- Rules are mutually exclusive  --------------------
  # A single finding event must never match two rules, or EventBridge starts two concurrent
  # Step Function executions against the same finding.

  assert {
    condition     = jsondecode(aws_cloudwatch_event_rule.securityhub_findings_events.event_pattern).detail.findings.RecordState == ["ACTIVE"]
    error_message = "Primary rule must be scoped to RecordState ACTIVE (disjoint from the archived-findings rule)"
  }

  assert {
    condition     = jsondecode(aws_cloudwatch_event_rule.securityhub_findings_events.event_pattern).detail.findings.Compliance.Status[0]["anything-but"] == "PASSED"
    error_message = "Primary rule must exclude PASSED findings (disjoint from the passed-events rule)"
  }

  assert {
    condition = length(setintersection(
      toset(jsondecode(aws_cloudwatch_event_rule.securityhub_findings_events.event_pattern).detail.findings.RecordState),
      toset(jsondecode(aws_cloudwatch_event_rule.securityhub_findings_deleted_resources[0].event_pattern).detail.findings.RecordState)
    )) == 0
    error_message = "Primary and deleted-resources rules must be disjoint by RecordState"
  }

  assert {
    condition     = !contains(jsondecode(aws_cloudwatch_event_rule.securityhub_findings_resolved_events[0].event_pattern).detail.findings.Workflow.Status, "NOTIFIED")
    error_message = "Resolved rule must not match NOTIFIED (disjoint from the primary/deleted rules)"
  }

  # --- Step Function suppression bypass mirrors the close gate ----------------------------
  # The ChoiceSuppressor remediated-finding bypass must treat NOT_AVAILABLE like PASSED:
  # both are close triggers in ChoiceJiraIntegration, and routing NOT_AVAILABLE through the
  # suppression lambda would let a matching suppression rule set finding_state='suppressed',
  # blocking the autoclose that an identical PASSED finding would get.

  assert {
    condition     = strcontains(jsonencode(jsondecode(aws_sfn_state_machine.jira_orchestrator[0].definition).States.ChoiceSuppressor.Choices), "PASSED")
    error_message = "ChoiceSuppressor must bypass suppression for NOTIFIED+PASSED findings when autoclose is enabled"
  }

  assert {
    condition     = strcontains(jsonencode(jsondecode(aws_sfn_state_machine.jira_orchestrator[0].definition).States.ChoiceSuppressor.Choices), "NOT_AVAILABLE")
    error_message = "ChoiceSuppressor must bypass suppression for NOTIFIED+NOT_AVAILABLE findings (must mirror the close gate) when autoclose is enabled"
  }
}
