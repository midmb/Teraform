# GCP using Teraform
exercise


## New CI/CD Configurations

### .github/workflows/terraform-plan.yml
```yaml
name: 'Terraform Plan'

on:
  pull_request:
    branches:
      - main
      - develop

jobs:
  terraform-plan:
    name: 'Terraform Plan'
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        environment: [dev, prod]
        
    defaults:
      run:
        working-directory: environments/${{ matrix.environment }}

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.0.0

    - name: Auth to GCP
      uses: google-github-actions/auth@v2
      with:
        credentials_json: ${{ secrets.GCP_SA_KEY }}

    - name: Terraform Init
      run: terraform init
      env:
        GOOGLE_CREDENTIALS: ${{ secrets.GCP_SA_KEY }}

    - name: Terraform Format
      run: terraform fmt -check

    - name: Terraform Validate
      run: terraform validate -no-color

    - name: Terraform Plan
      run: terraform plan -no-color
      env:
        GOOGLE_CREDENTIALS: ${{ secrets.GCP_SA_KEY }}
        TF_VAR_project_id: ${{ secrets.GCP_PROJECT_ID }}
```

### .github/workflows/terraform-apply.yml
```yaml
name: 'Terraform Apply'

on:
  push:
    branches:
      - main

jobs:
  terraform-apply:
    name: 'Terraform Apply'
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        environment: [dev, prod]
        
    defaults:
      run:
        working-directory: environments/${{ matrix.environment }}

    environment:
      name: ${{ matrix.environment }}
      
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.0.0

    - name: Auth to GCP
      uses: google-github-actions/auth@v2
      with:
        credentials_json: ${{ secrets.GCP_SA_KEY }}

    - name: Terraform Init
      run: terraform init
      env:
        GOOGLE_CREDENTIALS: ${{ secrets.GCP_SA_KEY }}

    - name: Terraform Apply
      run: terraform apply -auto-approve
      env:
        GOOGLE_CREDENTIALS: ${{ secrets.GCP_SA_KEY }}
        TF_VAR_project_id: ${{ secrets.GCP_PROJECT_ID }}
```

### scripts/terraform-validate.sh
```bash
#!/bin/bash

# This script runs terraform format and validate on all terraform directories

# Find all directories containing .tf files
TERRAFORM_DIRS=$(find . -type f -name "*.tf" -exec dirname {} \; | sort -u)

# Initialize error flag
ERROR=0

# Loop through each directory
for dir in $TERRAFORM_DIRS; do
  echo "Checking directory: $dir"
  
  # Change to directory
  cd "$dir" || exit 1
  
  # Run terraform fmt check
  echo "Running terraform fmt check..."
  if ! terraform fmt -check; then
    ERROR=1
    echo "❌ Terraform fmt check failed in $dir"
  fi
  
  # Run terraform validate
  echo "Running terraform validate..."
  if ! terraform validate; then
    ERROR=1
    echo "❌ Terraform validation failed in $dir"
  fi
  
  # Return to original directory
  cd - > /dev/null || exit 1
done

# Exit with error code if any checks failed
exit $ERROR
```

### Update backend.tf for Remote State
```hcl
# environments/dev/backend.tf
terraform {
  backend "gcs" {
    bucket = "terraform-state-dev-bucket"
    prefix = "terraform/state"
  }
}
```

## CI/CD Pipeline Features

1. **Pull Request Workflow**:
   - Runs on PR to main/develop
   - Performs format check
   - Validates configurations
   - Creates plan
   - Separate plans for dev/prod

2. **Apply Workflow**:
   - Runs on merge to main
   - Applies changes to infrastructure
   - Environment-specific deployments
   - Requires approval for prod

3. **Security Features**:
   - GCP Service Account authentication
   - Environment secrets
   - Protected environments

## GitHub Repository Setup

1. **Create Required Secrets**:
   - `GCP_SA_KEY`: Service account JSON key
   - `GCP_PROJECT_ID`: GCP project ID

2. **Configure Environment Protection Rules**:
   ```
   Settings -> Environments -> New environment
   - Name: prod
   - Configure protection rules
   - Required reviewers
   - Deployment branches: main
   ```

3. **Configure Branch Protection**:
   ```
   Settings -> Branches -> Add rule
   - Branch name pattern: main
   - Require pull request reviews
   - Require status checks to pass
   ```

## Usage Instructions

1. **For Feature Development**:
   ```bash
   git checkout -b feature/new-feature
   # Make changes
   git commit -m "Add new feature"
   git push origin feature/new-feature
   # Create PR to develop
   ```

2. **For Production Deployment**:
   ```bash
   # Create PR from develop to main
   # Wait for approval and merge
   # Automatic deployment will start
   ```

## Best Practices Implemented

1. **Environment Separation**:
   - Different workflows for plan/apply
   - Environment-specific configurations
   - Protected environments

2. **Security**:
   - Secrets management
   - Service account authentication
   - Required approvals

3. **Code Quality**:
   - Automated formatting checks
   - Validation before apply
   - Consistent state management

4. **Process**:
   - PR-driven changes
   - Automatic planning
   - Manual approval for prod

