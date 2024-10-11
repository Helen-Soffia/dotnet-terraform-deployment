provider "aws" {
  region = "us-east-1"  # Specify the AWS region
}

# # Hardcode the existing S3 bucket and object
# resource "aws_s3_object" "app_version" {
#   bucket = "elasticbeanstalk-us-east-1-825765409649"  # Hardcoded S3 bucket name
#   key    = "EvalWebApp/AWSDeploymentArchive_EvalWebApp_v20241002070149.zip"  # Hardcoded file path in S3 bucket
#   source = "EvalWebApp.zip"  # Local path to the file you are uploading
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
  bucket      = "dotnet-sample-github"  # Use the existing S3 bucket
  key         = "sample-eval.zip"  # Key of the existing S3 object
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
