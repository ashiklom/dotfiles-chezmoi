---
name: terraform
description: Use this skill when working with Terraform infrastructure-as-code. Triggers include .tf files, terraform commands, AWS infrastructure provisioning, IAM role configuration, and IaC best practices.
---

# Terraform Agent Skill

AI agent skill for working with Terraform infrastructure-as-code, focusing on AWS best practices, common patterns, and avoiding configuration pitfalls.

## Overview

This skill helps AI agents assist users with:
- Writing and reviewing Terraform configurations
- AWS infrastructure provisioning
- IAM role and policy configuration
- Terraform best practices and validation patterns
- Troubleshooting common Terraform issues

### When to Use This Skill

Activate this skill when users need to:
- Create or modify `.tf` files
- Configure AWS infrastructure with Terraform
- Set up IAM roles, policies, and permissions
- Implement input validation in Terraform variables
- Debug Terraform configuration or runtime errors
- Apply IaC best practices

## AWS-Specific Patterns

### Region

When working on repositories related to NASA data (e.g., anything related to GMAO, SMCE, SMDC, etc.), if no region is specified or obvious from the context, default to region `us-west-2`.
Otherwise, prompt the user for the region.

### AWS Role Chaining Session Duration Limitation

#### Issue

When working with AWS IAM roles and STS (Security Token Service), there is a critical limitation with **role chaining** that affects session duration.

#### Background

**Role chaining** occurs when:
1. An entity (user, EC2 instance, Lambda function) assumes Role A
2. That assumed Role A then assumes Role B

Common scenarios include:
- Lambda functions (running with an execution role) assuming another role
- EC2 instances (with instance profile) assuming additional roles
- Cross-account access where Role A assumes Role B in another account

#### The Limitation

**When role chaining occurs, AWS enforces a 1-hour (3600 seconds) maximum session duration**, regardless of:
- The role's configured `MaxSessionDuration` setting
- The `DurationSeconds` parameter in the `AssumeRole` call
- Any other configuration

##### Error Symptom

If you request a session duration longer than 1 hour in a role chaining scenario, you'll get:

```
ValidationError: The requested DurationSeconds exceeds the 1 hour session limit for roles assumed by role chaining.
```

#### Terraform Implementation

##### ❌ Incorrect (Will Fail at Runtime)

```hcl
# Lambda execution role
resource "aws_iam_role" "lambda_execution" {
  name               = "lambda-execution-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Target role that Lambda will assume
resource "aws_iam_role" "target_role" {
  name                 = "target-role"
  max_session_duration = 43200  # ❌ This will be ignored due to role chaining!
  assume_role_policy   = data.aws_iam_policy_document.target_assume.json
}

# Lambda tries to assume with 12-hour duration
resource "aws_lambda_function" "example" {
  environment {
    variables = {
      SESSION_DURATION = "43200"  # ❌ Will fail at runtime!
    }
  }
}
```

##### ✅ Correct (With Validation)

```hcl
variable "session_duration_seconds" {
  type        = number
  description = "Duration of temporary credentials in seconds (900-3600). Limited to 1 hour due to AWS role chaining restrictions."
  default     = 3600

  validation {
    condition     = var.session_duration_seconds >= 900 && var.session_duration_seconds <= 3600
    error_message = "Session duration must be between 15 minutes (900s) and 1 hour (3600s). AWS limits role chaining (role assuming another role) to a maximum of 1 hour, regardless of the role's MaxSessionDuration setting."
  }
}

resource "aws_iam_role" "target_role" {
  name                 = "target-role"
  max_session_duration = var.session_duration_seconds  # ✅ Respects 1-hour limit
  assume_role_policy   = data.aws_iam_policy_document.target_assume.json
}

resource "aws_lambda_function" "example" {
  environment {
    variables = {
      SESSION_DURATION = var.session_duration_seconds  # ✅ Max 3600
    }
  }
}
```

#### Detection Strategy

When designing IAM role architectures, ask:

1. **Is the role being assumed by another assumed role?**
   - Lambda functions → YES (execution role is assumed)
   - EC2 instances → YES (instance profile is assumed)
   - Direct IAM user → NO (not role chaining)

2. **What is the maximum required session duration?**
   - If > 1 hour and role chaining → Architecture needs redesign
   - If ≤ 1 hour → Use role chaining with validation

#### Solutions

##### Option 1: Accept 1-Hour Limit (Recommended)
- **Use case**: Most API/CLI operations
- **Implementation**: Set `max_session_duration = 3600` and validate
- **Workaround**: Implement credential refresh logic in long-running applications

##### Option 2: Eliminate Role Chaining
- **Use case**: When longer sessions are absolutely required
- **Implementation**: 
  - Use IAM user credentials with `GetFederationToken` (not recommended)
  - Attach permissions directly to execution role (less flexible)
  - Use service-specific authentication (e.g., S3 bucket policies)

##### Option 3: Hybrid Approach
- **Use case**: Mix of short and long operations
- **Implementation**:
  - Short operations: Use role chaining with 1-hour limit
  - Long operations: Use different authentication mechanism

