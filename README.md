# Teraform
exercise

# GCP Skeleton App Infrastructure

This repository contains Terraform configurations to set up a complete skeleton application infrastructure on GCP with CI/CD pipelines.

## Project Structure
```
gcp-skeleton-app/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml
│       └── terraform-apply.yml
├── environments/
│   ├── dev/
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars.example
│   └── prod/
│       ├── backend.tf
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars.example
├── modules/
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── storage/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── scripts/
│   └── terraform-validate.sh
├── .gitignore
└── README.md
```
