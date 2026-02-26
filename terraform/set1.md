## 1. What happens if two engineers run `terraform apply` at the same time?

**Answer:**
If we use a remote backend with state locking (like AWS S3 + DynamoDB), Terraform acquires a lock before modifying the state. 

* The first engineer successfully gets the lock.
* The second engineer receives an error:
  > `"Error acquiring the state lock"`

This mechanism strictly prevents concurrent modifications and state corruption. 
* **If locking is not enabled:** Both applies may proceed at the same time, leading to race conditions and a corrupted state file.
* **Best Practice:** In production, we *always* enable a remote backend with state locking.

---

## 2. How does Terraform state locking work with S3 + DynamoDB?

**Answer:**
When using an AWS S3 backend with DynamoDB, the underlying mechanism works like this:

1. **Storage:** The actual state file (`terraform.tfstate`) is stored in an Amazon S3 bucket.
2. **Lock Acquisition:** Before running a `plan` or `apply`, Terraform attempts to write a lock record in a specified DynamoDB table.
3. **Concurrency Control:** DynamoDB uses **conditional writes** to ensure that only one client can successfully acquire the lock at any given time.
4. **Lock Release:** After a successful `apply` (or if the run terminates), the lock record is automatically removed from DynamoDB.

This process guarantees atomic locking and prevents concurrent updates from overriding each other.

## 3. Risks of manually editing `.tfstate` and recovery?

**Answer:**
Manually editing the Terraform state file is highly discouraged and can cause severe issues:

* **Resource recreation:** Terraform might destroy and rebuild infrastructure unnecessarily because it lost track of the current state.
* **Orphaned resources:** Infrastructure exists in the cloud but is no longer managed or tracked by Terraform.
* **Dependency mismatch:** The logical relationships and references between resources get broken.
* **State corruption:** The JSON file becomes unreadable, halting all future deployments.

### Recovery Steps
If the state becomes corrupted due to manual edits (or other reasons), follow these steps:

1. **Restore Previous Version:** If using a remote backend (like S3) with versioning enabled, restore the last known good version of the `.tfstate` file.
2. **CLI State Manipulation:** If versioning isn't available, use `terraform state rm` to remove broken references and `terraform import` to remap the existing cloud resources back into the state file.
3. **Verify:** Re-run `terraform plan` to ensure the local state perfectly matches the real-world infrastructure without attempting unexpected changes.

> **Best Practice:** Avoid manual edits to the `.tfstate` file entirely. Always use dedicated CLI commands (like `terraform state mv`, `rm`, or `import`) to safely manipulate the state.

## 4. How do you design Terraform architecture for multiple environments?

**Answer:**
For **enterprise setup**:

* Use **reusable modules**.
* Maintain **separate state files** per environment.
* **Separate backend** per **env** (**dev**/**qa**/**prod**).
* Use **environment-specific variables**.
* Use **CI/CD** to control deployments.

### Example structure:

* **modules/**
* **environments/**
    * **dev/**
    * **qa/**
    * **prod/**

> **Senior Signal:** Each environment has its own **backend** and **state isolation**.

## 5. What is Terraform drift? How do you detect and prevent it?

**Answer:**
**Drift** occurs when infrastructure is modified outside **Terraform**.
**Example**: Someone edits **Security Group** manually.

### Detection:

1.  **`terraform plan`**
2.  **`terraform plan -refresh-only`**

### Prevention:

* Restrict **console access**
* Enforce **CI/CD-only applies**
* **IAM guardrails**
* Regular **drift detection pipelines**

> **Senior Signal:** Regular **drift detection pipelines** help ensure that the **State File** remains the single source of truth, preventing "silent" infrastructure changes from causing deployment failures.
## 6. Difference between count and for_each? Why is count risky?

**Answer:**
**count** creates resources using **numeric indexes**.
If one resource is removed in the middle, **indexes shift**, causing **resource recreation**.
**for_each** uses **stable keys**, preventing index shifting issues.
In **production**, we prefer **for_each** for stability.

---

## 7. How do you migrate from local to remote backend without downtime?

**Answer:**
1. Configure **remote backend** in code.
2. Run **`terraform init`**.
3. Confirm **state migration** when prompted.

**Terraform** uploads **local state** to **remote backend** without affecting infrastructure.
No downtime since only **state location** changes.

---

## 8. How do you refactor Terraform code without destroying infrastructure?

**Answer:**
Use:
* **`terraform state mv`**
* Or **`moved` block** (recommended approach)

Always run **`terraform plan`** before applying.
**Refactoring** updates **state mapping** without recreating resources.

---

## 9. What are lifecycle meta-arguments? When use create_before_destroy or prevent_destroy?

**Answer:**
**Lifecycle** controls resource behavior.

* **`create_before_destroy`** → ensures new resource is created before deleting old (**zero downtime**).
* **`prevent_destroy`** → protects critical resources like **production databases**.
* **`ignore_changes`** → ignores changes to certain attributes.

Used carefully in **production-critical systems**.

---

## 10. How do you securely manage secrets in Terraform?

**Answer:**
Never **hardcode secrets**.
Use:
* **AWS SSM Parameter Store**
* **AWS Secrets Manager**
* **HashiCorp Vault**

Mark variables as **`sensitive = true`**.
Access secrets using **data sources** and restrict **IAM permissions**.

---

## 11. How does Terraform handle dependency graphs internally?

**Answer:**
**Terraform** builds a **Directed Acyclic Graph (DAG)**.
**Dependencies** are auto-detected via **resource references**.
**Terraform** executes resources in **dependency order** and **parallelizes** independent resources.
Explicit dependencies can be added using **`depends_on`**.

---

## 12. Difference between refresh, plan, and apply?

**Answer:**
* **`refresh`** → Updates **state** from real infrastructure.
* **`plan`** → Compares **configuration** with **state** and shows **execution plan**.
* **`apply`** → Executes the **plan** and updates **infrastructure** + **state**.

Modern **Terraform** automatically **refreshes** during **plan**.

---

## 13. How do you design reusable, version-controlled modules for enterprise use?

**Answer:**
* Create **separate module repositories**.
* Follow **semantic versioning** (**v1.0.0**).
* Avoid **breaking changes**.
* **Pin module versions** in **production**.
* Include **validation** and **documentation**.
* Use **CI pipelines** for **module testing**.
* Never use **floating references** like **main branch** in **production**.

---

## 14. How do you perform zero-downtime updates?

**Answer:**
Approaches:
* **`create_before_destroy`**
* **Blue-Green deployment**
* **Rolling updates** with **ASG**
* **Multi-AZ** for **databases**
* **Health checks** before switching traffic

For **ALB + ASG**, **Blue-Green** is safest approach.

---

## 15. How do you handle Terraform failure midway?

**Answer:**
* Re-run **`terraform plan`**.
* **Terraform** will reconcile and continue (**idempotent**).
* If resources exist but not in state → use **`terraform import`**.
* If state is corrupted → **restore from backup**.
* If **lock stuck** → use **`terraform force-unlock`**.
* Avoid **manual deletion** unless necessary.

---

## 🔥 If Interviewer Asks: "Explain your Terraform Production Experience"

**You can say:**
> "In **production**, I use **S3 backend** with **DynamoDB locking**, maintain **separate states** per environment, enforce **CI/CD-only applies**, use **for_each** instead of **count**, implement **blue-green deployments** for **ASGs**, and manage **secrets** via **SSM**. I also ensure **drift detection** and **version-controlled reusable modules**."
