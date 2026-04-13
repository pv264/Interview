## 1. How do I ensure that RDS is deployed in the correct VPC when using modules?

**Answer:**
When using modules, I create the **VPC** in a dedicated module and expose the **VPC ID** and **subnet IDs** as **outputs**. 

In the **root module**, I pass these outputs into the **RDS module** as **input variables**. Inside the **RDS module**, I use the provided **VPC ID** for **security groups** and **subnet IDs** for the **DB subnet group**, ensuring that **RDS** is deployed in the correct **VPC**.



### Implementation Workflow:

1.  **VPC Module:** Define the network and declare `output "vpc_id" { value = aws_vpc.main.id }`.
2.  **Root Module:** Capture the output: `module.vpc.vpc_id`.
3.  **RDS Module:** Receive the value via a variable and apply it to the `aws_db_subnet_group` and `aws_security_group`.

> **Senior Signal:** This is the standard "Dependency Injection" pattern in **Terraform**. By passing IDs between modules rather than hardcoding them, you ensure that your infrastructure is modular, reusable, and that **RDS** always resides within the specific network boundaries defined by your **VPC module**.

## 2. Difference Between `terraform plan` and `terraform plan -refresh-only`

**Answer:**

* **`terraform plan`** compares my **Terraform code** with actual infrastructure.
* **`terraform plan -refresh-only`** compares **Terraform state** with actual infrastructure.

### Scenario: Manual Infrastructure Changes
If someone manually opens **port 443** in **AWS**, **`terraform plan`** will try to remove it since it’s not in code. But **`refresh-only`** will just detect that change and update the state without modifying infrastructure. That’s why I use **`refresh-only`** to safely audit drift before applying changes.

> **Senior Signal:** In production, blindly running **`terraform plan`** can unintentionally remove critical manual fixes. So using **`refresh-only`** first helps avoid outages.
## 3. What is `terraform taint`?

**Answer:**
**`taint`** in **Terraform** is used to mark a resource for **forced recreation**. 

When a resource is tainted, **Terraform** will **destroy and recreate** it in the next **`apply`**, even if there are no changes in the configuration.

> **Senior Signal:** While it is important to know what tainting does, you should definitely mention in an interview that the `terraform taint` command was deprecated in Terraform v0.15.2. The modern best practice is to use **`terraform apply -replace="resource_address"`** instead. Pointing this out shows the interviewer that you are up-to-date with current Terraform standards!

## 4. What are lifecycle arguments in Terraform and how are they used?

**Answer:**
**Lifecycle arguments** are used within a resource block to control how **Terraform** handles creation, update, and deletion. 

For example, we use:
* **`create_before_destroy`** to avoid downtime.
* **`prevent_destroy`** to protect critical resources like databases.
* **`ignore_changes`** when certain attributes are managed outside **Terraform**, such as **Auto Scaling** desired capacity.

> **Senior Signal:** Using **`ignore_changes`** is essential when working with external tools (like an AWS Application Auto Scaler or Kubernetes controllers) that dynamically modify resource properties, preventing Terraform from constantly trying to "revert" those external changes during every apply.

## 5.What is Terraform remote backend, and why do we use it?

**Answer:**
A **remote backend** in **Terraform** defines where the **state file** is stored remotely instead of locally. It is commonly configured using services like **S3**. 

We use it to enable **team collaboration**, ensure **centralized state management**, and improve **security**. 

> **Senior Signal:** It also supports **state locking** using services like **DynamoDB**, which prevents multiple users from making concurrent changes.

## 6. ## What is Terraform drift, and how do you handle it?

**Answer:**
**Terraform drift** occurs when infrastructure is changed outside **Terraform**, leading to a mismatch between the **state** and actual resources. 

We detect it using **`terraform plan`** or **`refresh-only`**, and then either update the code or revert the changes. 

To prevent drift, we **restrict manual access** and enforce changes through **Terraform**.
