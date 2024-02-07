# Fullstack AWS Terraform CI/CD Template
Frontend and Backend services on ECS Fargate, Load Balancers, Private Postgres RDS Instance with Bastion EC2 Instance, and CI/CD with Terraform Cloud and GitHub Actions

# Instructions

### Adapting for your Project
After copying the infra/ directory to your project, update the following:
1. 'project-id' in infra/variable.tf
2. 'awslog-group' in infra/task-definitions/service.latest.json and backend-service.latest.json
3. 'organization' and 'workspace' in terraform section of main.tf

### Deploy the Infrastructure
```
cd infra
terraform init
terraform plan
terraform apply
```

### Deploy the App
To deploy the app, commit or merge to main to kick off the actions workflow

# OUTSTANDING:
    - Secret Rotation: GitHub can't do this. So we need to use AWS secrets.
        - Solution: Use GitHub Actions "Schedule" trigger to trigger lambda to change creds, retreive new creds, and deploy new images



# In Docker, use Secrets, NOT ENV Vars
https://docs.docker.com/compose/environment-variables/set-environment-variables/#:~:text=Don't%20use%20environment%20variables,Use%20secrets%20instead.

# DB SECURITY
TODO: Create NON-ROOT DB users to do different DB tasks

# TODO
1. Use AWS Secrets Manager to store DB creds. Then pull creds from AWS Secrets Manager during GitHub Actions build. https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieving-secrets_github.html
2. Allow AWS to "manage_master_user_password" for RDS instance. We should have multiple DB users for different tasks. https://aws.amazon.com/blogs/database/managing-postgresql-users-a
nd-roles/



# Dyanmically set ENV Vars in GitHub Actions from Terraform Output
First, you must migrate your terraform state to Terraform Cloud: https://developer.hashicorp.com/terraform/tutorials/cloud/cloud-migrate
Set your AWS Secrets in Terraform Cloud, and set your Terraform API Key as a GitHub Secret: https://betterprogramming.pub/github-actions-in-action-with-terraform-cloud-bfd7b5be666c

1. Set the Terraform API token in GitHub secrets. This will allow us to retrieve Terraform outputs dynamically.

# Running Locally
1. Run 'docker-compose build && docker-compose up' 
2. If the frontend, backend, and DB are properly networked, you should be able to navigate to localhost:3000 and see "Hello from the backend!" as well as a "Mock Data:" section with 3 items, which was retrieved by the backend from the DB
