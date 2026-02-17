# Advanced Resource Configuration with Terraform
## One-Day Training Session - Azure Container Apps

**Duration:** 8 Hours (9:00 AM - 5:00 PM)  
**Target Audience:** DevOps Engineers, Cloud Architects, Infrastructure Engineers  
**Prerequisites:** Basic Terraform knowledge, Azure fundamentals, Container concepts

---

## Training Agenda

| Time | Session | Duration |
|------|---------|----------|
| 9:00 - 10:30 | Session 1: Advanced Terraform Fundamentals & State Management | 90 min |
| 10:30 - 10:45 | Break | 15 min |
| 10:45 - 12:15 | Session 2: Advanced Resource Dependencies & Dynamic Configurations | 90 min |
| 12:15 - 1:15 | Lunch Break | 60 min |
| 1:15 - 2:45 | Session 3: Modularization & Reusable Components | 90 min |
| 2:45 - 3:00 | Break | 15 min |
| 3:00 - 4:30 | Session 4: Advanced Security & Compliance Patterns | 90 min |
| 4:30 - 5:00 | Session 5: Production Best Practices & Troubleshooting | 30 min |

---

## Session 1: Advanced Terraform Fundamentals & State Management
**Duration:** 90 minutes

### Learning Objectives
- Master remote state management with Azure Storage
- Understand state locking mechanisms
- Implement workspace strategies for multi-environment deployments
- Configure backend settings for team collaboration

### Key Concepts

#### 1.1 Remote State Configuration
Remote state enables team collaboration and prevents concurrent modifications. Azure Blob Storage provides a reliable backend for Terraform state.

**Key Points:**
- State files contain sensitive information and should be secured
- Backend configuration enables state locking to prevent conflicts
- Partial backend configuration allows for environment-specific settings
- State encryption at rest is crucial for security

#### 1.2 State Locking
State locking prevents multiple users from modifying infrastructure simultaneously, avoiding race conditions and state corruption.

**Key Points:**
- Azure Blob Storage uses native blob leases for locking
- Lock timeout should be configured appropriately
- Failed locks should trigger clear error messages
- Manual unlock may be needed in exceptional cases

#### 1.3 Workspaces
Workspaces allow managing multiple environments (dev, staging, prod) from a single configuration.

**Key Points:**
- Each workspace maintains separate state
- Workspace names can be used in resource naming
- Default workspace should be avoided in production
- Workspace strategy should align with deployment pipeline

### Lab 1.1: Setting Up Remote State with Azure Storage

**Objective:** Configure Azure Blob Storage as remote backend for Terraform state management.

**Steps:**
1. Create Azure Storage Account for state management
2. Configure backend with state locking
3. Initialize Terraform with remote backend
4. Verify state storage and locking mechanism

### Lab 1.2: Multi-Environment Container Apps with Workspaces

**Objective:** Deploy Azure Container Apps to multiple environments using Terraform workspaces.

**Steps:**
1. Create workspace-aware configuration
2. Deploy to development workspace
3. Deploy to production workspace
4. Verify environment isolation

---

## Session 2: Advanced Resource Dependencies & Dynamic Configurations
**Duration:** 90 minutes

### Learning Objectives
- Master implicit and explicit dependencies
- Implement dynamic blocks for flexible configurations
- Use for_each and count for resource iteration
- Handle complex data transformations with functions

### Key Concepts

#### 2.1 Resource Dependencies
Understanding dependency management is crucial for proper resource provisioning order.

**Key Points:**
- Implicit dependencies through reference expressions
- Explicit dependencies using depends_on
- Dependency cycles and how to avoid them
- Create_before_destroy lifecycle rules

#### 2.2 Dynamic Blocks
Dynamic blocks enable generating nested configuration blocks programmatically.

**Key Points:**
- Iterate over collections to generate configuration
- Reduce code duplication
- Handle optional configuration blocks
- Access iterator values and keys

#### 2.3 Advanced Iteration Patterns
for_each and count enable creating multiple similar resources efficiently.

**Key Points:**
- for_each with maps provides better resource identification
- count is simpler but has limitations with reordering
- Conditional resource creation with count
- Converting between sets, lists, and maps

### Lab 2.1: Complex Container App with Dynamic Configuration

**Objective:** Create a Container App with dynamically generated secrets, environment variables, and volume mounts.

**Steps:**
1. Define variable structure for dynamic configuration
2. Implement dynamic blocks for secrets and env vars
3. Add dynamic volume mounts
4. Deploy and verify configuration

### Lab 2.2: Multi-Container Apps with for_each

**Objective:** Deploy multiple Container Apps with different configurations using for_each.

**Steps:**
1. Define map of container app configurations
2. Use for_each to create multiple apps
3. Implement shared and unique configurations
4. Verify all deployments

---

## Session 3: Modularization & Reusable Components
**Duration:** 90 minutes

### Learning Objectives
- Design reusable Terraform modules
- Implement input validation and output values
- Create module composition patterns
- Publish and version modules

