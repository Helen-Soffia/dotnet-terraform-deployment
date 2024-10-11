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

- .NET Framework 4.8 SDK (for building the application)
- AWS CLI (for managing AWS services)
- Terraform (for managing infrastructure as code)
- Git (for version control)

You also need an AWS account and an S3 bucket to store the application package.

## Setup

1. Clone the repository:

    ```bash
    git clone https://github.com/Helen-Soffia/dotnet-terraform-deployment.git
    cd dotnet-terraform-deployment
    ```

2. Install Terraform:

    Follow the official [Terraform installation guide](https://learn.hashicorp.com/tutorials/terraform/install-cli) to install Terraform on your machine.

3. Set up AWS CLI:

    Configure the AWS CLI with your credentials:

    ```bash
    aws configure
    ```

4. Install .NET Framework SDK:

    If you haven't already, download and install the .NET Framework 4.8 SDK from Microsoft's website.

## Deployment

### Step 1: Build and Package the .NET Application

1. Open a terminal in the project root and build the application:

    ```bash
    dotnet build
    ```

2. Publish the application:

    ```bash
    dotnet publish -c Release
    ```

3. Zip the published output:

    ```bash
    zip -r app.zip ./bin/Release/net48/publish/
    ```

4. Upload the zip file to your S3 bucket:

    ```bash
    aws s3 cp app.zip s3://your-s3-bucket-name/app.zip
    ```

### Step 2: Deploy Using Terraform

1. Navigate to the Terraform directory:

    ```bash
    cd terraform
    ```

2. Initialize Terraform:

    ```bash
    terraform init
    ```

3. Plan the deployment:

    ```bash
    terraform plan
    ```

4. Apply the Terraform configuration:

    ```bash
    terraform apply
    ```

    This will create the necessary AWS Elastic Beanstalk environment and deploy the application from your S3 bucket.

### Step 3: Verify the Deployment

Once Terraform finishes applying the changes, you can access your .NET application via the URL provided by Elastic Beanstalk. You can view the output in your terminal.

## Terraform Directory Structure

- `main.tf`: Main Terraform configuration file defining AWS resources.
- `variables.tf`: Contains variables used throughout the Terraform configuration.
- `outputs.tf`: Defines outputs like the URL of the Elastic Beanstalk environment.
- `provider.tf`: Configures the AWS provider for Terraform.
