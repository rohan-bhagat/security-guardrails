variable "environment" {
  description = "Environment name (e.g., prod, staging)"
  type        = string
}

variable "allowed_services" {
  description = "Whitelist of AWS API actions/services allowed across accounts"
  type        = list(string)
  default     = []
}

variable "web_acl_name" {
  description = "Name of the AWS WAF Web ACL"
  type        = string
}

variable "target_ou_ids" {
  description = "Organizational Unit IDs to attach SCPs"
  type        = list(string)
}

variable "target_waf_associations" {
  description = "Map of ARNs to associate the Web ACL with (e.g., ALB/NLB ARNs)"
  type        = map(string)
  default     = {}
}

variable "protected_tag_key" {
  description = "Tag key that marks resources as protected from deletion"
  type        = string
  default     = "protected"
}

variable "sso_denied_actions" {
  description = "Explicit IAM/Organizations actions that modify SSO or directory configs"
  type        = list(string)
  default     = [
    "sso:*",
    "organizations:LeaveOrganization",
    "organizations:DisablePolicyType",
    "iam:CreateAccessKey",
    "iam:DeleteAccessKey",
    "iam:CreateVirtualMFADevice",
    "iam:DeleteVirtualMFADevice"
  ]
}

variable "public_exposure_denied_actions" {
  description = "Actions that typically create publicly accessible resources"
  type        = list(string)
  default     = [
    "s3:PutBucketPolicy", "s3:PutBucketAcl",
    "ec2:RunInstances", "rds:CreateDBInstance",
    "elasticloadbalancing:CreateLoadBalancer",
    "cloudfront:CreateDistribution", "route53:CreateHostedZone"
  ]
}

variable "lifecycle_denied_actions" {
  description = "Lifecycle actions to restrict on unprotected resources"
  type        = list(string)
  default     = ["Delete*", "Terminate*", "Remove*", "Detach*", "Stop*"]
}