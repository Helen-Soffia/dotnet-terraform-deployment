# Provider configuration
provider "aws" {
  region = "us-east-1" # Change this to your desired region
}

# VPC configuration
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dotnet-beanstalk-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "dotnet-beanstalk-igw"
  }
}

# Public subnets for the load balancer
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "dotnet-beanstalk-public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "dotnet-beanstalk-public-subnet-2"
  }
}

# Private subnets for EC2 instances
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "dotnet-beanstalk-private-subnet-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "dotnet-beanstalk-private-subnet-2"
  }
}

# NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "dotnet-beanstalk-nat-gw"
  }
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "dotnet-beanstalk-public-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "dotnet-beanstalk-private-rt"
  }
}

# Route table associations
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

# Security Group for EC2 instances
resource "aws_security_group" "ec2_sg" {
  name        = "eb-ec2-sg"
  description = "Security group for Elastic Beanstalk EC2 instances"
  vpc_id      = aws_vpc.main.id

  # Allow outbound traffic to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eb-ec2-sg"
  }
}

# Security Group for ELB
resource "aws_security_group" "elb_sg" {
  name        = "eb-elb-sg"
  description = "Security group for Elastic Beanstalk ELB"
  vpc_id      = aws_vpc.main.id

  # Allow inbound HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound HTTPS traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eb-elb-sg"
  }
}

# Security Group Rule to allow traffic from ELB to EC2
resource "aws_security_group_rule" "elb_to_ec2_in" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.elb_sg.id
  security_group_id        = aws_security_group.ec2_sg.id
}

resource "aws_security_group_rule" "elb_to_ec2_out" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_sg.id
  security_group_id        = aws_security_group.elb_sg.id
}

# IAM role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "aws-elasticbeanstalk-ec2-role-terraform"

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

# Attach necessary policies to the role
resource "aws_iam_role_policy_attachment" "web_tier" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "worker_tier" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
  role       = aws_iam_role.ec2_role.name
}

# Create an instance profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "aws-elasticbeanstalk-ec2-role-terraform"
  role = aws_iam_role.ec2_role.name
}

# Create a key pair
resource "aws_key_pair" "deployer" {
  key_name   = "devops-key"
  public_key = file("${path.module}/devops.pem.pub") # Replace with the path to your public key file
}

# Elastic Beanstalk application
resource "aws_elastic_beanstalk_application" "dotnet_app" {
  name        = "dotnet-48-app"
  description = ".NET 4.8 Application"
}

# Elastic Beanstalk application version
resource "aws_elastic_beanstalk_application_version" "dotnet_app_version" {
  name        = "dotnet-48-app-version-1.0.0"
  application = aws_elastic_beanstalk_application.dotnet_app.name
  description = "Application version created by Terraform"
  bucket      = "dotnet-sample-github"
  key         = "sample-eval-codepipeline/sample-eval.zip"
}

# Elastic Beanstalk environment
resource "aws_elastic_beanstalk_environment" "dotnet_env" {
  name                = "dotnet-48-environment"
  application         = aws_elastic_beanstalk_application.dotnet_app.name
  solution_stack_name = "64bit Windows Server 2019 v2.15.5 running IIS 10.0"
  version_label       = aws_elastic_beanstalk_application_version.dotnet_app_version.name

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.main.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${aws_subnet.public_1.id},${aws_subnet.public_2.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.private_1.id},${aws_subnet.private_2.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "false"
  }

  # Apply EC2 security group
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.ec2_sg.id
  }

  # Apply ELB security group
  setting {
    namespace = "aws:elb:loadbalancer"
    name      = "SecurityGroups"
    value     = aws_security_group.elb_sg.id
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = aws_key_pair.deployer.key_name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.ec2_instance_profile.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.medium"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "RootVolumeType"
    value     = "gp3"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "RootVolumeSize"
    value     = "60"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "DisableIMDSv1"
    value     = "true"
  }

  setting {
    namespace = "aws:ec2:instances"
    name      = "EnableSpot"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ENVIRONMENT"
    value     = "production"
  }

  # SSL Configuration
  setting {
    namespace = "aws:elb:listener:443"
    name      = "ListenerProtocol"
    value     = "HTTPS"
  }

  setting {
    namespace = "aws:elb:listener:443"
    name      = "InstancePort"
    value     = 80
  }

  setting {
    namespace = "aws:elb:listener:443"
    name      = "SSLCertificateId"
    value     = "arn:aws:acm:us-east-1:825765409649:certificate/80f280b6-f74f-47ae-b171-5b9d2709f0d4" # Replace with your SSL certificate ARN
  }

  # Optional: Redirect HTTP to HTTPS
  setting {
    namespace = "aws:elb:listener:80"
    name      = "ListenerEnabled"
    value     = "false"
  }

  # Load Balancer configuration
  setting {
    namespace = "aws:elb:loadbalancer"
    name      = "CrossZone"
    value     = "true"
  }

  # Auto Scaling configuration
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "2"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "4"
  }

  # Health check configuration
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/"
  }
}

# Output the Elastic Beanstalk environment URL
output "beanstalk_endpoint" {
  value = aws_elastic_beanstalk_environment.dotnet_env.endpoint_url
}
