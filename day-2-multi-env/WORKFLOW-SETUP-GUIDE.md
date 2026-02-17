# GitHub Actions Multi-Environment Workflow Guide

## 📦 Files Provided

1. **multi-env-deploy.yml** - Full GitHub Actions workflow with Azure backend
2. **multi-env-hcp-terraform.yml** - Simplified workflow using HCP Terraform API

## 🚀 Setup Instructions

### Step 1: Add GitHub Secrets

Navigate to: **Repository Settings → Secrets and variables → Actions**

#### Required Secrets for Azure Backend (multi-env-deploy.yml)

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `ARM_CLIENT_ID` | Azure Service Principal ID | `12345678-1234-1234-1234-123456789012` |
| `ARM_CLIENT_SECRET` | Azure Service Principal Secret | `your-secret-value` |
| `ARM_SUBSCRIPTION_ID` | Azure Subscription ID | `87654321-4321-4321-4321-210987654321` |
| `ARM_TENANT_ID` | Azure Tenant ID | `11111111-1111-1111-1111-111111111111` |
| `STATE_RG_NAME` | State storage resource group | `rg-terraform-state` |
| `STATE_SA_NAME` | State storage account name | `tfstateworkshop12345` |

#### Required Secrets for HCP Terraform (multi-env-hcp-terraform.yml)

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `TF_API_TOKEN` | HCP Terraform API Token | User Settings → Tokens → Create API token |
| `TF_CLOUD_ORGANIZATION` | Your HCP Terraform org name | From HCP Terraform URL |

### Step 2: Create Workflow File

```bash
# Create workflows directory
mkdir -p .github/workflows

# Copy the workflow file
cp multi-env-deploy.yml .github/workflows/

# Or for HCP Terraform version
cp multi-env-hcp-terraform.yml .github/workflows/
```

### Step 3: Configure GitHub Environments (Optional but Recommended)

Create three GitHub environments for approval gates:

**Settings → Environments → New environment**

#### Environment: dev
```
Protection rules: None (auto-deploy)
Deployment branches: main
```

#### Environment: staging
```
Protection rules:
  ✅ Required reviewers (1 person)
  ✅ Wait timer: 0 minutes
Deployment branches: main
```

#### Environment: prod
```
Protection rules:
  ✅ Required reviewers (2 people)
  ✅ Wait timer: 5 minutes
  ✅ Restrict to protected branches
Deployment branches: main only
```

### Step 4: Commit and Push

```bash
git add .github/workflows/
git commit -m "Add multi-environment Terraform workflow"
git push origin main
```

---

## 🎯 Usage Examples

### Example 1: Manual Deployment to Dev

1. Go to **Actions** tab in GitHub
2. Select **"Multi-Environment Terraform Deployment"**
3. Click **"Run workflow"**
4. Select:
   - Environment: `dev`
   - Action: `apply`
   - Auto approve: `true`
5. Click **"Run workflow"**

**Result:** Deploys to dev automatically

### Example 2: Manual Deployment to Production

1. Go to **Actions** tab
2. Click **"Run workflow"**
3. Select:
   - Environment: `prod`
   - Action: `apply`
   - Auto approve: `false`
4. Click **"Run workflow"**

**Result:** 
- Creates plan for production
- Requires manual approval in GitHub (2 reviewers)
- After approval, applies changes

### Example 3: Automatic Deployment on Push

```bash
# Make a change to infrastructure
cd day-2-multi-env/dev
echo "# Update $(date)" >> main.tf

# Commit and push
git add .
git commit -m "Update infrastructure"
git push origin main
```

**Result:**
- Automatically deploys to dev (auto-approve)
- Automatically plans for staging (requires approval)
- Automatically plans for prod (requires approval)

**Sequential deployment:** Dev → Staging → Prod

### Example 4: Pull Request Preview

```bash
# Create a feature branch
git checkout -b feature/add-monitoring

# Make changes
cd day-2-multi-env/dev
# ... edit files ...

# Push and create PR
git push origin feature/add-monitoring
# Create PR on GitHub
```

**Result:**
- Workflow runs automatically
- Creates plan for dev
- Posts plan results as PR comment
- No apply happens (plan only)

### Example 5: Destroy Environment

1. Go to **Actions** tab
2. Click **"Run workflow"**
3. Select:
   - Environment: `dev`
   - Action: `destroy`
   - Auto approve: `true`
4. Click **"Run workflow"**

**Result:** Destroys dev environment resources

---

## 🔄 Workflow Behavior by Trigger

### Manual Trigger (workflow_dispatch)

| Input | Behavior |
|-------|----------|
| Environment: `dev` + Action: `plan` | Plans dev only |
| Environment: `staging` + Action: `apply` | Applies staging (requires approval) |
| Environment: `prod` + Action: `destroy` | Destroys prod (requires approval) |

### Push to Main

```
Automatically:
1. Deploys to dev (auto-approve)
2. Plans for staging (requires approval)
3. Plans for prod (requires approval)

Sequence: dev → staging → prod
```

### Pull Request

```
Automatically:
1. Plans dev environment only
2. Posts plan as PR comment
3. No apply happens
```

---

## 📊 Workflow Features

### ✅ What's Included

