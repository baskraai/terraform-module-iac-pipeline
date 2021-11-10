# Get the defaults from the ec2-env

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_default_vpc.default.id
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "${var.aws_region}a"
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "${var.aws_region}b"
}

resource "aws_default_subnet" "default_az3" {
  availability_zone = "${var.aws_region}c"
}

resource "aws_iam_role" "codebuildrole" {
  name = "${var.name}_CodeBuildRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuildpolicy" {
  role = aws_iam_role.codebuildrole.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterfacePermission"
      ],
      "Resource": [
        "arn:aws:ec2:us-east-1:123456789012:network-interface/*"
      ],
      "Condition": {
        "StringEquals": {
          "ec2:Subnet": [
            "${aws_default_subnet.default_az1.arn}",
            "${aws_default_subnet.default_az2.arn}",
            "${aws_default_subnet.default_az3.arn}"
          ],
          "ec2:AuthorizedService": "codebuild.amazonaws.com"
        }
      }
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject"
        ],
        "Resource": [
          "arn:aws:s3:::${element(split(":",resource.aws_s3_bucket.terraform-state.arn),length(split(":",resource.aws_s3_bucket.terraform-state.arn))-1)}/${var.branch}"
        ]
    }
  ]
}
POLICY
}

resource "aws_codebuild_project" "pipeline-build" {
  name          = "${var.name}_build"
  description   = "Infra-as-Code pipeline"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuildrole.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:1.0.10"
    type                        = "LINUX_CONTAINER"

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "${var.name}_build"
      stream_name = "pipeline"
    }
  }

  source {
    type            = "CODECOMMIT"
    location        = aws_codecommit_repository.iac-repo.clone_url_http
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }
    buildspec = templatefile("${path.module}/buildspec.yml.template",{ secret = element(split(":",resource.aws_secretsmanager_secret.pipeline.arn),length(split(":",resource.aws_secretsmanager_secret.pipeline.arn))-1) } )
  }

  source_version = var.branch

  vpc_config {
    vpc_id = aws_default_vpc.default.id

    subnets = [
      aws_default_subnet.default_az1.id,
      aws_default_subnet.default_az2.id,
      aws_default_subnet.default_az3.id
    ]

    security_group_ids = [
      aws_default_security_group.default.id
    ]
  }


  tags = {
    terraform = "true"
  }
}
