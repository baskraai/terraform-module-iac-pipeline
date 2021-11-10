resource "aws_s3_bucket" "terraform-state" {
  bucket = lower("${var.name}-state")
  acl    = "private"
  tags = {
    terraform = "true"
  }
}
