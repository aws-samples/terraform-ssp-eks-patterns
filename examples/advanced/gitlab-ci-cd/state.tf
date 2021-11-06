terraform {
  backend "s3" {
    bucket = "<s3-bucket-name>"
    region = "eu-west-1"
    key    = "preprod/dev/terraform-main.tfstate"
  }
}