## Usage Example
```hcl
module "security_guardrails" {
  source = "../../modules/security-guardrails"

  environment        = "prod"
  allowed_services   = ["ec2:Describe*", "s3:GetObject", "sts:AssumeRole", "lambda:InvokeFunction"]
  web_acl_name       = "prod-waf-guardrails"
  target_ou_ids      = ["ou-1234-abcd", "ou-5678-efgh"]
  target_waf_associations = {
    alb-arn = "arn:aws:elasticloadbalancing:us-east-1:123456789:loadbalancer/app/prod-alb/1234567890"
    nlb-arn = "arn:aws:elasticloadbalancing:us-east-1:123456789:loadbalancer/net/prod-nlb/1234567890"
  }
}```