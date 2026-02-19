---
description: Create an AWS EC2 sandbox with auto-shutdown
agent: build
---

You are tasked with creating an AWS EC2 sandbox instance using Terraform. This instance will automatically terminate after a user-specified lifetime.

## Step 1: Verify AWS Credentials

First, verify that AWS credentials are configured:

!`aws sts get-caller-identity`

If this command fails, inform the user that they need to configure AWS credentials first and stop execution.

## Step 2: Get Working Directory

Capture the current working directory where the command was invoked:

!`pwd`

Store this directory path and use it for all subsequent operations. All file operations must happen in this directory.

## Step 3: Check for Existing Sandbox

Check if a sandbox already exists in the working directory:

!`test -d .sandbox && test -f .sandbox/terraform.tfstate && echo "EXISTS" || echo "NONE"`

If a sandbox already exists, inform the user and ask if they want to destroy it first using `/aws-ec2-sandbox-destroy`.

## Step 4: Prompt User for Configuration

Ask the user for the following configuration (show defaults clearly):

1. **AWS Region** (default: us-west-2)
2. **Instance lifetime in hours** - after this time, the instance will automatically terminate (default: 4)
3. **Instance category** - e.g., c7i-flex, c7i, m7i, t3 (default: c7i-flex)
4. **Number of vCPUs** - 2, 4, 8, 16, or 32 (default: 4)
5. **Root volume size in GB** (default: 50)

## Step 5: Create .sandbox Directory

Create the `.sandbox/` directory in the working directory captured in Step 2. Use the bash tool with the workdir parameter set to the working directory.

Example: If working directory is `/home/user/myproject`, create `/home/user/myproject/.sandbox/`

## Step 6: Generate Terraform Configuration Files

Create the following files in the `.sandbox/` directory of the working directory. Use absolute paths constructed from the working directory captured in Step 2.

For each file, use the Write tool with `filePath` set to `<working_directory>/.sandbox/<filename>`.

### variables.tf
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "lifetime_hours" {
  description = "Hours until instance auto-terminates"
  type        = number
}

variable "instance_category" {
  description = "EC2 instance category"
  type        = string
}

variable "vcpus" {
  description = "Number of vCPUs"
  type        = number
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GB"
  type        = number
}
```

### data.tf
```hcl
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

data "aws_subnet" "default" {
  id = data.aws_subnets.default.ids[0]
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

### main.tf
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  size_suffix = {
    2  = "large"
    4  = "xlarge"
    8  = "2xlarge"
    16 = "4xlarge"
    32 = "8xlarge"
  }
  
  instance_type = "${var.instance_category}.${local.size_suffix[var.vcpus]}"
  
  timestamp = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timestamp())
  shutdown_time = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timeadd(timestamp(), "${var.lifetime_hours}h"))
}

# Security Group - SSM access only (egress only)
resource "aws_security_group" "sandbox" {
  name_prefix = "opencode-sandbox-"
  description = "Security group for OpenCode sandbox - SSM access only"
  vpc_id      = data.aws_vpc.default.id
  
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name      = "opencode-sandbox-sg"
    ManagedBy = "opencode-terraform"
  }
}

# IAM Role for EC2 instance
resource "aws_iam_role" "sandbox" {
  name_prefix = "opencode-sandbox-"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = {
    Name      = "opencode-sandbox-role"
    ManagedBy = "opencode-terraform"
  }
}

# Attach AWS managed policy for SSM access
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.sandbox.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach AWS managed policy for CloudWatch Agent Server
resource "aws_iam_role_policy_attachment" "cloudwatch_server" {
  role       = aws_iam_role.sandbox.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach AWS managed policy for CloudWatch Agent Admin
resource "aws_iam_role_policy_attachment" "cloudwatch_admin" {
  role       = aws_iam_role.sandbox.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"
}

# Inline policy for S3 full access
resource "aws_iam_role_policy" "s3_access" {
  name_prefix = "s3-full-access-"
  role        = aws_iam_role.sandbox.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          "arn:aws:s3:::*"
        ]
      }
    ]
  })
}

