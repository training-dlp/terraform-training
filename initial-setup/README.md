# Initial Setup - Azure Container App with Python

This is the baseline infrastructure that will be used throughout the workshop.

## What's Deployed

- Azure Resource Group
- Azure Container Registry (ACR)
- Azure Container App Environment
- Azure Container App (running Python web app)
- Application Insights for monitoring

## Python Application

A simple Flask web application displaying workshop information.

## Deployment Steps

### 1. Update Variables

Edit `terraform.tfvars`:

```hcl
project_name = "tfworkshop"
location     = "eastus"
environment  = "initial"
```

### 2. Initialize and Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 3. Access the Application

After deployment, Terraform will output the application URL:

```bash
terraform output app_url
```

Visit the URL to see your Python application running!

## Architecture

```
┌─────────────────────────────────────┐
│  Azure Container Registry (ACR)     │
│  - Stores Docker images              │
└─────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│  Container App Environment          │
│  ┌───────────────────────────────┐  │
│  │  Container App                │  │
│  │  - Python Flask App           │  │
│  │  - Auto-scaling enabled       │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│  Application Insights               │
│  - Monitoring & Logging              │
└─────────────────────────────────────┘
```

## Files Overview

- `main.tf` - Main infrastructure configuration
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `terraform.tfvars` - Variable values
- `app/` - Python Flask application
- `Dockerfile` - Container image definition

## Next Steps

After completing this initial setup, proceed to:
- **Day 1**: Learn about state management