**Multi-Environment Support:**
- ✅ Dev, Staging, Production
- ✅ Environment-specific variables (dev.tfvars, staging.tfvars, prod.tfvars)
- ✅ Sequential deployment (max-parallel: 1)

**Safety Features:**
- ✅ GitHub environment protection rules
- ✅ Required approvals for staging/prod
- ✅ Manual approval gates
- ✅ Plan artifacts uploaded for review

**Automation:**
- ✅ Automatic deployment on push to main
- ✅ Plan on pull requests
- ✅ PR comments with plan results

**Flexibility:**
- ✅ Manual trigger with environment selection
- ✅ Plan, Apply, or Destroy actions
- ✅ Auto-approve option

**Observability:**
- ✅ Deployment summaries
- ✅ Job summaries with status
- ✅ Application URLs in outputs

---

## 🎨 Workflow Diagram

```
┌─────────────────────┐
│   Trigger Event     │
└──────────┬──────────┘
           │
           ├──► Manual (workflow_dispatch)
           │    └─► Selected environment only
           │
           ├──► Push to main
           │    └─► All environments (dev → staging → prod)
           │
           └──► Pull Request
                └─► Dev environment only (plan)
           
┌──────────▼──────────┐
│  Setup Job          │
│  - Determine envs   │
│  - Set action       │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│  Terraform Job      │
│  (Matrix Strategy)  │
└──────────┬──────────┘
           │
    ┌──────┴──────┬──────────┬──────────┐
    ▼             ▼          ▼          
┌───────┐    ┌─────────┐  ┌──────┐
│  Dev  │───▶│ Staging │─▶│ Prod │
│ Auto  │    │ Approve │  │ 2x   │
│ Apply │    │ Once    │  │Approve│
└───────┘    └─────────┘  └──────┘
    │             │          │
    └──────┬──────┴──────────┘
           ▼
    ┌─────────────┐
    │ Notify Job  │
    └─────────────┘
```

---

## 🔧 Customization Options

### Option 1: Change Environment Order

```yaml
# Deploy prod first, then staging, then dev (reverse order)
strategy:
  matrix:
    environment: ['prod', 'staging', 'dev']
```

### Option 2: Parallel Deployment

```yaml
# Deploy all environments simultaneously
strategy:
  max-parallel: 3  # or 0 for unlimited
```

### Option 3: Add More Environments

```yaml
# Add QA environment
workflow_dispatch:
  inputs:
    environment:
      options:
        - dev
        - qa      # New environment
        - staging
        - prod
```

### Option 4: Environment-Specific Auto-Approve

```yaml
# Auto-approve based on environment
- name: Set auto-approve
  run: |
    if [[ "${{ matrix.environment }}" == "dev" ]]; then
      echo "AUTO_APPROVE=true" >> $GITHUB_ENV
    else
      echo "AUTO_APPROVE=false" >> $GITHUB_ENV
    fi
```

### Option 5: Add Slack Notifications

```yaml
- name: Notify Slack
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "Deployed ${{ matrix.environment }}: ${{ job.status }}"
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

---

## 🐛 Troubleshooting

### Issue: "Resource not found" error

**Cause:** Backend state file doesn't exist

**Solution:**
```yaml
# Add to init step:
terraform init -reconfigure
```

### Issue: Plan artifacts not uploading

**Cause:** Path issues

**Solution:**
```yaml
# Use absolute paths
path: ${{ github.workspace }}/day-2-multi-env/${{ matrix.environment }}/tfplan
```

### Issue: Sequential deployment not working

**Cause:** max-parallel setting

**Solution:**
```yaml
strategy:
  max-parallel: 1  # Ensure this is set
```

### Issue: PR comments not appearing

**Cause:** Missing permissions

**Solution:**
```yaml
permissions:
  pull-requests: write  # Required for PR comments
```

---

## 📝 Best Practices

### 1. **Use GitHub Environments**
```
Provides:
- Required reviewers
- Deployment protection rules
- Deployment history
- Environment-specific secrets
```

### 2. **Tag Your Releases**
```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# Trigger workflow on tags
on:
  push:
    tags:
      - 'v*'
```

### 3. **Use Terraform Workspaces** (Alternative)
```yaml
- name: Select Workspace
  run: |
    terraform workspace select ${{ matrix.environment }} || \
    terraform workspace new ${{ matrix.environment }}
```

### 4. **Add Cost Estimation**
```yaml
- name: Terraform Cost Estimation
  uses: terraform-cost-estimation/action@v1
  with:
    terraform_plan_file: tfplan
```

### 5. **Security Scanning**
```yaml
- name: Run Checkov
  uses: bridgecrewio/checkov-action@master
  with:
    directory: day-2-multi-env/${{ matrix.environment }}
    framework: terraform
```

---

## 🎯 Quick Reference

### Trigger Manually
```
Actions → Multi-Environment Terraform Deployment → Run workflow
```

### View Run
```
Actions → Click on workflow run → View job details
```

### Approve Deployment
```
Actions → Pending deployment → Review deployments → Approve
```

### View Artifacts
```
Actions → Workflow run → Artifacts → Download plan
```

---

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform GitHub Actions](https://github.com/hashicorp/setup-terraform)
- [Azure Login Action](https://github.com/Azure/login)
- [Environment Protection Rules](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)

---

**Ready to use!** Just add the workflow file and configure your secrets. 🚀
