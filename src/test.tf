# Provider configuration
provider "aws" {
  region = "us-east-1" # Specify the AWS region
}

# Create S3 bucket
resource "aws_s3_bucket" "app_bucket" {
  bucket = "dotnet-sample-codepipeline-${random_id.bucket_suffix.hex}"
}

# Generate random suffix for bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# Upload the application file to S3
resource "aws_s3_object" "app_version" {
  bucket = aws_s3_bucket.app_bucket.id
  key    = "sample-eval-codepipeline.zip"
  source = "sample-eval.zip" # Ensure this file exists in your local directory
}

# Create an Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "dotnet_app" {
  name        = "DotNetApp"
  description = "Elastic Beanstalk Application for .NET 4.8"
}

# Create an Elastic Beanstalk Application Version
resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = "v1-${formatdate("YYYYMMDDHHmmss", timestamp())}"
  application = aws_elastic_beanstalk_application.dotnet_app.name
  bucket      = aws_s3_bucket.app_bucket.id
  key         = aws_s3_object.app_version.key
}

# Create IAM role for Elastic Beanstalk
resource "aws_iam_role" "eb_role" {
  name = "aws-elasticbeanstalk-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policies to the IAM role
resource "aws_iam_role_policy_attachment" "eb_web_tier" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
  role       = aws_iam_role.eb_role.name
}

resource "aws_iam_role_policy_attachment" "eb_worker_tier" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
  role       = aws_iam_role.eb_role.name
}

resource "aws_iam_role_policy_attachment" "eb_multicontainer_docker" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
  role       = aws_iam_role.eb_role.name
}

# Create IAM instance profile
resource "aws_iam_instance_profile" "eb_profile" {
  name = "eb-instance-profile"
  role = aws_iam_role.eb_role.name
}

# Create an Elastic Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "dotnet_environment" {
  name                = "DotNetEnv"
  application         = aws_elastic_beanstalk_application.dotnet_app.name
  solution_stack_name = "64bit Windows Server 2019 v2.15.5 running IIS 10.0"
  version_label       = aws_elastic_beanstalk_application_version.app_version.name

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.medium"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ENVIRONMENT"
    value     = "production"
  }
}

# Output the S3 bucket name
output "s3_bucket_name" {
  value       = aws_s3_bucket.app_bucket.id
  description = "The name of the S3 bucket created for the Elastic Beanstalk application"
}

# Output the Elastic Beanstalk environment URL
output "eb_environment_url" {
  value       = aws_elastic_beanstalk_environment.dotnet_environment.endpoint_url
  description = "The URL of the Elastic Beanstalk environment"
}
