# Terraform Module IaC Pipeline
An terraform module that deploys a Terraform pipeline in AWS

# Requirements

- Terraform >= v1.0.9
- hashicorp/aws >= v3.63.0

# Deploy

```hcl
module "iac-pipeline" {
  source = "github.com/baskraai/terraform-module-iac-pipeline?ref=v0.0.2"

  name = "IaC-Pipeline"
  branch = "master"

}

output "IaC-pipeline" {
  value = module.iac-pipeline.environment
}
```

