
## 1. Your Terraform state file got accidentally deleted. What will you do?

**Answer:**
If the **Terraform state file** is deleted, the infrastructure remains intact, but **Terraform** loses track of the resources. 

* The first step is to restore the state from a **remote backend** like **S3** with **versioning** enabled. 
* If that is not possible, we need to manually reconstruct the state by **importing resources**. 

 To avoid such issues, we always use **remote backends** with **versioning** and proper **backups**.

 ## 2. Terraform plan shows that it will destroy and recreate a production database (RDS). What will you do?

**Answer:**
If **Terraform** plans to recreate a production **RDS instance**, I would not apply it immediately. I would first analyze the plan to identify the attribute causing the replacement, especially checking for **immutable changes** or **drift**. 

Since this involves potential data loss, I would:
* **Revert the change** in the code if it was unintentional.
* Use **lifecycle rules** like **`ignore_changes`** if the change was managed outside of Terraform and is safe to ignore.
* Take **proper backups** (Snapshots) and plan a **controlled migration** if the change is absolutely necessary.



 Direct recreation in production must be avoided. In a real-world scenario, you should also look for the `forces replacement` note in the plan output to identify the specific field (like a DB identifier change or a storage type modification) that is triggering the destroy/create cycle. Using **`prevent_destroy = true`** in your lifecycle block is a proactive way to ensure this never happens by accident.

 ## 3.You ran `terraform apply`, but it failed in the middle. Some resources are created, some are not. What will you do?

**Answer:**
If **`terraform apply`** fails midway, I would first review the error output to identify the root cause. Since **Terraform** tracks successfully created resources in the **state**, I can fix the issue and then run **`terraform plan`** to confirm the expected changes. 

After that, I would re-run **`terraform apply`**, and due to **Terraform’s idempotent nature**, it will only create or update the remaining resources.

### Example Scenario:
If we provide an incorrect or non-existent **AMI ID** while creating an **EC2 instance**, **Terraform** will fail with an error like `InvalidAMIID.NotFound`.

In such cases, I would:
1.  Check the **error message**.
2.  Identify the **root cause**.
3.  **Fix the configuration** (e.g., provide the correct AMI ID).
4.  Re-run **`terraform apply`**.

> **Senior Signal:** A partial failure can sometimes lead to a "State Lock" issue if the process was interrupted abruptly. If the backend is **S3/DynamoDB**, you may need to manually release the lock using **`terraform force-unlock <LOCK_ID>`** before you can successfully re-run the apply. Furthermore, always check if any "orphaned" resources were created that didn't make it into the state—though rare, a **`terraform import`** might be necessary to bring them back under management.
