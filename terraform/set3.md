
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

## 4. What is `ignore_changes`?

**Answer:**
**`ignore_changes`** is a **lifecycle argument** used to tell **Terraform** to ignore updates to specific attributes. It is useful when certain values are managed outside **Terraform** or change dynamically, such as **Auto Scaling desired capacity**. This prevents **Terraform** from overriding those changes.



### Example Scenario:
In an **Auto Scaling Group**, we might set `desired_capacity = 2` in **Terraform**. However, during high traffic, **AWS** can automatically increase it to **4**.

* **Without `ignore_changes`:** **Terraform** will detect a drift (it sees 4 but wants 2) and will try to bring it back to **2** in the next run, potentially causing a performance bottleneck during high traffic.
* **With `ignore_changes`:** We tell **Terraform** to ignore this specific field so it does not override the changes made by the **Auto Scaling** policy.

> **Senior Signal:** Using **`ignore_changes`** is a critical best practice when your infrastructure interacts with external controllers or "intelligent" cloud services. Beyond Auto Scaling, it is frequently used for **tags** (if a security tool adds compliance tags automatically) or **Kubernetes** resources where external controllers might modify metadata or replicas.

# 5 .What is the purpose of terraform init?

`terraform init` initializes a Terraform working directory. It downloads required provider plugins, sets up the backend configuration, and prepares the environment to run Terraform commands.