# Instance profile to attach role to EC2
resource "aws_iam_instance_profile" "sandbox" {
  name_prefix = "opencode-sandbox-"
  role        = aws_iam_role.sandbox.name
  
  tags = {
    Name      = "opencode-sandbox-profile"
    ManagedBy = "opencode-terraform"
  }
}

# EC2 Instance
resource "aws_instance" "sandbox" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = local.instance_type
  subnet_id              = data.aws_subnet.default.id
  vpc_security_group_ids = [aws_security_group.sandbox.id]
  iam_instance_profile   = aws_iam_instance_profile.sandbox.name
  
  # Root block device configuration
  root_block_device {
    volume_size           = var.root_volume_size_gb
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = false
  }
  
  user_data = templatefile("${path.module}/user-data.sh", {
    lifetime_hours = var.lifetime_hours
  })
  
  tags = {
    Name          = "opencode-sandbox-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
    Project       = basename(abspath(path.root))
    ManagedBy     = "opencode-terraform"
    AutoShutdown  = "true"
    ShutdownTime  = local.shutdown_time
    CreatedAt     = local.timestamp
    LifetimeHours = var.lifetime_hours
  }
  
  # Wait for instance to be fully ready before completing
  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "⏳ Waiting for instance ${self.id} to complete status checks..."
      echo "   This typically takes 2-3 minutes..."
      
      if aws ec2 wait instance-status-ok \
          --instance-ids ${self.id} \
          --region ${var.aws_region}; then
        echo "✅ Instance ${self.id} is ready and all status checks passed!"
      else
        echo "❌ Instance status check wait failed or timed out"
        exit 1
      fi
    EOT
  }
}
```

### outputs.tf
```hcl
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.sandbox.id
}

output "private_ip" {
  description = "Private IP address"
  value       = aws_instance.sandbox.private_ip
}

output "availability_zone" {
  description = "Availability Zone"
  value       = aws_instance.sandbox.availability_zone
}

output "instance_type" {
  description = "EC2 instance type"
  value       = aws_instance.sandbox.instance_type
}

output "root_volume_size_gb" {
  description = "Root volume size in GB"
  value       = var.root_volume_size_gb
}

output "region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

output "created_at" {
  description = "Instance creation timestamp"
  value       = local.timestamp
}

output "shutdown_time" {
  description = "Scheduled auto-shutdown time"
  value       = local.shutdown_time
}

output "ssm_connect_command" {
  description = "AWS SSM Session Manager connection command"
  value       = "aws ssm start-session --target ${aws_instance.sandbox.id} --region ${var.aws_region}"
}
```

### user-data.sh
```bash
#!/bin/bash
set -e

# Logging
exec > >(tee /var/log/sandbox-init.log)
exec 2>&1

echo "=== OpenCode EC2 Sandbox Initialization ==="
echo "Started at: $(date)"

# Set lifetime from Terraform variable
LIFETIME_HOURS=${lifetime_hours}

# Calculate shutdown time
SHUTDOWN_TIME=$(date -d "+$LIFETIME_HOURS hours" '+%Y-%m-%d %H:%M:%S')
SHUTDOWN_EPOCH=$(date -d "+$LIFETIME_HOURS hours" '+%s')

echo "Instance will auto-shutdown at: $SHUTDOWN_TIME"
echo "Shutdown epoch: $SHUTDOWN_EPOCH"

# Create systemd service for shutdown
cat > /etc/systemd/system/sandbox-shutdown.service <<'EOF'
[Unit]
Description=Auto-shutdown sandbox instance

[Service]
Type=oneshot
ExecStart=/usr/sbin/shutdown -h now
EOF

# Create timer for shutdown
cat > /etc/systemd/system/sandbox-shutdown.timer <<EOF
[Unit]
Description=Timer for sandbox auto-shutdown

[Timer]
OnCalendar=$SHUTDOWN_TIME
AccuracySec=1min

[Install]
WantedBy=timers.target
EOF

# Enable and start timer
systemctl daemon-reload
systemctl enable sandbox-shutdown.timer
systemctl start sandbox-shutdown.timer

