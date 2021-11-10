resource "aws_codecommit_repository" "iac-repo" {
  repository_name = "${var.name}"
  description     = "Infra-as-Code repo build with the Terraform IaC-pipeline module"
  tags            = {
    terraform = true
  }
}
