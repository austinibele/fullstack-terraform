# TODO
1. Allow AWS to "manage_master_user_password" for RDS instance. We should have multiple DB users for different tasks. https://aws.amazon.com/blogs/database/managing-postgresql-users-and-roles/


# Keep Secrets in separate tfvars file 
1. This file should not be commited to github
2. It is better use a encrypted secrets manager

```
cd infra
mv example.secrets.tfvars secrets.tfvars
terraform plan -var-file="secrets.tfvars"
terraform apply --auto-approve -var-file="secrets.tfvars"
```

# Terraform

1. Set the Terraform API token in GitHub secrets. This will allow us to retrieve Terraform outputs dynamically.

# Running Locally
1. Run 'docker-compose build && docker-compose up' 
2. If the frontend, backend, and DB are properly networked, you should be able to navigate to localhost:3000 and see "Hello from the backend!" as well as a "Mock Data:" section with 3 items, which was retrieved by the backend from the DB
