# Advanced Resource Configuration with Terraform
## Azure Container Apps - Complete Training Package

This comprehensive training package provides a full-day workshop on advanced Terraform techniques using Azure Container Apps as the practical example.

## 📦 Package Contents

```
terraform-training/
├── documentation/
│   ├── advanced-terraform-training.md    # Main training curriculum
│   └── LAB-GUIDE.md                      # Detailed lab instructions
├── labs/
│   ├── lab1.1-remote-state-setup.tf      # Remote state configuration
│   ├── lab1.2-workspaces.tf              # Multi-environment workspaces
│   ├── lab2.1-dynamic-configuration.tf   # Dynamic blocks
│   ├── lab2.2-foreach-iteration.tf       # for_each patterns
│   ├── lab3.1-module-usage.tf            # Using modules
│   ├── lab3.2-module-composition.tf      # Module composition
│   ├── lab4.1-secure-keyvault.tf         # Security with Key Vault
│   └── lab4.2-network-isolation.tf       # Network isolation
└── modules/
    └── container-app/
        ├── README.md                     # Module documentation
        ├── main.tf                       # Main module code
        ├── variables.tf                  # Input variables
        └── outputs.tf                    # Output values

```

## 🎯 Training Overview

**Duration:** 8 hours (full day)  
**Level:** Advanced  
**Target Audience:** DevOps Engineers, Cloud Architects, Infrastructure Engineers

### What You'll Learn

1. **Advanced Terraform Fundamentals**
   - Remote state management with Azure Storage
   - State locking mechanisms
   - Workspace strategies for multi-environment deployments

2. **Advanced Resource Dependencies**
   - Implicit and explicit dependencies
   - Dynamic blocks for flexible configurations
   - for_each and count patterns

3. **Modularization & Reusability**
   - Designing reusable modules
   - Input validation and outputs
   - Module composition patterns

4. **Security & Compliance**
   - Azure Key Vault integration
   - Managed Identity implementation
   - Network isolation with VNets
   - Private endpoints

5. **Production Best Practices**
   - CI/CD integration
   - Drift detection
   - Disaster recovery strategies

## 🚀 Getting Started

### Prerequisites

**Required:**
- Azure Subscription with Contributor access
- Azure CLI (version 2.50+)
- Terraform (version 1.5+)
- Basic Terraform knowledge
- Understanding of container concepts

**Recommended:**
- VS Code with Terraform extension
- Git for version control
- 4+ GB RAM on your machine

### Quick Start

1. **Install Required Tools**

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
unzip terraform_1.7.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify
az --version
terraform --version
```

2. **Login to Azure**

```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

3. **Set Up Workspace**

```bash
# Create working directory
mkdir ~/terraform-labs
cd ~/terraform-labs

# Copy training materials
cp -r /path/to/terraform-training/* .
```

4. **Start with Documentation**

```bash
# Read the main training document
cat documentation/advanced-terraform-training.md

# Follow the detailed lab guide
cat documentation/LAB-GUIDE.md
```

## 📚 Training Sessions

### Session 1: Terraform Fundamentals (90 min)
- Lab 1.1: Remote State Configuration
- Lab 1.2: Multi-Environment Workspaces

### Session 2: Advanced Configurations (90 min)
- Lab 2.1: Dynamic Configuration
- Lab 2.2: for_each Iteration

### Session 3: Modularization (90 min)
- Lab 3.1: Creating Reusable Modules
- Lab 3.2: Module Composition

### Session 4: Security Patterns (90 min)
- Lab 4.1: Secure Container App with Key Vault
- Lab 4.2: Network-Isolated Container App

### Session 5: Best Practices (30 min)
- CI/CD Integration
- Troubleshooting
- Production Considerations

## 🔬 Lab Structure

Each lab includes:
- **Learning objectives** - What you'll accomplish
- **Key concepts** - Theory and best practices
- **Terraform code** - Complete, working examples
- **Step-by-step instructions** - Detailed guidance
- **Verification steps** - How to confirm success
- **Expected results** - What to look for
- **Cleanup instructions** - Resource teardown

