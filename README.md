# dotnet-terraform-deployment

This repository demonstrates how to deploy a .NET Framework 4.8 application using Terraform to manage AWS Elastic Beanstalk. It includes the necessary infrastructure setup and automation scripts for deploying the application to AWS.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Deployment](#deployment)
- [Terraform Directory Structure](#terraform-directory-structure)
- [Contributing](#contributing)
- [License](#license)

## Prerequisites

Before you begin, ensure you have the following installed:

- **.NET Framework 4.8 SDK** (for building the application)
- **AWS CLI** (for managing AWS services)
- **Terraform** (for managing infrastructure as code)
- **Git** (for version control)

You also need an AWS account and S3 bucket to store the application package.

## Setup

1. **Clone the repository:**

   ```bash
   git clone https://github.com/Helen-Soffia/dotnet-terraform-deployment.git
   cd dotnet-terraform-deployment
Install Terraform:

Follow the official Terraform installation guide to install Terraform on your machine.

Set up AWS CLI:

Configure the AWS CLI with your credentials:

bash
Copy code
aws configure
Install .NET Framework SDK:

If you haven't already, download and install the .NET Framework 4.8 SDK from Microsoft's website.

Deployment
Step 1: Build and package the .NET application
Open a terminal in the project root and build the application:

bash
Copy code
dotnet build
Publish the application:

bash
Copy code
dotnet publish -c Release
Zip the published output:

bash
Copy code
zip -r app.zip ./bin/Release/net48/publish/
Upload the zip file to your S3 bucket:

bash
Copy code
aws s3 cp app.zip s3://your-s3-bucket-name/app.zip
Step 2: Deploy using Terraform
Navigate to the Terraform directory:

bash
Copy code
cd terraform
Initialize Terraform:

bash
Copy code
terraform init
Plan the deployment:

bash
Copy code
terraform plan
Apply the Terraform configuration:

bash
Copy code
terraform apply
This will create the necessary AWS Elastic Beanstalk environment and deploy the application from your S3 bucket.

Step 3: Verify the Deployment
Once Terraform finishes applying the changes, you can access your .NET application via the URL provided by Elastic Beanstalk. You can view the output in your terminal.

Terraform Directory Structure
main.tf: Main Terraform configuration file defining AWS resources.
variables.tf: Contains variables used throughout the Terraform configuration.
outputs.tf: Defines outputs like the URL of the Elastic Beanstalk environment.
provider.tf: Configures the AWS provider for Terraform
