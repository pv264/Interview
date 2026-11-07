# Terraform Interview Questions and Answers

## Q1. How do you design and manage infrastructure using Terraform modules across multiple environments?

**Answer:**

I follow a modular approach in Terraform. I maintain separate reusable modules for VPC and EC2.

- **VPC module:** Handles VPC creation, public and private subnets, Internet Gateway, NAT Gateway and route tables.
- **EC2 module:** Handles EC2 instances, Security Groups and IAM instance profiles.

I maintain these reusable modules in a centralized `modules` directory and have separate environment directories for Dev, QA and Production.

Each environment calls the same VPC and EC2 modules but passes different input values through variables and `terraform.tfvars` files.

For example:
- Dev uses a `t3.micro` instance.
- QA uses a `t3.small` instance.
- Production uses a `t3.medium` instance.

For communication between modules, I use Terraform input variables and outputs. For example, the VPC module exports the VPC ID and private subnet IDs, which are passed to the EC2 module so that instances are launched in the appropriate subnets.

For state management, I use separate S3 remote state files for each environment, with state locking enabled. This ensures environment isolation and prevents concurrent state modifications.

This modular approach reduces code duplication, improves reusability and makes infrastructure easier to maintain across multiple environments.

---

## Q2. How do you authenticate Terraform with AWS when there is no CI/CD pipeline?

**Answer:**

If we don't have a CI/CD pipeline for infrastructure automation, developers can execute Terraform directly from their local machines.

First, we authenticate with AWS using our company's approved login mechanism.

After authentication, we use AWS IAM roles to access the required AWS accounts. For example, if we want to deploy infrastructure in the Dev account, we assume the Dev Terraform IAM role.

AWS STS (Security Token Service) then provides temporary credentials for that role. Terraform automatically uses these credentials through the AWS credential provider chain to communicate with AWS and perform infrastructure operations.

Similarly, if we have separate Dev, QA and Production AWS accounts, we maintain dedicated IAM roles for each environment and assume the appropriate role whenever we need to work in that account.

From a security perspective, we follow the principle of least privilege, restrict Production access and avoid storing permanent AWS access keys in Terraform configuration files.
