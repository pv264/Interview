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
