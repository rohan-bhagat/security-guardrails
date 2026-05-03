# ─────────────────────────────────────────────────────────────
# 1. Deny All Except Whitelisted Services
# ─────────────────────────────────────────────────────────────
resource "aws_organizations_policy" "deny_all_except_whitelist" {
  name        = "DenyAllExceptWhitelist-${var.environment}"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyAllNotWhitelisted"
        Effect    = "Deny"
        Action    = "*"
        Resource  = "*"
        NotAction = var.allowed_services
      }
    ]
  })
}

# ─────────────────────────────────────────────────────────────
# 2. Block SSO & Directory Modification
# ─────────────────────────────────────────────────────────────
resource "aws_organizations_policy" "deny_sso_modification" {
  name        = "DenySSOModification-${var.environment}"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenySSOAndDirAccess"
        Effect   = "Deny"
        Action   = var.sso_denied_actions
        Resource = "*"
      }
    ]
  })
}

# ─────────────────────────────────────────────────────────────
# 3. Block Public Exposure (API Layer)
# ─────────────────────────────────────────────────────────────
resource "aws_organizations_policy" "deny_public_exposure" {
  name        = "DenyPublicExposure-${var.environment}"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyPublicResourceCreation"
        Effect   = "Deny"
        Action   = var.public_exposure_denied_actions
        Resource = "*"
        Condition = {
          StringEquals = { "aws:RequestedRegion": "us-east-1" }
        }
      }
    ]
  })
}

# ─────────────────────────────────────────────────────────────
# 4. Block Deletion of Unprotected Resources
# ─────────────────────────────────────────────────────────────
resource "aws_organizations_policy" "deny_unprotected_deletion" {
  name        = "DenyUnprotectedDeletion-${var.environment}"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyDeleteUnprotected"
        Effect   = "Deny"
        Action   = var.lifecycle_denied_actions
        Resource = "*"
        Condition = {
          StringNotEquals = { "aws:ResourceTag/${var.protected_tag_key}": "true" }
        }
      }
    ]
  })
}

# ─────────────────────────────────────────────────────────────
# Attach SCPs to OU
# ─────────────────────────────────────────────────────────────
resource "aws_organizations_policy_attachment" "whitelist" {
  count      = length(var.target_ou_ids)
  policy_id  = aws_organizations_policy.deny_all_except_whitelist.id
  target_id  = var.target_ou_ids[count.index]
}
resource "aws_organizations_policy_attachment" "sso" {
  count      = length(var.target_ou_ids)
  policy_id  = aws_organizations_policy.deny_sso_modification.id
  target_id  = var.target_ou_ids[count.index]
}
resource "aws_organizations_policy_attachment" "public" {
  count      = length(var.target_ou_ids)
  policy_id  = aws_organizations_policy.deny_public_exposure.id
  target_id  = var.target_ou_ids[count.index]
}
resource "aws_organizations_policy_attachment" "lifecycle" {
  count      = length(var.target_ou_ids)
  policy_id  = aws_organizations_policy.deny_unprotected_deletion.id
  target_id  = var.target_ou_ids[count.index]
}

# ─────────────────────────────────────────────────────────────
# AWS Firewall Managed Web ACL (Regional)
# ─────────────────────────────────────────────────────────────
resource "aws_wafv2_web_acl" "main" {
  name  = var.web_acl_name
  scope = "REGIONAL"
  default_action {
    allow {}
  }

  # AWS Managed Rules: AWSManagedRulesCommonRuleSet, AWSManagedRulesKnownBadInputsRuleSet
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "SecurityGuardrailsWACL"
    sampled_requests_enabled   = true
  }
}

# Associate WAF with ALB/NLB targets
resource "aws_wafv2_web_acl_association" "main" {
  count            = length(var.target_waf_associations)
  web_acl_arn      = aws_wafv2_web_acl.main.arn
  resource_arn     = values(var.target_waf_associations)[count.index]
}