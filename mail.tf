provider "aws" {
  region = "us-east-1"
}

# Archive your .NET 4.8 application
data "archive_file" "app_zip" {
  type        = "zip"
  source_dir  = "src/" 
  output_path = "${path.module}/dotnet-app.zip" 
}

# Create an S3 bucket for storing the application bundle
resource "aws_s3_bucket" "app_bucket" {
  bucket = "my-dotnet-app-bucket"
}

# Upload the zipped application to S3
resource "aws_s3_bucket_object" "app_version" {
  bucket = aws_s3_bucket.app_bucket.bucket
  key    = "dotnet-app.zip"
  source = data.archive_file.app_zip.output_path 
}

# Create an Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "dotnet_app" {
  name        = "DotNetApp"
  description = "Elastic Beanstalk Application for .NET 4.8"
}

# Create an Elastic Beanstalk Application Version
resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.dotnet_app.name
  bucket      = aws_s3_bucket.app_bucket.bucket
  key         = aws_s3_bucket_object.app_version.key
}

# Create an Elastic Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "dotnet_environment" {
  name                = "DotNetEnv"
  application         = aws_elastic_beanstalk_application.dotnet_app.name
  solution_stack_name = "64bit Windows Server 2019 v2.8.0 running IIS 10.0"  # For .NET Framework 4.8 on Windows

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.medium" 
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ENVIRONMENT"
    value     = "production"
  }

  version_label = aws_elastic_beanstalk_application_version.app_version.name
}

# IAM Role for Elastic Beanstalk (if needed)
resource "aws_iam_instance_profile" "eb_profile" {
  name = "eb-instance-profile"
  
  role {
    name = "aws-elasticbeanstalk-ec2-role"
  }
}
