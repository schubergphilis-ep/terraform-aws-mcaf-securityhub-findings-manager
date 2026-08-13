output "findings_manager_events_lambda_sg_id" {
  value       = module.findings_manager_events_lambda.security_group_id
  description = "This will output the security group id attached to the lambda_findings_manager_events Lambda. This can be used to tune ingress and egress rules."
}

output "findings_manager_trigger_lambda_sg_id" {
  value       = module.findings_manager_trigger_lambda.security_group_id
  description = "This will output the security group id attached to the lambda_findings_manager_trigger Lambda. This can be used to tune ingress and egress rules."
}

output "findings_manager_worker_lambda_sg_id" {
  value       = module.findings_manager_worker_lambda.security_group_id
  description = "This will output the security group id attached to the lambda_findings_manager_worker Lambda. This can be used to tune ingress and egress rules."
}

output "jira_lambda_sg_id" {
  value       = length(module.jira_lambda) > 0 ? module.jira_lambda[*].security_group_id : null
  description = "This will output the security group id attached to the jira_lambda Lambda. This can be used to tune ingress and egress rules."
}

output "kms_key_arn" {
  value       = length(module.kms_key) > 0 ? module.kms_key[0].arn : null
  description = "The ARN of the KMS key created by this module, which can be used to encrypt the secrets stored in Secrets Manager and SSM Parameter Store used by this module. This will be null when an existing key is provided via 'kms_key_arn'."
}
