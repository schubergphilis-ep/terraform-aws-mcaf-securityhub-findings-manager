# Upgrading Notes

This document captures required refactoring on your part when upgrading to a module version that contains breaking changes.

## Upgrading to v8.0.0

### Key Changes v8.0.0

The events, trigger and worker Lambdas now run on [awsfindingsmanagerlib](https://github.com/schubergphilis-ep/awsfindingsmanagerlib) 2.x, a complete rewrite of the 1.x library with a different rules schema. The `findings-manager-jira` Lambda is unaffected: it has no dependency on either library.

Two consequences of this switch:

- **`rules.yaml` must be rewritten** in awsfindingsmanagerlib 2.x's schema (see "Behaviour" below).
- **`lambda_runtime` no longer accepts `python3.11`.** awsfindingsmanagerlib 2.x requires Python >= 3.12. This
  variable is shared by all four Lambdas in this module, including the Jira Lambda, so it is now
  restricted to `python3.12` module-wide, even though the Jira Lambda itself has no Python version
  constraint.

### Behaviour (v8.0.0)

awsfindingsmanagerlib 2.x's rule filters map directly onto the Security Hub `get_findings`/`batch_update_findings`
boto3 API, rather than a custom, narrower matching schema. The table below maps every
`match_on` key supported by the 1.x library onto its 2.x equivalent; see
the library's [documentation](https://schubergphilis-ep.github.io/awsfindingsmanagerlib/) for the full rule syntax and
its own [UPGRADING.md](https://github.com/schubergphilis-ep/awsfindingsmanagerlib/blob/main/UPGRADING.md) migration guide.

| awsfindingsmanagerlib 1.x | awsfindingsmanagerlib 2.x |
|---|---|
| `note` | `UpdatesToFilteredFindings.Note.Text` |
| `action: SUPPRESSED` | `UpdatesToFilteredFindings.Workflow.Status: SUPPRESSED` |
| `match_on.security_control_id` | `Filters.ComplianceSecurityControlId` |
| `match_on.tags` (a list of `{key, value}`, matching any of them) | `Filters.ResourceTags` (a list of `{Key, Value, Comparison: EQUALS}`; multiple entries are also matched as "any of") |
| `match_on.resource_id_regexps` | `ExtraFeatures.RegexStringFilters.ResourceId` |
| `match_on.regions` | `Filters.Region` |
| `match_on.rule_or_control_id` | `Filters.ProductFields` with `Key: ControlId` and `Key: RuleId` (1.x matched either, depending on the standard) |
| `match_on.title` | `Filters.Title` |
| `match_on.product_name` | `Filters.ProductName` |

awsfindingsmanagerlib 1.x's default filter (`WorkflowStatus` in `NEW`/`NOTIFIED`, applied to every
rule automatically) and its Jira-compatible JSON note merging (so that suppressing a finding
doesn't overwrite the `jiraIssue`/`jiraInstance` metadata a ticket integration stored in the
finding's note) both have to be set explicitly once, via `ManagerConfig.DefaultRuleInput`, if you
were relying on them:

```yaml
ManagerConfig:
  DefaultRuleInput:
    Filters:
      WorkflowStatus:
      - Value: NEW
        Comparison: EQUALS
      - Value: NOTIFIED
        Comparison: EQUALS
    UpdatesToFilteredFindings:
      Workflow:
        Status: SUPPRESSED
      Note:
        UpdatedBy: FindingsManager
    ExtraFeatures:
      NoteTextConfig:
        Mode: jsonUpdate
        Key: Note
```

The script below converts a 1.x `rules.yaml` to a complete 2.x document, including the `ManagerConfig` block above
(that's also where `Note.UpdatedBy` comes from - Security Hub's API rejects a `Note` without one).
It declares its own dependencies ([PEP 723](https://peps.python.org/pep-0723/)), so with
[uv](https://docs.astral.sh/uv/) you can save it as `convert.py` and run it directly:

```shell
uv run convert.py rules.yaml > rules-v2.yaml
```

The input path is optional (default: `rules.yaml`). The converted document goes to stdout, and it is validated with
`awsfindingsmanagerlib` itself before it is printed, so a failure means the result is not a valid 2.x document.
No AWS credentials are needed. Review the `ManagerConfig` block it prints and adjust it to the defaults you relied on.

```python
# /// script
# requires-python = ">=3.12,<3.13"  # awsfindingsmanagerlib 2.0.0 does not yet run on 3.13
# dependencies = ["awsfindingsmanagerlib>=2,<3", "pyyaml"]
# ///
import sys
from pathlib import Path

import boto3
import yaml

from awsfindingsmanagerlib import Manager

SUPPORTED_MATCH_ON_KEYS = {
    "security_control_id",
    "rule_or_control_id",
    "title",
    "product_name",
    "regions",
    "tags",
    "resource_id_regexps",
}


def equals(values):
    return [{"Value": value, "Comparison": "EQUALS"} for value in values]


def convert(rule):
    match_on = rule.get("match_on", {})
    unknown_keys = set(match_on) - SUPPORTED_MATCH_ON_KEYS
    if unknown_keys:
        # Fail rather than silently drop a condition and suppress too much.
        msg = f"Unsupported match_on key(s) {sorted(unknown_keys)} in rule: {rule}"
        raise ValueError(msg)

    filters = {}

    if "security_control_id" in match_on:
        filters["ComplianceSecurityControlId"] = equals(
            [match_on["security_control_id"]]
        )
    if "rule_or_control_id" in match_on:
        # The old library matched either field, depending on the standard.
        filters["ProductFields"] = [
            {
                "Key": key,
                "Value": match_on["rule_or_control_id"],
                "Comparison": "EQUALS",
            }
            for key in ("ControlId", "RuleId")
        ]
    if "title" in match_on:
        filters["Title"] = equals([match_on["title"]])
    if "product_name" in match_on:
        filters["ProductName"] = equals([match_on["product_name"]])
    if "regions" in match_on:
        filters["Region"] = equals(match_on["regions"])
    if "tags" in match_on:
        filters["ResourceTags"] = [
            {"Key": tag["key"], "Value": tag["value"], "Comparison": "EQUALS"}
            for tag in match_on["tags"]
        ]

    updates = {"Note": {"Text": rule["note"]}}
    # SUPPRESSED is already the default in ManagerConfig.DefaultRuleInput.
    if rule["action"] != "SUPPRESSED":
        updates["Workflow"] = {"Status": rule["action"]}

    new_rule = {"Filters": filters, "UpdatesToFilteredFindings": updates}

    if "resource_id_regexps" in match_on:
        new_rule["ExtraFeatures"] = {
            "RegexStringFilters": {"ResourceId": match_on["resource_id_regexps"]}
        }

    return new_rule


input_path = Path(sys.argv[1] if len(sys.argv) > 1 else "rules.yaml")
with input_path.open() as file:
    old_document = yaml.safe_load(file)

if "Rules" not in old_document:
    sys.exit(f"{input_path} has no top-level 'Rules' key. Is it a 1.x rules file?")

document = {
    "ManagerConfig": {
        "DefaultRuleInput": {
            "Filters": {
                "WorkflowStatus": equals(["NEW", "NOTIFIED"]),
            },
            "UpdatesToFilteredFindings": {
                "Workflow": {"Status": "SUPPRESSED"},
                "Note": {"UpdatedBy": "FindingsManager"},
            },
            "ExtraFeatures": {
                "NoteTextConfig": {"Mode": "jsonUpdate", "Key": "Note"},
            },
        },
    },
    "Rules": [convert(rule) for rule in old_document["Rules"]],
}

# Validate against botocore's service model. This makes no AWS calls and needs no
# credentials; the region is only required to create the client.
client = boto3.client("securityhub", region_name="us-east-1")
Manager.from_rules_document(document, client)

print(yaml.safe_dump(document, sort_keys=False, indent=2))
print(
    f"Converted {len(document['Rules'])} rules; the result is a valid 2.x rules document.",
    file=sys.stderr,
)
```

See the updated `examples/rules.yaml` in this repository for a complete, translated file (all four
of its rules existed in the previous schema too, so it doubles as a worked example of the mapping
above, and of running this exact script against it).

## Upgrading to v7.0.0

### Key Changes v7.0.0

This module now requires a minimum AWS provider version of 6.0 to support the region parameter. If you are using multiple AWS provider blocks, please read [migrating from multiple provider configurations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/enhanced-region-support#migrating-from-multiple-provider-configurations).

## Upgrading to v6.0.0

The Jira integration has been restructured to support multiple Jira instances. This allows routing Security Hub findings to different Jira projects based on AWS account IDs.

### Behaviour (v6.0.0)

**New functionality:**

- **Multiple Jira instances**: Route findings to different Jira projects based on AWS account ID
- **Default instance fallback**: Configure a fallback instance for accounts not explicitly mapped to any instance
- **Per-instance credentials**: Each instance can use different Jira credentials (different Jira servers or projects)
- **Mutually exclusive routing**: Each AWS account is routed to exactly one Jira instance (findings from an account always go to the same instance)

### Variables (v6.0.0)

The `jira_integration` variable structure has been completely redesigned:

**Old structure:**

```hcl
jira_integration = {
  enabled                               = true
  project_key                           = "PROJ"
  include_account_ids                   = ["123456789012"]
  credentials_secretsmanager_arn        = "arn:aws:secretsmanager:..."
  autoclose_enabled                     = true
  autoclose_comment                     = "Closing issue"
  autoclose_transition_name             = "Done"
  finding_severity_normalized_threshold = 70
  include_product_names                 = ["GuardDuty"]
  issue_type                            = "Security Advisory"
  issue_custom_fields                   = {}
  include_intermediate_transition       = "In Progress"
}
```

**New structure:**

```hcl
jira_integration = {
  autoclose_comment                     = "Closing issue"
  autoclose_enabled                     = true
  autoclose_transition_name             = "Done"
  exclude_account_ids                   = []
  finding_severity_normalized_threshold = 70
  include_product_names                 = ["GuardDuty"]

  # Per-instance configurations
  instances = {
    "default" = {
      credentials_secretsmanager_arn  = "arn:aws:secretsmanager:..."
      default_instance                = true # Catches all accounts
      include_intermediate_transition = "In Progress"
      issue_custom_fields             = {}
      issue_type                      = "Security Advisory"
      project_key                     = "PROJ"
      # Note: include_account_ids is optional when default_instance = true
    }
  }
}
```

## Upgrading to v5.0.0

The following variables have been renamed:

- `jira_integration.credentials_secret_arn` -> `jira_integration.credentials_secretsmanager_arn`

## Upgrading to v4.0.0

We are introducing a new worker Lambda function and an SQS queue, enabling the Lambda to run within the 15-minute timeout, which is especially relevant for larger environments.

The following variable defaults have been modified:

- `findings_manager_events_lambda.log_level` -> default: `ERROR` (previous default: `INFO`). The logging configuration has been updated, and `ERROR` is now more logical as the default level.
- `findings_manager_trigger_lambda.log_level` -> default: `ERROR` (previous default: `INFO`). The logging configuration has been updated, and `ERROR` is now more logical as the default level.
- `findings_manager_trigger_lambda.memory_size` -> default: `256` (previous default: `1024`). With the new setup, the trigger Lambda requires less memory.
- `findings_manager_trigger_lambda.timeout` -> default: `300` (previous default: `900`). With the new setup, the trigger Lambda completes tasks in less time.

The following variables have been introduced:

- `findings_manager_worker_lambda`

The following output has been introduced:

- `findings_manager_worker_lambda_sg_id`

Note:

- Ensure your KMS key is available for SQS access.

## Upgrading to v3.0.0

### Variables (v3.0.0)

The following variables have been removed:

- `dynamodb_table`
- `dynamodb_deletion_protection`

The following variables have been introduced:

- `rules_filepath`
- `rules_s3_object_name`

The following variables have been renamed:

- `lambda_events_suppressor` -> `findings_manager_events_lambda`
- `lambda_streams_suppressor` -> `findings_manager_trigger_lambda`
- `lambda_suppressor_iam_role_name` -> `findings_manager_lambda_iam_role_name`
- `eventbridge_suppressor_iam_role_name` -> `jira_eventbridge_iam_role_name`
- `step_function_suppressor_iam_role_name` -> `jira_step_function_iam_role_name`

A Lambda function now triggers on S3 Object Creation Trigger Events.
By default it is triggered by putting a new (version of) an object called `rules.yaml` in the bucket created by this module.
This filename can be customized with the `rules_s3_object_name` variable.

You can add the `rules.yaml` file to the bucket in any way you like after deploying this module, for instance with an `aws_s3_object` resource.
This way you can separate management of your infrastructure and security.
If this separation is not necessary in your case you also let this module directly upload the file for you by setting the `rules_filepath` variable to a filepath to your `rules.yaml` file.
In either case, be mindful that there can be a delay between creating S3 triggers and those being fully functional.
Re-create the rules object later to have rules run on your findings history in that case.

### Outputs (v3.0.0)

The following output has been removed:

- `dynamodb_arn`

The following output has been renamed:

- `lambda_jira_security_hub_sg_id` -> `jira_lambda_sg_id`
- `lambda_securityhub_events_suppressor_sg_id` -> `findings_manager_events_lambda_sg_id`
- `lambda_securityhub_streams_suppressor_sg_id` -> `findings_manager_trigger_lambda_sg_id`

### Behaviour (v3.0.0)

New functionality:

- Managing consolidated control findings is now supported
- Managing based on tags is now supported

See the README, section `## How to format the rules.yaml file?` for more information on the keys you need to use to control this.

The `rules.yaml` file needs to be written in a different syntax. The script below can be used to easily convert your current `suppressions.yml` file to the new format.

```python
import yaml

suppressions = yaml.safe_load(open('suppressions.yml'))['Suppressions']

rules = {
    'Rules': [
        {
            'note': content['notes'],
            'action': content['action'],
            'match_on': {
                'rule_or_control_id': rule_or_control_id,
                'resource_id_regexps': content['rules']
            }
        }
        for rule_or_control_id, contents in suppressions.items()
        for content in contents
    ]
}

print(yaml.dump(rules, indent=2))
```

If you do not want to rename your file from `suppressions.yml` to `rules.yaml` you can override the name using the `rules_s3_object_name` variable.

## Upgrading to v2.0.0

### Variables (v2.0.0)

The following variable has been replaced:

- `create_allow_all_egress_rule` -> `jira_integration.security_group_egress_rules`, `lambda_streams_suppressor.security_group_egress_rules`, `lambda_events_suppressor.security_group_egress_rules`

Instead of only being able to allow all egress or block all egress and having to rely on resources outside this module to create specific egress rules this is now supported natively by the module.

The following variable defaults have been modified:

- `servicenow_integration.cloudwatch_retention_days` -> default: `365` (previous hardcoded: `14`). In order to comply with AWS Security Hub control CloudWatch.16.

### Behaviour (v2.0.0)

The need to provide a `providers = { aws = aws }` argument has been removed, but is still allowed. E.g. when deploying this module in the audit account typically `providers = { aws = aws.audit }` is passed.

## Upgrading to v1.0.0

### Behaviour (v1.0.0)

- Timeouts of the suppressor lambdas have been increased to 120 seconds. The current timeout of 60 seconds is not always enough to process 100 records of findings.
- The `create_servicenow_access_keys` variable, now called `servicenow_integration.create_access_keys` was not used in the code and therefore the default behaviour was that access keys would be created. This issue has been resolved.
- The `create_allow_all_egress_rule` variable has been set to `false`.
- The `tags` variable is now optional.

### Variables (v1.0.0)

The following variables have been replaced by a new variable `jira_integration`:

- `jira_exclude_account_filter` -> `jira_integration.exclude_account_ids`
- `jira_finding_severity_normalized` -> `jira_integration.finding_severity_normalized_threshold`
- `jira_integration` -> `jira_integration.enabled`
- `jira_issue_type` -> `jira_integration.issue_type`
- `jira_project_key` -> `jira_integration.project_key`
- `jira_secret_arn` -> `jira_integration.credentials_secret_arn`
- `lambda_jira_name` -> `jira_integration.lambda_settings.name`
- `lambda_jira_iam_role_name` -> `jira_integration.lambda_settings.iam_role_name`
- Additionally you are now able to specify the `log_level`, `memory_size,` and `timeout` of the lambda.

The following variables have been replaced by a new variable `servicenow_integration`:

- `servicenow_integration` -> `servicenow_integration.enabled`
- `create_servicenow_access_keys` -> `servicenow_integration.create_access_keys`

The following variables have been replaced by a new variable `lambda_events_suppressor`:

- `lambda_events_suppressor_name` -> `lambda_events_suppressor.name`
- Additionally you are now able to specify the `log_level`, `memory_size,` and `timeout` of the lambda.

The following variables have been replaced by a new variable `lambda_streams_suppressor`:

- `lambda_streams_suppressor_name` -> `lambda_streams_suppressor.name`
- Additionally you are now able to specify the `log_level`, `memory_size,` and `timeout` of the lambda.
