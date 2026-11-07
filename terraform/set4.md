I follow a modular approach in Terraform. For example, I maintain separate reusable modules for VPC and EC2.

The VPC module handles VPC creation, public and private subnets, Internet Gateway, NAT Gateway and route tables. The EC2 module handles EC2 instances, Security Groups and IAM instance profiles.

I maintain these modules in a centralized modules directory and have separate environment directories for Dev, QA and Production.

Each environment calls the same VPC and EC2 modules but passes different input values through variables and terraform.tfvars files. For example, Dev might use a t3.micro instance, QA a t3.small and Production a t3.medium.

For module communication, I use Terraform outputs and input variables. For example, the VPC module exports the VPC ID and private subnet IDs, which are passed to the EC2 module so that instances are launched in the correct subnets.

For state management, I use separate S3 remote state files for each environment with state locking enabled. This ensures environment isolation and prevents concurrent state modifications.

This approach avoids code duplication, improves reusability and makes infrastructure easier to maintain across environments.


If we don't have a CI/CD pipeline, we can execute Terraform directly from our local machines.

First, we authenticate with AWS using our company's approved login method.

After authentication, we use AWS IAM roles to access the required AWS accounts. For example, if we want to deploy infrastructure in the Dev account, we assume the Dev Terraform role.

AWS STS then provides temporary credentials for that role. Terraform automatically uses these credentials to connect to AWS and perform infrastructure operations.

Similarly, if we have separate Dev, QA and Production accounts, we maintain separate IAM roles for each environment and assume the appropriate role whenever we need to work in that account.

For security, we follow least-privilege access, restrict Production access and avoid using permanent AWS access keys.
