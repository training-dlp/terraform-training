# Day 3: Custom Modules and Reusability

## Overview

Learn how to create reusable Terraform modules, implement best practices for module design, and manage module versions.

## Learning Objectives

- Create custom Terraform modules
- Implement module best practices
- Use input variables and outputs effectively
- Version and distribute modules
- Compose modules for complex architectures

## Module Structure

```
day-3-custom-modules/
├── modules/
│   ├── container-app/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── storage/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    ├── dev/
    └── prod/
```

## Exercises

### Exercise 1: Create Container App Module (30 minutes)

Create a reusable module for Azure Container Apps.

### Exercise 2: Use Module in Multiple Environments (20 minutes)

Deploy using the module in dev and prod.

### Exercise 3: Module Composition (20 minutes)

Combine multiple modules for a complete solution.

## Best Practices

1. **Single Responsibility**: One module, one purpose
2. **Clear Inputs/Outputs**: Well-documented variables
3. **Version Control**: Use semantic versioning
4. **README Documentation**: Usage examples
5. **Validation**: Input variable validation
6. **Defaults**: Sensible default values
7. **No Hard-coding**: Use variables for all values

## Next Steps

Proceed to **Day 4: Dynamic Logic and Validation**
