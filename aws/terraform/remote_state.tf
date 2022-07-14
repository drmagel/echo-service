resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name = "terraform-state-lock-echo-service"
  hash_key = "LockID"
  read_capacity = 5
  write_capacity = 5

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "DynamoDB Terraform State Lock Table"
  }
}

terraform {
  backend "s3" {
    bucket = "mabaya-terraform-states"
    dynamodb_table = "terraform-state-lock-echo-service"
    key    = "terraform/echo-service/terraform.tfstate"
    region = "us-east-1"
  }
}