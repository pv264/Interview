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

## 4. Designing Terraform Architecture for Multiple Environments

To ensure a scalable and secure enterprise-grade setup, the architecture must focus on **modularity**, **state isolation**, and **automated deployment pipelines**.

### Core Architectural Principles

* **Reusable Modules:** Create a `modules/` directory to define standardized infrastructure components (e.g., VPC, RDS, EKS). This ensures consistency across all environments and reduces code duplication.
* **State Isolation:** Maintain **separate state files** for each environment to prevent accidental changes in `prod` while working in `dev`.
* **Dedicated Backends:** Use a **separate backend configuration** (e.g., distinct S3 buckets or prefixes) for `dev`, `qa`, and `prod`.
* **Environment-Specific Variables:** Use `terraform.tfvars` or specific variable files for each environment to handle differences in instance sizes, CIDR blocks, or tags.
* **CI/CD Integration:** Control deployments via pipelines (e.g., GitHub Actions, GitLab CI, or Jenkins) to enforce manual approvals for `prod` and automated testing for `dev`.

### Recommended Directory Structure

```text
root-directory/
├── modules/                # Shared reusable components
│   ├── vpc/
│   ├── ec2/
│   └── rds/
└── environments/           # Environment-specific configurations
    ├── dev/
    │   ├── main.tf         # Calls modules with dev-specific values
    │   ├── variables.tf
    │   └── backend.tf      # S3 bucket for dev state
    ├── qa/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── backend.tf      # S3 bucket for qa state
    └── prod/
        ├── main.tf
        ├── variables.tf
        └── backend.tf      # S3 bucket for prod state
