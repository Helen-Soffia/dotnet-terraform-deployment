provider "aws" {
  region = "us-east-1"  # Change to your AWS region
}

variable "app_s3_bucket" {}
variable "app_s3_key" {}

resource "aws_s3_bucket_object" "app_version" {
  bucket = var.app_s3_bucket
  key    = var.app_s3_key
  source = "dotnet-app.zip"
}

# # Create an S3 bucket for storing the application bundle
# resource "aws_s3_bucket" "app_bucket" {
#   bucket = "my-dotnet-app-bucket"  # Change this to a unique bucket name
# }

# # Upload the zipped application to S3 using the new resource
# resource "aws_s3_object" "app_version" {
#   bucket = aws_s3_bucket.app_bucket.bucket
#   key    = "dotnet-app.zip"  # The name of the file in the S3 bucket
#   source = "dotnet-app.zip"  # Source is the zipped file created above
# }

# Create an Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "dotnet_app" {
  name        = "DotNetApp"
  description = "Elastic Beanstalk Application for .NET 4.8"
}

# Create an Elastic Beanstalk Application Version
resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = "v1-${timestamp()}"  # Use a unique version name
  application = aws_elastic_beanstalk_application.dotnet_app.name
  bucket      = aws_s3_bucket.app_bucket.bucket
  key         = aws_s3_object.app_version.key
}

resource "aws_elastic_beanstalk_environment" "dotnet_environment" {
  name                = "DotNetEnv"
  application         = aws_elastic_beanstalk_application.dotnet_app.id
  solution_stack_name = "64bit Windows Server 2019 v2.15.5 running IIS 10.0"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.medium"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_profile.arn
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ENVIRONMENT"
    value     = "production"
  }

  version_label = aws_elastic_beanstalk_application_version.app_version.name
}

# Reference the existing IAM Role
data "aws_iam_role" "existing_eb_role" {
  name = "aws-elasticbeanstalk-ec2-role"
}

resource "aws_iam_instance_profile" "eb_profile" {
  name = "eb-instance-profile"
  role = data.aws_iam_role.existing_eb_role.name
}
