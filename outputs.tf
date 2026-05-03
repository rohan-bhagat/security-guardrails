output "scp_ids" {
  description = "IDs of the enforced Service Control Policies"
  value = [
    aws_organizations_policy.deny_all_except_whitelist.id,
    aws_organizations_policy.deny_sso_modification.id,
    aws_organizations_policy.deny_public_exposure.id,
    aws_organizations_policy.deny_unprotected_deletion.id
  ]
}

output "web_acl_arn" {
  description = "ARN of the managed Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}

output "waf_association_count" {
  description = "Number of resources associated with the WAF"
  value       = length(aws_wafv2_web_acl_association.main)
}