#### Real-World Example: S3 Access API

**Scenario**: API Gateway → Lambda → Assume S3 Access Role → Return credentials

**Problem**: Initially configured for 12-hour sessions, but Lambda's role chaining limited it to 1 hour.

**Solution**:
```hcl
variable "session_duration_seconds" {
  type        = number
  description = "Duration of temporary credentials in seconds (900-3600). Limited to 1 hour due to AWS role chaining restrictions when Lambda assumes a role."
  default     = 3600

  validation {
    condition     = var.session_duration_seconds >= 900 && var.session_duration_seconds <= 3600
    error_message = "Session duration must be between 15 minutes (900s) and 1 hour (3600s). AWS limits role chaining to 1 hour."
  }
}
```

**Result**: Terraform validates at plan time, preventing runtime errors.

#### Best Practices

1. **Always validate session duration** in Terraform variables when role chaining is involved
2. **Document the limitation** in variable descriptions and README files
3. **Fail fast** with clear validation error messages at plan time (not apply time)
4. **Test with actual role assumption** to verify expected behavior
5. **Consider credential refresh patterns** for long-running applications

#### AWS Documentation References

- [IAM Role Maximum Session Duration](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session)
- [Role Chaining Limitations](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-role-chaining)
- [AssumeRole API](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html)

#### Summary

| Scenario | Max Session Duration |
|----------|---------------------|
| IAM User directly assumes role | Up to role's `MaxSessionDuration` (max 12 hours) |
| Role chaining (role assumes role) | **1 hour (3600 seconds)** - hardcoded AWS limit |
| Federation token | Up to 36 hours (IAM user), 12 hours (root) |

**Key Takeaway**: When designing Lambda-based credential vending systems or cross-account access patterns, always assume a 1-hour maximum session duration and validate accordingly in Terraform.

## Terraform Best Practices

### Variable Validation

Use Terraform's built-in validation blocks to catch configuration errors at plan time:

```hcl
variable "environment" {
  type        = string
  description = "Deployment environment"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

**When to use validation**:
- Enforce allowed value sets
- Validate ranges (numeric, string length)
- Prevent runtime errors from invalid configurations
- Document constraints clearly

### State Management

**Placeholder for future content:**
- Remote state configuration (S3, Terraform Cloud)
- State locking with DynamoDB
- State file security and encryption
- Workspace strategies

### Module Development

**Placeholder for future content:**
- Module structure and organization
- Input/output variable patterns
- Versioning strategies
- Registry publishing

### Provider Configuration

**Placeholder for future content:**
- AWS provider configuration patterns
- Multi-region deployments
- Provider aliasing
- Credential management

### Resource Lifecycle Management

**Placeholder for future content:**
- `create_before_destroy` patterns
- `prevent_destroy` for critical resources
- `ignore_changes` for external modifications
- Dependency management with `depends_on`

## Code Style Guidelines

### General Conventions

- Use 2 spaces for indentation
- Use snake_case for resource names
- Add descriptions to all variables and outputs
- Group related resources together
- Use `terraform fmt` for consistent formatting

### Naming Patterns

**Resources**:
```hcl
resource "aws_iam_role" "lambda_execution" {  # type_purpose
  name = "${var.project_name}-lambda-execution-role"
}
```

**Variables**:
```hcl
variable "session_duration_seconds" {  # descriptive_with_units
  type        = number
  description = "Session duration in seconds"
}
```

### Documentation

- Include descriptions for all variables, outputs, and data sources
- Add inline comments for complex logic or non-obvious configurations
- Document validation rules and their rationale
- Reference AWS documentation URLs for specific limitations or behaviors

## Common Patterns

### IAM Role with Policy

```hcl
# IAM role
resource "aws_iam_role" "example" {
  name               = "${var.project_name}-example-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Trust policy
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Permissions policy
data "aws_iam_policy_document" "permissions" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${aws_s3_bucket.example.arn}/*"]
  }
}

resource "aws_iam_role_policy" "example" {
  role   = aws_iam_role.example.id
  policy = data.aws_iam_policy_document.permissions.json
}
```

### Tags and Metadata

```hcl
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket" "example" {
  bucket = "${var.project_name}-${var.environment}-data"
  
  tags = merge(
    local.common_tags,
    {
      Purpose = "Data storage"
    }
  )
}
```

## Troubleshooting

### Common Errors

**"The requested DurationSeconds exceeds the 1 hour session limit"**
- See AWS Role Chaining section above
- Check if role chaining is involved
- Validate session duration ≤ 3600 seconds

**State locking errors**
- Verify DynamoDB table exists
- Check IAM permissions for state locking
- Manually release stuck locks if safe

**Provider initialization failures**
- Verify AWS credentials are configured
- Check provider version constraints
- Ensure correct region is specified

### Debugging Tips

1. Use `terraform plan` to preview changes before applying
2. Enable detailed logging: `TF_LOG=DEBUG terraform apply`
3. Use `terraform state list` to inspect current state
4. Validate configurations with `terraform validate`
5. Format code with `terraform fmt -recursive`

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
