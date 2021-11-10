output "environment" {
  description = "The properties of the IaC environment"
  value = {
    vpc = aws_default_vpc.default.id
    security_group = aws_default_security_group.default.id
    subnets = [
      aws_default_subnet.default_az1.id,
      aws_default_subnet.default_az2.id,
      aws_default_subnet.default_az3.id
    ]
    state_bucket = element(split(":",resource.aws_s3_bucket.terraform-state.arn),length(split(":",resource.aws_s3_bucket.terraform-state.arn))-1)
    pipelines = {
      terraform = element(split(":",resource.aws_codebuild_project.pipeline-build.arn),length(split(":",resource.aws_codebuild_project.pipeline-build.arn))-1)
    }
    git = {
      name = element(split(":",resource.aws_codecommit_repository.iac-repo.arn),length(split(":",resource.aws_codecommit_repository.iac-repo.arn))-1)
      clone_http = aws_codecommit_repository.iac-repo.clone_url_http
      clone_ssh = aws_codecommit_repository.iac-repo.clone_url_ssh
    }
  }
}
