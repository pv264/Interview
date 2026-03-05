## What was the last Terraform issue you fixed?

**Answer:**
During a **Terraform** deployment, **`terraform apply`** started showing that it would **recreate** an **EC2 instance** even though we had not changed anything related to the instance.

### Problem Identification:
I reviewed the **`terraform plan`** output carefully and noticed that the **AMI ID** had changed because it was being fetched using a **data source** for the latest **AMI**.

```hcl
data "aws_ami" "latest" {
  most_recent = true
}
Whenever a new AMI was released, Terraform detected it as a change and tried to replace the EC2 instance.

Root Cause:
The root cause was using dynamic AMI lookup with most_recent = true, which caused Terraform to detect changes and plan instance replacement.

Resolution:
We pinned the AMI ID explicitly or

Used lifecycle rules:

Terraform
lifecycle {
  ignore_changes = [ami]
}
