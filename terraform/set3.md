
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