## 💡 Key Features

- ✅ **Real-world examples** - Production-ready code
- ✅ **Input validation** - Error prevention patterns
- ✅ **Comprehensive outputs** - Useful information extraction
- ✅ **Security focused** - Best practices embedded
- ✅ **Well documented** - Clear explanations throughout
- ✅ **Modular design** - Reusable components
- ✅ **Complete labs** - Nothing left out

## 🛠️ Technical Details

### Azure Resources Used

- Container Apps and Environments
- Virtual Networks and Subnets
- Network Security Groups
- Azure Key Vault
- Log Analytics Workspaces
- Application Insights
- Storage Accounts
- Private Endpoints
- Private DNS Zones
- Managed Identities
- RBAC Role Assignments

### Terraform Features Covered

- Remote state backends
- State locking
- Workspaces
- Dynamic blocks
- for_each and count
- Module creation
- Module composition
- Input validation
- Complex data types
- Lifecycle rules
- Dependencies
- Outputs and locals

## 📋 Lab Completion Checklist

Track your progress:

- [ ] Lab 1.1: Remote State Configuration
- [ ] Lab 1.2: Multi-Environment Workspaces
- [ ] Lab 2.1: Dynamic Configuration
- [ ] Lab 2.2: for_each Iteration
- [ ] Lab 3.1: Reusable Module Creation
- [ ] Lab 3.2: Module Composition
- [ ] Lab 4.1: Key Vault Integration
- [ ] Lab 4.2: Network Isolation

## 💰 Cost Considerations

### Estimated Costs

Running all labs simultaneously:
- Container Apps: ~$10-15/day
- Log Analytics: ~$2-3/day
- Storage: ~$0.50/day
- Network: ~$1/day
- Key Vault: Minimal
- **Total: ~$15-20/day**

### Cost Management Tips

1. **Complete labs sequentially** and destroy resources after each
2. **Use the smallest SKUs** for learning
3. **Set Azure budgets** and alerts
4. **Cleanup immediately** after training
5. **Use free tier services** where available

### Cleanup Commands

```bash
# Destroy lab resources
terraform destroy -auto-approve

# Verify all resources deleted
az resource list --resource-group RG_NAME

# Delete resource group if needed
az group delete --name RG_NAME --yes
```

## 🐛 Troubleshooting

Common issues and solutions are documented in:
- `documentation/LAB-GUIDE.md` - See "Troubleshooting Guide" section
- Each lab file - Includes specific troubleshooting notes

### Quick Fixes

**State Lock Issue:**
```bash
terraform force-unlock LOCK_ID
```

**Module Not Found:**
```bash
terraform init
terraform get -update
```

**RBAC Propagation:**
```bash
# Wait 60-90 seconds after role assignments
```

## 📖 Additional Resources

### Documentation
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Container Apps Docs](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

### Community
- [HashiCorp Discuss](https://discuss.hashicorp.com/)
- [Azure Tech Community](https://techcommunity.microsoft.com/)
- [Terraform Registry](https://registry.terraform.io/)

## 🤝 Support

For questions or issues with this training:

1. Check the LAB-GUIDE.md troubleshooting section
2. Review the module README.md files
3. Consult official Terraform and Azure documentation
4. Reach out to your training instructor

## 📝 Feedback

We'd love to hear your feedback! After completing the training:

- What worked well?
- What could be improved?
- What additional topics would you like covered?
- How well did the labs prepare you for real-world scenarios?

## 📜 License

This training material is provided for educational purposes.

## 🔄 Version History

- **v1.0** (February 2026) - Initial release
  - 8 comprehensive labs
  - Reusable module included
  - Complete documentation
  - Production-ready examples

## 👥 Credits

Developed by: DevOps Training Team  
Last Updated: February 16, 2026  
Terraform Version: 1.5+  
Azure Provider Version: 3.0+

---

**Ready to start?** Open `documentation/LAB-GUIDE.md` and begin with Lab 1.1!

**Questions?** Review the documentation or reach out to your instructor.

**Happy Learning! 🚀**