### Key Concepts

#### 3.1 Module Design Principles
Well-designed modules promote reusability and maintainability.

**Key Points:**
- Single responsibility principle
- Clear input and output contracts
- Sensible defaults with override capability
- Documentation and examples

#### 3.2 Input Validation
Validate inputs to catch errors early and provide clear feedback.

**Key Points:**
- Variable validation blocks
- Type constraints and custom types
- Conditional validation rules
- Error message best practices

#### 3.3 Module Composition
Combine multiple modules to build complex infrastructure.

**Key Points:**
- Pass outputs as inputs between modules
- Shared data sources
- Module versioning strategies
- Dependency management between modules

### Lab 3.1: Creating a Container App Module

**Objective:** Build a reusable module for Azure Container Apps with validation and outputs.

**Steps:**
1. Structure module directory
2. Define variables with validation
3. Implement core resources
4. Create comprehensive outputs
5. Add README documentation

### Lab 3.2: Module Composition - Full Application Stack

**Objective:** Compose multiple modules to deploy a complete application infrastructure.

**Steps:**
1. Create networking module
2. Create Log Analytics module
3. Integrate Container App module
4. Deploy complete stack
5. Verify inter-module dependencies

---

## Session 4: Advanced Security & Compliance Patterns
**Duration:** 90 minutes

### Learning Objectives
- Implement secure secret management
- Configure network isolation and private endpoints
- Apply managed identity and RBAC
- Implement compliance and governance policies

### Key Concepts

#### 4.1 Secret Management
Never store secrets in code or state files unencrypted.

**Key Points:**
- Azure Key Vault integration
- Secret rotation strategies
- Least privilege access
- Audit logging for secret access

#### 4.2 Network Security
Isolate container apps using virtual networks and private endpoints.

**Key Points:**
- Virtual Network integration
- Private DNS zones
- Network Security Groups
- Application Gateway integration

#### 4.3 Identity and Access Management
Use managed identities to eliminate credential management.

**Key Points:**
- System-assigned vs user-assigned identities
- RBAC role assignments
- Service principal alternatives
- Azure AD integration

### Lab 4.1: Secure Container App with Key Vault Integration

**Objective:** Deploy Container App with secrets stored in Azure Key Vault and managed identity.

**Steps:**
1. Create Key Vault with secrets
2. Configure managed identity
3. Grant Key Vault access
4. Reference secrets in Container App
5. Verify secure secret retrieval

### Lab 4.2: Network-Isolated Container App

**Objective:** Deploy Container App in a virtual network with private endpoints.

**Steps:**
1. Create virtual network and subnets
2. Configure Container App Environment with VNet
3. Deploy Container App with internal ingress
4. Configure Private DNS
5. Test connectivity

---

## Session 5: Production Best Practices & Troubleshooting
**Duration:** 30 minutes

### Learning Objectives
- Implement CI/CD pipeline integration
- Understand drift detection and remediation
- Apply disaster recovery strategies
- Master troubleshooting techniques

### Key Concepts

#### 5.1 CI/CD Integration
Automate Terraform workflows in deployment pipelines.

**Key Points:**
- terraform plan in pull requests
- terraform apply with approvals
- State management in pipelines
- Automated testing and validation

#### 5.2 Drift Detection
Identify and handle infrastructure drift.

**Key Points:**
- Regular terraform plan execution
- Automated drift detection
- Import existing resources
- Manual change prevention

#### 5.3 Disaster Recovery
Prepare for state loss and infrastructure failures.

**Key Points:**
- State backup strategies
- Import existing infrastructure
- Recreating from configuration
- Multi-region deployments

### Best Practices Checklist
- ✅ Use remote state with locking
- ✅ Never commit secrets or sensitive data
- ✅ Implement proper tagging strategy
- ✅ Use modules for reusability
- ✅ Version control all Terraform code
- ✅ Peer review all changes
- ✅ Test in non-prod first
- ✅ Document architectural decisions
- ✅ Monitor state file size
- ✅ Regular security audits

---

## Training Resources

### Required Tools
- Terraform >= 1.5.0
- Azure CLI >= 2.50.0
- Azure Subscription with Contributor access
- Git for version control
- VS Code with Terraform extension (recommended)

### Additional Reading
- Terraform Azure Provider Documentation
- Azure Container Apps Documentation
- HashiCorp Learn Platform
- Azure Architecture Center

### Support and Q&A
- Training Slack Channel: #terraform-training
- Office Hours: Daily 4:00 PM - 5:00 PM
- Email Support: devops-training@company.com

---

## Assessment and Certification

### Knowledge Check
- Quiz after each session (5 questions)
- Hands-on lab completion (all 8 labs)
- Final project: Deploy production-ready Container App infrastructure

### Certification Requirements
- 80% score on all quizzes
- Complete all lab exercises
- Submit final project
- Demonstrate troubleshooting skills

---

**Training Version:** 1.0  
**Last Updated:** February 2026  
**Instructor:** DevOps Training Team