# Verify timer is active
echo "=== Timer Status ==="
systemctl status sandbox-shutdown.timer --no-pager || true
systemctl list-timers sandbox-shutdown.timer --no-pager || true

echo "=== Initialization Complete ==="
echo "Root volume size: $(df -h / | tail -1 | awk '{print $2}')"
echo "Auto-shutdown scheduled for: $SHUTDOWN_TIME"
echo "Current time: $(date)"
```

## Step 7: Create Terraform Variables File

Create a `terraform.tfvars` file in the `.sandbox/` directory with the user's inputs.

Use the Write tool with `filePath` set to `<working_directory>/.sandbox/terraform.tfvars`.

```hcl
aws_region           = "<USER_INPUT>"
lifetime_hours       = <USER_INPUT>
instance_category    = "<USER_INPUT>"
vcpus               = <USER_INPUT>
root_volume_size_gb = <USER_INPUT>
```

## Step 8: Initialize and Apply Terraform

Run terraform commands using the bash tool with `workdir` parameter set to `<working_directory>/.sandbox`:

!`terraform init -upgrade`

!`terraform apply -auto-approve`

## Step 9: Export Outputs to JSON

Use the bash tool with `workdir` parameter set to `<working_directory>/.sandbox`:

!`terraform output -json > output.json`

## Step 10: Update .gitignore

Check if `.gitignore` exists in the working directory and add `.sandbox/` to it.

Use the bash tool with `workdir` parameter set to the working directory:

!`grep -q "^\.sandbox/$" .gitignore 2>/dev/null || (echo "" >> .gitignore && echo "# OpenCode EC2 Sandbox (managed by Terraform)" >> .gitignore && echo ".sandbox/" >> .gitignore)`

If `.gitignore` doesn't exist, create it with the entry using the Write tool.

## Step 11: Update AGENTS.md

Create or update the `AGENTS.md` file in the working directory with sandbox information. If the file exists, add a new section. If it doesn't exist, create it using the Write tool with `filePath` set to `<working_directory>/AGENTS.md`.

Add this content:

```markdown
## EC2 Sandbox

This project has an EC2 sandbox environment managed by OpenCode and Terraform.

- **Status**: Check `.sandbox/output.json` for current instance details
- **Connect**: Use the SSM command from the output below
- **Terraform**: Configuration in `.sandbox/` directory (gitignored)
- **Auto-shutdown**: Instance will auto-terminate after configured lifetime
- **Cleanup**: Run `/aws-ec2-sandbox-destroy` to manually terminate
- **Storage**: Root volume with configured size

**Note**: The `.sandbox/` directory is gitignored to prevent committing Terraform state and AWS instance details.
```

## Step 12: Display Success Message

Show the user a success message with the connection command. Read the `output.json` file from `<working_directory>/.sandbox/output.json` and display:

- Instance ID
- Instance Type
- Private IP
- Region
- Root Volume Size
- Created At
- Shutdown Time
- **SSM Connect Command** (formatted as a ready-to-run command)

Example format:
```
✅ EC2 Sandbox created successfully!

Instance ID: i-1234567890abcdef0
Instance Type: c7i-flex.xlarge
Private IP: 172.31.45.67
Region: us-west-2
Storage: 50 GB
Created: 2026-02-12T14:30:00Z
Auto-shutdown: 2026-02-12T18:30:00Z

Connect to your sandbox:
  aws ssm start-session --target i-1234567890abcdef0 --region us-west-2

Instance details saved to .sandbox/output.json
```

## Important Notes

- **Working Directory**: Capture the working directory at the start (Step 2) and use it consistently throughout
- **Bash Tool Usage**: Use the `workdir` parameter for all bash commands to ensure they execute in the correct location
- **File Paths**: Use absolute paths constructed from `<working_directory>` for all Write tool operations
- Ensure all Terraform files are created before running `terraform init`
- Handle errors gracefully and provide clear error messages
- If Terraform fails, preserve the error output for debugging
- Validate user inputs where possible (e.g., positive numbers, valid regions)
- The instance will automatically terminate after the specified lifetime
- **Critical**: Never use relative paths with `cd` commands - always use the `workdir` parameter instead
