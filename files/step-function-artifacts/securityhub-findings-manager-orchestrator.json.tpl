{
    "Comment": "Step Function to orchestrate Security Hub findings manager Lambda functions",
    "StartAt": "ChoiceSuppressor",
    "States": {
      "ChoiceSuppressor": {
        "Type": "Choice",
        "Choices": [
          {
            "Comment": "Archived finding (resource deleted / no longer active): skip suppression, evaluate Jira autoclose.",
            "Variable": "$.detail.findings[0].RecordState",
            "StringEquals": "ARCHIVED",
            "Next": "ChoiceJiraIntegration"
          },
%{~ if jira_autoclose_enabled }
          {
            "Comment": "Close-eligible finding (NOTIFIED + Compliance PASSED or NOT_AVAILABLE, mirroring the close gate): skip suppression so a matching suppression rule cannot block the autoclose.",
            "And": [
              {
                "Variable": "$.detail.findings[0].Workflow.Status",
                "StringEquals": "NOTIFIED"
              },
              {
                "Variable": "$.detail.findings[0].Compliance.Status",
                "IsPresent": true
              },
              {
                "Or": [
                  {
                    "Variable": "$.detail.findings[0].Compliance.Status",
                    "StringEquals": "PASSED"
                  },
                  {
                    "Variable": "$.detail.findings[0].Compliance.Status",
                    "StringEquals": "NOT_AVAILABLE"
                  }
                ]
              }
            ],
            "Next": "ChoiceJiraIntegration"
          },
%{ endif ~}
          {
            "Comment": "Active finding (Workflow NEW or NOTIFIED): run the findings-manager suppression Lambda",
            "Or": [
              {
                "Variable": "$.detail.findings[0].Workflow.Status",
                "StringEquals": "NEW"
              },
              {
                "Variable": "$.detail.findings[0].Workflow.Status",
                "StringEquals": "NOTIFIED"
              }
            ],
            "Next": "invoke-securityhub-findings-manager-events"
          }
        ],
        "Default": "ChoiceJiraIntegration"
      },
      "invoke-securityhub-findings-manager-events": {
        "Type": "Task",
        "Resource": "arn:aws:states:::lambda:invoke",
        "Parameters": {
          "Payload.$": "$",
          "FunctionName": "${findings_manager_events_lambda}"
        },
        "Retry": [
          {
            "ErrorEquals": [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException"
            ],
            "IntervalSeconds": 2,
            "MaxAttempts": 6,
            "BackoffRate": 2
          }
        ],
        "Catch": [
          {
            "ErrorEquals": [
              "States.TaskFailed"
            ],
            "Comment": "Catch all task failures",
            "Next": "ChoiceJiraIntegration",
            "ResultPath": "$.error"
          }
        ],
        "Next": "ChoiceJiraIntegration",
        "ResultPath": "$.TaskResult"
      },
      "ChoiceJiraIntegration": {
        "Type": "Choice",
        "Choices": [
          {
            "Comment": "Eligible for Jira: finding was not suppressed, passes de-duplication, and matches create-ticket or close-ticket criteria - invoke the Jira Lambda",
            "And": [
              {
                "Comment": "Finding was not actively suppressed by the findings-manager Lambda (no Lambda result, or result was 'skipped')",
                "Or": [
                  {
                    "Variable": "$.TaskResult.Payload.finding_state",
                    "IsPresent": false
                  },
                  {
                    "And": [
                      {
                        "Variable": "$.TaskResult.Payload.finding_state",
                        "IsPresent": true
                      },
                      {
                        "Variable": "$.TaskResult.Payload.finding_state",
                        "StringEquals": "skipped"
                      }
                    ]
                  }
                ]
              },
%{~ if length(include_product_names) > 0 }
              {
                "Comment": "PRODUCT NAME FILTER: Only process findings with ProductName in the include list",
                "Or": [
%{~ for idx, product_name in include_product_names }
                  {
                    "Variable": "$.detail.findings[0].ProductName",
                    "StringEquals": "${product_name}"
                  }%{if idx < length(include_product_names) - 1},%{endif}
%{~ endfor }
                ]
              },
%{ endif ~}
              {
                "Comment": "Prevent duplicate Jira tickets: only create NEW tickets if note doesn't contain jiraIssue, OR allow ARCHIVED findings for closure",
                "Or": [
                  {
                    "Variable": "$.detail.findings[0].Note.Text",
                    "IsPresent": false
                  },
                  {
                    "And": [
                      {
                        "Variable": "$.detail.findings[0].Note.Text",
                        "IsPresent": true
                      },
                      {
                        "Not": {
                          "Variable": "$.detail.findings[0].Note.Text",
                          "StringMatches": "*jiraIssue*"
                        }
                      }
                    ]
                  },
                  {
                    "Not": {
                      "Variable": "$.detail.findings[0].Workflow.Status",
                      "StringEquals": "NEW"
                    }
                  },
                  {
                    "Comment": "Allow ARCHIVED findings through for autoclose even if note has jiraIssue and status is NEW",
                    "Variable": "$.detail.findings[0].RecordState",
                    "StringEquals": "ARCHIVED"
                  }
                ]
              },
              %{~ if jira_autoclose_enabled }
              {
                "Or": [
                  {
                    "Comment": "CREATE JIRA TICKET: Requires severity >= threshold",
                    "And": [
                      {
                        "Variable": "$.detail.findings[0].Severity.Normalized",
                        "NumericGreaterThanEquals": ${finding_severity_normalized}
                      },
                      {
                        "Variable": "$.detail.findings[0].Workflow.Status",
                        "StringEquals": "NEW"
                      },
                      {
                        "Variable": "$.detail.findings[0].RecordState",
                        "StringEquals": "ACTIVE"
                      },
                      {
                        "Or": [
                          {
                            "Variable": "$.detail.findings[0].Compliance.Status",
                            "IsPresent": false
                          },
                          {
                            "And": [
                              {
                                "Variable": "$.detail.findings[0].Compliance.Status",
                                "IsPresent": true
                              },
                              {
                                "Or": [
                                  {
                                    "Variable": "$.detail.findings[0].Compliance.Status",
                                    "StringEquals": "FAILED"
                                  },
                                  {
                                    "Variable": "$.detail.findings[0].Compliance.Status",
                                    "StringEquals": "WARNING"
                                  }
                                ]
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  {
                    "Comment": "CLOSE JIRA TICKET: Works at ANY severity (ticket already exists).",
                    "And": [
                      {
                        "Or": [
                          {
                            "Comment": "Finding explicitly resolved by a human",
                            "Variable": "$.detail.findings[0].Workflow.Status",
                            "StringEquals": "RESOLVED"
                          },%{~ if jira_autoclose_suppressed_enabled }
                          {
                            "Comment": "Finding suppressed (only routed here when autoclose_suppressed_findings is enabled)",
                            "Variable": "$.detail.findings[0].Workflow.Status",
                            "StringEquals": "SUPPRESSED"
                          },%{ endif ~}
                          {
                            "Comment": "Remediated finding: a ticket is open (NOTIFIED) and the control now passes (PASSED) or can no longer be evaluated (NOT_AVAILABLE). The IsPresent guard prevents a States.Runtime error on findings without a Compliance object; those fall through to the Archived branch below",
                            "And": [
                              {
                                "Variable": "$.detail.findings[0].Workflow.Status",
                                "StringEquals": "NOTIFIED"
                              },
                              {
                                "Variable": "$.detail.findings[0].Compliance.Status",
                                "IsPresent": true
                              },
                              {
                                "Or": [
                                  {
                                    "Variable": "$.detail.findings[0].Compliance.Status",
                                    "StringEquals": "PASSED"
                                  },
                                  {
                                    "Variable": "$.detail.findings[0].Compliance.Status",
                                    "StringEquals": "NOT_AVAILABLE"
                                  }
                                ]
                              }
                            ]
                          },
                          {
                            "Comment": "Archived finding: the resource was deleted or the finding is otherwise no longer active. Matches any Workflow.Status, including NEW after a re-import reset.",
                            "Variable": "$.detail.findings[0].RecordState",
                            "StringEquals": "ARCHIVED"
                          }
                        ]
                      },
                      {
                        "Variable": "$.detail.findings[0].Note.Text",
                        "IsPresent": true
                      },
                      {
                        "Variable": "$.detail.findings[0].Note.Text",
                        "StringMatches": "*jiraIssue*"
                      }
                    ]
                  }
                ]
              }
              %{ else }
              {
                "And": [
                  {
                    "Variable": "$.detail.findings[0].Severity.Normalized",
                    "NumericGreaterThanEquals": ${finding_severity_normalized}
                  },
                  {
                    "Variable": "$.detail.findings[0].Workflow.Status",
                    "StringEquals": "NEW"
                  }
                ]
              }
              %{ endif ~}
            ],
            "Next": "invoke-securityhub-jira"
          }
        ],
        "Default": "Success"
      },
      "Success": {
        "Type": "Succeed"
      },
      "invoke-securityhub-jira": {
        "Type": "Task",
        "Resource": "arn:aws:states:::lambda:invoke",
        "OutputPath": "$.Payload",
        "Parameters": {
          "Payload.$": "$",
          "FunctionName": "${jira_lambda}"
        },
        "Retry": [
          {
            "ErrorEquals": [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException"
            ],
            "IntervalSeconds": 2,
            "MaxAttempts": 6,
            "BackoffRate": 2
          }
        ],
        "End": true
      }
    }
  }
