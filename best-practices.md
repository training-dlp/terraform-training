# 🏗️ Terraform Best Practices

A comprehensive guide to writing production-grade Terraform code — with real-world examples for each practice.

---

## Table of Contents

1. [Use Remote State](#1-use-remote-state)
2. [Use Existing Shared and Community Modules](#2-use-existing-shared-and-community-modules)
3. [Import Existing Infrastructure](#3-import-existing-infrastructure)
4. [Avoid Hardcoding Variables](#4-avoid-hardcoding-variables)
5. [Always Format and Validate](#5-always-format-and-validate)
6. [Use a Consistent Naming Convention](#6-use-a-consistent-naming-convention)
7. [Tag Your Resources](#7-tag-your-resources)
8. [Introduce Policy as Code](#8-introduce-policy-as-code)
9. [Implement a Secrets Management Strategy](#9-implement-a-secrets-management-strategy)
10. [Test Your Terraform Code](#10-test-your-terraform-code)
11. [Enable Debug / Troubleshooting](#11-enable-debug--troubleshooting)
12. [Build Modules Wherever Possible](#12-build-modules-wherever-possible)
13. [Use Loops and Conditionals](#13-use-loops-and-conditionals)
14. [Use Functions](#14-use-functions)
15. [Take Advantage of Dynamic Blocks](#15-take-advantage-of-dynamic-blocks)
16. [Use Terraform Workspaces](#16-use-terraform-workspaces)
17. [Use the Lifecycle Block](#17-use-the-lifecycle-block)
18. [Use Variable Validations](#18-use-variable-validations)
19. [Leverage Helper Tools](#19-leverage-helper-tools)
20. [Take Advantage of IDE Extensions](#20-take-advantage-of-ide-extensions)

---

## 1. Use Remote State

Storing state locally is risky and makes collaboration impossible. Use a remote backend to share state across teams, enable state locking, and protect against data loss.

**Why it matters:**
- Enables team collaboration
- Prevents concurrent state corruption via locking
- Keeps sensitive state output off local disks

```hcl
# backend.tf — S3 remote backend with DynamoDB locking
terraform {
  backend "s3" {
    bucket         = "my-company-terraform-state"
    key            = "prod/networking/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

```hcl
# Create the DynamoDB lock table (one-time setup)
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

> 💡 **Tip:** Use separate state files per environment (`dev/`, `staging/`, `prod/`) and per component (`networking/`, `compute/`, `database/`) to limit blast radius.

---

## 2. Use Existing Shared and Community Modules

Don't reinvent the wheel. The [Terraform Registry](https://registry.terraform.io/) has thousands of vetted, well-maintained modules for AWS, Azure, GCP, and more.

**Why it matters:**
- Faster delivery — skip boilerplate
- Battle-tested by the community
- Regular security and feature updates

```hcl
# Use the official AWS VPC module instead of writing it from scratch
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "my-production-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

> 💡 **Tip:** Always pin module versions using `version = "~> X.Y"` to avoid unexpected breaking changes during upgrades.

---

## 3. Import Existing Infrastructure

Already have cloud resources not managed by Terraform? Use `terraform import` (or the `import` block in Terraform 1.5+) to bring them under IaC management.

**Why it matters:**
- Avoids resource recreation or drift
- Gradually migrate existing infra to Terraform
- No downtime required

```hcl
# Terraform 1.5+ — declarative import block
import {
  to = aws_s3_bucket.existing_logs
  id = "my-existing-log-bucket-name"
}

resource "aws_s3_bucket" "existing_logs" {
  bucket = "my-existing-log-bucket-name"
}
```

```bash
# Classic CLI import (Terraform < 1.5)
terraform import aws_s3_bucket.existing_logs my-existing-log-bucket-name

# Generate config from an existing resource (Terraform 1.5+)
terraform plan -generate-config-out=generated.tf
```

> 💡 **Tip:** After importing, always run `terraform plan` to confirm zero drift before committing the state.

---

## 4. Avoid Hardcoding Variables

Hardcoded values make code brittle, non-reusable, and difficult to promote across environments. Parameterise everything.

**Why it matters:**
- Reuse the same code across dev, staging, and prod
- Single source of truth per environment via `.tfvars`
- Reduces copy-paste errors

```hcl
# ❌ Bad — hardcoded values scattered in resources
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"
  subnet_id     = "subnet-abc123"
}
```

```hcl
# ✅ Good — variables with descriptions and types
variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID to launch the instance in"
  type        = string
}

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
}
```

```hcl
# prod.tfvars
ami_id        = "ami-0c55b159cbfafe1f0"
instance_type = "t3.large"
subnet_id     = "subnet-prod-001"
```

```bash
terraform apply -var-file="prod.tfvars"
```

---

## 5. Always Format and Validate

Enforce consistent formatting and catch errors before they reach `apply`. Make these part of your CI/CD pipeline.

**Why it matters:**
- Consistent, readable code across the team
- Catches syntax errors and misconfigurations early
- Reduces review friction

```bash
# Format all .tf files in place
terraform fmt -recursive

# Check formatting without changing files (great for CI)
terraform fmt -check -recursive

# Validate configuration syntax and internal consistency
terraform validate

# Full pre-apply workflow
terraform fmt -recursive && terraform validate && terraform plan
```

```yaml
# .github/workflows/terraform.yml — CI pipeline snippet
- name: Terraform Format Check
  run: terraform fmt -check -recursive

- name: Terraform Validate
  run: |
    terraform init -backend=false
    terraform validate
```

> 💡 **Tip:** Add a pre-commit hook using [`pre-commit`](https://pre-commit.com/) with `terraform_fmt` and `terraform_validate` hooks so formatting is enforced locally before any commit.

---

## 6. Use a Consistent Naming Convention

Resource names should be predictable and encode context. Adopt a convention and apply it everywhere.

**Why it matters:**
- Makes resources easily discoverable in the console
- Avoids naming collisions across environments
- Communicates ownership and purpose at a glance

```hcl
# Recommended pattern: {org}-{env}-{region}-{component}-{suffix}
locals {
  prefix = "${var.org}-${var.environment}-${var.region}"
}

resource "aws_s3_bucket" "app_logs" {
  bucket = "${local.prefix}-app-logs"
  # e.g. myco-prod-use1-app-logs
}

resource "aws_security_group" "web" {
  name        = "${local.prefix}-web-sg"
  description = "Security group for web tier"
  vpc_id      = module.vpc.vpc_id
  # e.g. myco-prod-use1-web-sg
}

resource "aws_db_instance" "main" {
  identifier = "${local.prefix}-postgres-main"
  # e.g. myco-prod-use1-postgres-main
}
```

```hcl
# variables.tf
variable "org" {
  description = "Organisation short name"
  type        = string
  default     = "myco"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "region" {
  description = "Short AWS region code"
  type        = string
  default     = "use1"
}
```

> 💡 **Tip:** Document your naming convention in a `CONVENTIONS.md` in your repo root so new team members onboard quickly.

---

## 7. Tag Your Resources

Tags are your best friend for cost allocation, security auditing, and operational visibility. Enforce them via locals and policy.

**Why it matters:**
- Cost visibility by team, project, or environment
- Enables automated governance and compliance checks
- Simplifies incident response — who owns this resource?

```hcl
# locals.tf — centralised tag definition
locals {
  common_tags = {
    Organization = "MyCompany"
    Environment  = var.environment
    Team         = var.team
    Project      = var.project
    ManagedBy    = "Terraform"
    Repository   = "github.com/myco/infra"
    CostCenter   = var.cost_center
  }
}

# Merge common tags with resource-specific tags
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-web-server"
    Role = "web"
  })
}

resource "aws_s3_bucket" "data" {
  bucket = "${local.prefix}-data"

  tags = merge(local.common_tags, {
    Name        = "${local.prefix}-data"
    DataClass   = "confidential"
  })
}
```

> 💡 **Tip:** Use AWS Tag Policies or Azure Policy to enforce required tags at the cloud level as a safety net.

---

## 8. Introduce Policy as Code

Use tools like [OPA](https://www.openpolicyagent.org/) or [Sentinel](https://docs.hashicorp.com/sentinel) to enforce guardrails — before `apply` ever runs.

**Why it matters:**
- Prevents non-compliant infrastructure from being created
- Decouples policy from application code
- Auditable, version-controlled rules

```hcl
# Using Checkov for static analysis (free, open source)
# Install: pip install checkov
# Run:     checkov -d .
```

```python
# .checkov.yaml — skip specific checks with justification
skip-check:
  - CKV_AWS_20   # S3 bucket is intentionally public (CDN origin)
```

```bash
# Run Conftest with OPA policies
# Install: brew install conftest
conftest test plan.json --policy ./policies/

# Example OPA policy: deny unencrypted S3 buckets
# policies/s3.rego
```

```rego
# policies/s3.rego
package main

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  not resource.change.after.server_side_encryption_configuration
  msg := sprintf("S3 bucket '%s' must have server-side encryption enabled", [resource.address])
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  resource.change.after.acl == "public-read"
  msg := sprintf("S3 bucket '%s' must not be publicly readable", [resource.address])
}
```

```yaml
# CI integration
- name: Generate Terraform Plan JSON
  run: terraform show -json tfplan > plan.json

- name: Run OPA Policy Checks
  run: conftest test plan.json --policy ./policies/

- name: Run Checkov Security Scan
  run: checkov -d . --framework terraform
```

---

## 9. Implement a Secrets Management Strategy

Never store secrets in `.tf` files, `.tfvars`, or state files. Retrieve them dynamically at runtime.

**Why it matters:**
- Secrets in state or code = a breach waiting to happen
- Dynamic retrieval means no secret rotation needed in code
- Aligns with zero-trust security principles

```hcl
# ✅ Read secrets from AWS Secrets Manager at runtime
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/myapp/db-password"
}

resource "aws_db_instance" "main" {
  engine         = "postgres"
  instance_class = "db.t3.medium"
  username       = "admin"
  password       = data.aws_secretsmanager_secret_version.db_password.secret_string
  # Secret is retrieved dynamically — never stored in code
}
```

```hcl
# ✅ Use environment variables for provider credentials
# Never put AWS keys in .tf files!
# Set via: export AWS_ACCESS_KEY_ID=...
#          export AWS_SECRET_ACCESS_KEY=...
#          export AWS_SESSION_TOKEN=...

provider "aws" {
  region = var.aws_region
  # Credentials sourced from environment or IAM role automatically
}
```

```hcl
# ✅ Mark sensitive outputs — prevents them appearing in logs
output "db_connection_string" {
  value     = "postgresql://admin:${data.aws_secretsmanager_secret_version.db_password.secret_string}@${aws_db_instance.main.endpoint}/mydb"
  sensitive = true
}
```

> ⚠️ **Warning:** Even with `sensitive = true`, the value is still stored in plain text in the state file. Always encrypt your remote state.

---

## 10. Test Your Terraform Code

Treat infrastructure code like application code — write tests.

**Why it matters:**
- Catch regressions before they hit production
- Validate module behaviour with real cloud resources
- Build confidence for refactoring

```hcl
# native Terraform test (terraform test) — terraform 1.6+
# tests/s3_bucket.tftest.hcl

variables {
  environment = "test"
  bucket_name = "my-test-bucket-12345"
}

run "s3_bucket_is_private" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.main.block_public_acls == true
    error_message = "S3 bucket must block public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_server_side_encryption_configuration.main != null
    error_message = "S3 bucket must have encryption enabled"
  }
}
```

```go
// Terratest example — tests/s3_test.go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/gruntwork-io/terratest/modules/aws"
    "github.com/stretchr/testify/assert"
)

func TestS3BucketCreation(t *testing.T) {
    t.Parallel()

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../modules/s3",
        Vars: map[string]interface{}{
            "environment": "test",
            "bucket_name": "my-terratest-bucket-12345",
        },
    })

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    bucketID := terraform.Output(t, terraformOptions, "bucket_id")
    assert.NotEmpty(t, bucketID)

    // Verify bucket encryption is enabled
    aws.AssertS3BucketVersioningExists(t, "us-east-1", bucketID)
}
```

---

## 11. Enable Debug / Troubleshooting

When things go wrong, know how to extract detailed information quickly.

**Why it matters:**
- Faster incident resolution
- Understand provider API interactions
- Debug cryptic plan/apply errors

```bash
# Set log level: TRACE, DEBUG, INFO, WARN, ERROR
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log

# Log only the core (not providers)
export TF_LOG_CORE=INFO

# Log only providers
export TF_LOG_PROVIDER=TRACE

# Run apply with full debug output
TF_LOG=TRACE terraform apply 2>&1 | tee apply-debug.log

# Inspect state
terraform show                              # Human-readable current state
terraform state list                        # List all resources in state
terraform state show aws_instance.web       # Show a specific resource's state

# Refresh state (sync with actual cloud)
terraform refresh

# Force unlock a stuck state
terraform force-unlock <LOCK_ID>
```

```hcl
# Output useful debug info from your configuration
output "debug_vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID — useful for debugging downstream issues"
}
```

> 💡 **Tip:** Never commit files containing `TF_LOG=TRACE` output — they often contain sensitive values.

---

## 12. Build Modules Wherever Possible

Modules are Terraform's primary unit of reuse and abstraction. Structure your code so modules can be composed, tested, and versioned independently.

**Why it matters:**
- DRY infrastructure code
- Encapsulate complexity behind clean interfaces
- Version and share modules across teams

```
# Recommended module structure
modules/
  s3-private-bucket/
    main.tf
    variables.tf
    outputs.tf
    README.md
  ec2-web-server/
    main.tf
    variables.tf
    outputs.tf
    README.md

environments/
  prod/
    main.tf       ← calls modules
    variables.tf
    terraform.tfvars
    backend.tf
  dev/
    main.tf
```

```hcl
# modules/s3-private-bucket/main.tf
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}
```

```hcl
# modules/s3-private-bucket/variables.tf
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
```

```hcl
# modules/s3-private-bucket/outputs.tf
output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.this.arn
}
```

```hcl
# environments/prod/main.tf — consuming the module
module "app_logs" {
  source      = "../../modules/s3-private-bucket"
  bucket_name = "myco-prod-app-logs"
  tags        = local.common_tags
}
```

---

## 13. Use Loops and Conditionals

Replace repetitive resource blocks with `for_each`, `count`, and conditional expressions.

**Why it matters:**
- Eliminates copy-paste resource definitions
- Makes adding/removing instances a config change, not a code change
- Cleaner, more readable code

```hcl
# count — simple numeric repetition
resource "aws_iam_user" "dev_users" {
  count = length(var.developer_names)
  name  = var.developer_names[count.index]
}

# for_each with a set — preferred over count for named resources
variable "s3_buckets" {
  type    = set(string)
  default = ["logs", "backups", "artifacts"]
}

resource "aws_s3_bucket" "buckets" {
  for_each = var.s3_buckets
  bucket   = "myco-prod-${each.key}"
}

# for_each with a map — richer configuration per item
variable "ec2_instances" {
  type = map(object({
    instance_type = string
    subnet_id     = string
  }))
  default = {
    web = { instance_type = "t3.small",  subnet_id = "subnet-111" }
    api = { instance_type = "t3.medium", subnet_id = "subnet-222" }
    db  = { instance_type = "t3.large",  subnet_id = "subnet-333" }
  }
}

resource "aws_instance" "app" {
  for_each = var.ec2_instances

  ami           = var.ami_id
  instance_type = each.value.instance_type
  subnet_id     = each.value.subnet_id

  tags = { Name = "myco-prod-${each.key}" }
}

# Conditional — create a resource only in production
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = var.environment == "prod" ? 1 : 0

  alarm_name          = "high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "80"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
}
```

---

## 14. Use Functions

Terraform has a rich set of built-in functions to transform and manipulate data without external scripting.

**Why it matters:**
- Keeps logic inside Terraform — no shell scripts
- Reduces boilerplate through data transformation
- Makes configurations self-documenting

```hcl
locals {
  # String functions
  env_upper   = upper(var.environment)          # "PROD"
  bucket_name = lower("MyApp-Logs")             # "myapp-logs"
  trimmed     = trimspace("  hello  ")          # "hello"

  # Collection functions
  all_azs     = ["us-east-1a", "us-east-1b", "us-east-1c"]
  first_two   = slice(local.all_azs, 0, 2)      # first 2 AZs

  # Map merging
  base_tags   = { Env = "prod", Team = "platform" }
  extra_tags  = { App = "myapp" }
  all_tags    = merge(local.base_tags, local.extra_tags)

  # Encoding
  user_data_b64 = base64encode(file("${path.module}/scripts/user_data.sh"))

  # Conditionals and lookups
  instance_size = lookup(var.instance_sizes, var.environment, "t3.micro")

  # Type conversion
  port_list = tolist([80, 443, 8080])

  # Flatten nested lists
  all_cidrs = flatten([
    var.private_cidrs,
    var.public_cidrs
  ])

  # Format strings
  log_group = format("/aws/lambda/%s-%s", var.app_name, var.environment)
}

# cidrsubnet — calculate subnets dynamically
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = local.all_azs[count.index]
  # Generates: 10.0.0.0/24, 10.0.1.0/24, 10.0.2.0/24
}
```

---

## 15. Take Advantage of Dynamic Blocks

`dynamic` blocks let you generate repeated nested blocks programmatically, keeping configs concise.

**Why it matters:**
- Replaces copy-pasted nested blocks
- Makes rule sets and policies data-driven
- Cleaner diffs when adding/removing rules

```hcl
# Without dynamic — repetitive and hard to maintain
resource "aws_security_group" "web_bad" {
  name = "web-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
}

# ✅ With dynamic — data-driven and scalable
variable "ingress_rules" {
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    { port = 80,   protocol = "tcp", cidr_blocks = ["0.0.0.0/0"],  description = "HTTP" },
    { port = 443,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"],  description = "HTTPS" },
    { port = 8080, protocol = "tcp", cidr_blocks = ["10.0.0.0/8"], description = "Internal API" },
  ]
}

resource "aws_security_group" "web" {
  name        = "${local.prefix}-web-sg"
  description = "Web tier security group"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

---

## 16. Use Terraform Workspaces

Workspaces allow you to manage multiple environments from a single Terraform configuration with isolated state files.

**Why it matters:**
- Single codebase for dev/staging/prod
- State isolation between environments
- Environment-specific values without duplicating code

```hcl
# Use workspace name to drive environment-specific values
locals {
  env = terraform.workspace  # "dev", "staging", "prod"

  instance_type = {
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "t3.large"
  }

  min_capacity = {
    dev     = 1
    staging = 2
    prod    = 5
  }
}

resource "aws_autoscaling_group" "web" {
  min_size = local.min_capacity[local.env]
  max_size = local.min_capacity[local.env] * 2

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Environment"
    value               = local.env
    propagate_at_launch = true
  }
}
```

```bash
# Workspace commands
terraform workspace new staging         # Create workspace
terraform workspace select prod         # Switch workspace
terraform workspace list                # List all workspaces
terraform workspace show                # Show current workspace

# Apply to a specific workspace
terraform workspace select prod && terraform apply
```

> ⚠️ **Note:** Workspaces share the same backend bucket — use separate backends (or separate directories) for true isolation in highly regulated environments.

---

## 17. Use the Lifecycle Block

Control how Terraform handles resource creation, updates, and deletion with `lifecycle` meta-arguments.

**Why it matters:**
- Prevent accidental deletion of critical resources
- Allow blue/green deployments without downtime
- Ignore noisy attribute changes managed outside Terraform

```hcl
# create_before_destroy — zero-downtime replacement
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type

  lifecycle {
    create_before_destroy = true
  }
}

# prevent_destroy — protect stateful/critical resources
resource "aws_db_instance" "main" {
  identifier     = "prod-postgres"
  engine         = "postgres"
  instance_class = "db.r6g.large"

  lifecycle {
    prevent_destroy = true
  }
}

# ignore_changes — don't overwrite changes made outside Terraform
resource "aws_instance" "managed_externally" {
  ami           = var.ami_id
  instance_type = var.instance_type

  lifecycle {
    ignore_changes = [
      ami,           # AMI is managed by Packer pipeline
      user_data,     # User data is managed by config management
      tags["LastDeployed"],  # Updated by deployment pipeline
    ]
  }
}

# replace_triggered_by — force replacement on dependency change
resource "aws_instance" "web_v2" {
  ami           = var.ami_id
  instance_type = var.instance_type

  lifecycle {
    replace_triggered_by = [
      aws_launch_template.web.latest_version  # Replace when template changes
    ]
  }
}
```

---

## 18. Use Variable Validations

Add `validation` blocks to variables to fail fast with clear error messages rather than obscure provider errors.

**Why it matters:**
- Catch invalid inputs before API calls are made
- Self-documenting constraints
- Better developer experience with actionable errors

```hcl
variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string

  validation {
    condition     = can(regex("^t3\\.", var.instance_type))
    error_message = "instance_type must be a t3 family instance (e.g. t3.micro, t3.small)."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block (e.g. 10.0.0.0/16)."
  }
}

variable "retention_days" {
  description = "Log retention period in days"
  type        = number

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365], var.retention_days)
    error_message = "retention_days must be a valid CloudWatch log retention value."
  }
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)

  validation {
    condition     = contains(keys(var.tags), "Team")
    error_message = "tags must include a 'Team' key."
  }
}
```

---

## 19. Leverage Helper Tools

A thriving ecosystem of tools makes Terraform development faster, safer, and more consistent.

| Tool | Purpose | Install |
|------|---------|---------|
| [tflint](https://github.com/terraform-linters/tflint) | Linting & best practice checks | `brew install tflint` |
| [tfsec](https://github.com/aquasecurity/tfsec) | Security scanning | `brew install tfsec` |
| [checkov](https://www.checkov.io/) | Security & compliance scanning | `pip install checkov` |
| [infracost](https://www.infracost.io/) | Cost estimation before apply | `brew install infracost` |
| [tfswitch](https://tfswitch.warrensbox.com/) | Terraform version manager | `brew install warrensbox/tap/tfswitch` |
| [pre-commit](https://pre-commit.com/) | Git hooks for fmt/validate/lint | `brew install pre-commit` |
| [terragrunt](https://terragrunt.gruntwork.io/) | DRY wrapper for Terraform | `brew install terragrunt` |
| [atlantis](https://www.runatlantis.io/) | Pull request automation | Helm chart / Docker |

```bash
# tflint — catch common mistakes and deprecated syntax
tflint --init
tflint --recursive

# tfsec — static security analysis
tfsec .
tfsec . --soft-fail  # Don't fail on warnings

# infracost — see the cost impact of changes in CI
infracost breakdown --path .
infracost diff --path . --compare-to baseline.json

# pre-commit — automate checks on every commit
# .pre-commit-config.yaml
```

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.92.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_tfsec
      - id: infracost_breakdown
        args:
          - --args=--path=.
```

```bash
# Install and run pre-commit hooks
pre-commit install
pre-commit run --all-files
```

---

## 20. Take Advantage of IDE Extensions

The right editor setup dramatically improves productivity with autocompletion, inline docs, and real-time validation.

### VS Code

| Extension | Publisher | What it does |
|-----------|-----------|-------------|
| **HashiCorp Terraform** | HashiCorp | Syntax highlighting, autocompletion, hover docs, go-to-definition |
| **Terraform Lens** | 4ops | Enhanced resource navigation |
| **GitLens** | GitKraken | Inline blame & history for `.tf` files |
| **Error Lens** | Alexander | Inline error highlighting |

```json
// .vscode/settings.json — recommended project settings
{
  "[terraform]": {
    "editor.defaultFormatter": "hashicorp.terraform",
    "editor.formatOnSave": true,
    "editor.tabSize": 2
  },
  "[terraform-vars]": {
    "editor.defaultFormatter": "hashicorp.terraform",
    "editor.formatOnSave": true
  },
  "terraform.languageServer.enable": true,
  "terraform.languageServer.args": ["serve"],
  "terraform.codelens.referenceCount": true
}
```

### JetBrains IDEs (IntelliJ, GoLand, PyCharm)

- **HashiCorp Terraform** plugin — available in JetBrains Marketplace
- Provides full language support, variable resolution, and resource navigation

### Vim / Neovim

```vim
" Install via vim-plug or lazy.nvim
Plug 'hashivim/vim-terraform'         " Syntax + fmt on save
Plug 'nvim-treesitter/nvim-treesitter' " Better syntax parsing

" .vimrc
let g:terraform_fmt_on_save = 1
let g:terraform_align = 1
```

### Useful Snippets

Most Terraform extensions support custom snippets. Example for VS Code:

```json
// .vscode/terraform.code-snippets
{
  "Terraform Resource": {
    "prefix": "res",
    "body": [
      "resource \"${1:type}\" \"${2:name}\" {",
      "  ${3}",
      "}",
      ""
    ],
    "description": "Terraform resource block"
  },
  "Terraform Variable": {
    "prefix": "var",
    "body": [
      "variable \"${1:name}\" {",
      "  description = \"${2:description}\"",
      "  type        = ${3:string}",
      "  default     = ${4:null}",
      "}",
      ""
    ],
    "description": "Terraform variable block"
  }
}
```

---

## Quick Reference Cheatsheet

```bash
# Initialise                    terraform init
# Format                        terraform fmt -recursive
# Validate                      terraform validate
# Plan                          terraform plan -out=tfplan
# Apply                         terraform apply tfplan
# Destroy                       terraform destroy
# Show state                    terraform show
# List resources                terraform state list
# Import resource               terraform import <address> <id>
# Taint resource (force replace) terraform taint <resource>
# Workspace                     terraform workspace select <name>
# Debug                         TF_LOG=DEBUG terraform apply
```

---

## Contributing

Found an issue or want to add a new best practice? Open a PR! Please include:
- A clear explanation of the practice
- A working Terraform code example
- Notes on when to apply (and when not to)

---
COURTESY : https://www.terraform-best-practices.com/

*Maintained with ❤️ — PRs welcome*
