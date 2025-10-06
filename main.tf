terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.14.1"
    }
  }
}

provider "aws" {
  # Configuration options
    region = "us-east-1"
}

#create bucket S3
resource "aws_s3_bucket" "mybucket" {
  bucket = var.bucket_name
  tags = {
    Name = "mybucket"
    Enviroment = "Dev"
    ManagedBy = "Terraform"
  }
}

#bucket ownership controls
  resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.mybucket.id

  rule {
    object_ownership = "BucketOwnerPreferred" #Ensures that the bucket owner also owns the objects.
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.mybucket.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}
  
resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
  ]

  bucket = aws_s3_bucket.mybucket.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "restrict_ip" {
  bucket = aws_s3_bucket.mybucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowAccessFromSpecificIP"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.mybucket.arn}/*"
        Condition = {
          IpAddress = {
            "aws:SourceIp" = "200.124.166.46/32"
          }
        }
      }
    ]
  })
}

#create a objeto inside the bucket - a html page
resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.mybucket.id
  key = "index.html"
  source = "index.html"
  acl = "private"
  content_type = "text/html"
}

#create a objeto inside the bucket - a error page
resource "aws_s3_object" "error" {
  bucket = aws_s3_bucket.mybucket.id
  key = "error.html"
  source = "error.html"
  acl = "private"
  content_type = "text/html"
}

#configure the static site
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.mybucket.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }

  depends_on = [ aws_s3_bucket_acl.example ]
}