provider "aws" {
  region = "us-east-1"
}

# Create Key Pair (Fix for key error)
resource "aws_key_pair" "terraform_key" {
  key_name   = "terraformkey"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Create Security Group
resource "aws_security_group" "my_sg" {
  name = "mytf_sg"

  ingress {
    description = "allow ssh"
    to_port     = 22
    from_port   = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http"
    to_port     = 80
    from_port   = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "https"
    to_port     = 443
    from_port   = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow all"
    to_port     = 0
    from_port   = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create EC2 Instances
resource "aws_instance" "webserver" {
  ami                    = var.my_ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.terraform_key.key_name
  for_each               = toset(["jump-server", "app-server", "db-server"])
  vpc_security_group_ids = [aws_security_group.my_sg.id]

  tags = {
    Name = each.key
  }
}

# Random ID for Unique Bucket Name (Fix for bucket error)
resource "random_id" "bucket" {
  byte_length = 4
}

# Create S3 Bucket
resource "aws_s3_bucket" "mybucket" {
  bucket = "sonali-bucket-${random_id.bucket.hex}"
}

# Enable S3 versioning
resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.mybucket.id

  versioning_configuration {
    status = "Enabled"
  }
}