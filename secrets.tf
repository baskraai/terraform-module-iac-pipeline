resource "aws_secretsmanager_secret" "pipeline" {
  name = "${var.name}-secrets"
}
