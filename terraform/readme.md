## Terraform Workflow

### Initialize Terraform

**Setup Dev environment (vpc & bucket)**
```bash
cd bootstrap
terraform init -backend-config=./backends/dev.config  
```
**Setup Prod environment (vpc & bucket)**
```bash
cd bootstrap
terraform init -backend-config=./backends/prd.config  
```
**Cluster Dev environment**
```bash
cd cluster
terraform init -var-file=dev.tfvars
```
**Cluster Prod environment**
```bash
cd cluster
terraform init -var-file=prd.tfvars
```
**IAM Settings Dev environment**
```bash
cd iam 
terraform init -backend-config=./backends/dev.config  
```
**IAM Settings Prod environment**
```bash
cd iam 
terraform init -backend-config=./backends/prd.config  
```
**Managed DB Instance Dev environment**
```bash
cd db 
terraform init -var-file=dev.tfvars
```
**Managed DB Instance Prod environment**
```bash
cd db 
terraform init -var-file=prd.tfvars
```

### Plan Changes

**Setup Dev environment (vpc & bucket)**
```bash
cd bootstrap
terraform plan -var-file=dev.tfvars  
```
**Setup Prod environment (vpc & bucket)**
```bash
cd bootstrap
terraform plan -var-file=prd.tfvars
```
**Cluster Dev environment**
```bash
cd cluster
terraform plan -var-file=dev.tfvars
```
**Cluster Prod environment**
```bash
cd cluster
terraform plan -var-file=prd.tfvars
```
**IAM Settings Dev environment**
```bash
cd iam 
terraform plan -var-file=dev.tfvars  
```
**IAM Settings Prod environment**
```bash
cd iam 
terraform plan -var-file=prd.tfvars
```
**Managed DB Instance Dev environment**
```bash
cd db 
terraform plan -var-file=dev.tfvars
```
**Managed DB Instance Prod environment**
```bash
cd db 
terraform plan -var-file=prd.tfvars
```

### Apply Changes

**Setup Dev environment (vpc & bucket)**
```bash
cd bootstrap
terraform apply -var-file=dev.tfvars  
```
**Setup Prod environment (vpc & bucket)**
```bash
cd bootstrap
terraform apply -var-file=prd.tfvars  
```
**Cluster Dev environment**
```bash
cd cluster
terraform apply -var-file=dev.tfvars
```
**Cluster Prod environment**
```bash
cd cluster
terraform apply -var-file=prd.tfvars
```
**IAM Settings Dev environment**
```bash
cd iam 
terraform apply -var-file=dev.tfvars  
```
**IAM Settings Prod environment**
```bash
cd iam 
terraform apply -var-file=prd.tfvars
```
**Managed DB Instance Dev environment**
```bash
cd db 
terraform apply -var-file=dev.tfvars
```
**Managed DB Instance Prod environment**
```bash
cd db 
terraform apply -var-file=prd.tfvars
```

### Destroy Infrastructure

**Setup Dev environment (vpc & bucket)**
```bash
cd bootstrap
terraform destroy -var-file=dev.tfvars
```
**Setup Prod environment (vpc & bucket)**
```bash
cd bootstrap
terraform destroy -var-file=prd.tfvars
```
**Cluster Dev environment**
```bash
cd cluster
terraform destroy -var-file=dev.tfvars
```
**Cluster Prod environment**
```bash
cd cluster
terraform destroy -var-file=prd.tfvars
```
**IAM Settings Dev environment**
```bash
cd iam 
terraform destroy -var-file=dev.tfvars  
```
**IAM Settings Prod environment**
```bash
cd iam 
terraform destroy -var-file=prd.tfvars
```
**Managed DB Instance Dev environment**
```bash
cd db 
terraform destroy -var-file=dev.tfvars  
```
**Managed DB Instance Prod environment**
```bash
cd db 
terraform destroy -var-file=prd.tfvars
```
