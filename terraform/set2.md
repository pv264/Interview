## 1. How do I ensure that RDS is deployed in the correct VPC when using modules?

**Answer:**
# Terraform Modules: VPC and RDS Dependency

When I'm using Terraform modules, I want to avoid hardcoding the VPC ID inside my RDS module because the VPC ID is dynamically generated when Terraform creates the VPC.

So I separate the responsibility between the modules.

My **VPC module** is responsible for creating the VPC, public subnets, and private subnets. Once those resources are created, I expose the **VPC ID** and **private subnet IDs** using Terraform outputs.

Then, in my **root module**, I call both the VPC module and the RDS module. I take the private subnet IDs from the VPC module's output and pass them as an input variable to the RDS module.

Inside the **RDS module**, I use those private subnet IDs to create an **RDS DB subnet group**. The DB subnet group determines which VPC the RDS instance belongs to because all the subnets in that subnet group must belong to the same VPC.

## Flow

**VPC module creates VPC → VPC module creates private subnets → outputs expose subnet IDs → root module passes those IDs to RDS module → RDS module creates DB subnet group → RDS is deployed using that subnet group.**

This gives me a clear dependency between the modules. Terraform understands that the RDS module depends on the subnet IDs produced by the VPC module, so it creates the networking resources first and then creates the RDS resources.

This approach also makes the Terraform code reusable. If I deploy the same configuration in another environment, such as **QA or Production**, I don't have to change any hardcoded VPC IDs. Terraform creates the appropriate VPC and subnets and automatically passes the correct IDs to the RDS module.

## If the interviewer asks: "But where is the VPC ID actually used?"

I would explain:

> **"The RDS resource itself doesn't require me to directly specify a `vpc_id`. Instead, RDS uses a DB subnet group. The DB subnet group contains the private subnet IDs. Since those subnets were created inside my intended VPC, the subnet group is associated with that VPC, and the RDS instance is therefore placed in that VPC."**


## 2. Difference Between `terraform plan` and `terraform plan -refresh-only`

**Answer:**

### `terraform plan`
**`terraform plan`** compares the **desired Terraform configuration** (your code) with the **actual infrastructure** by querying the cloud provider APIs. If differences are found, **Terraform** generates a plan to make the real infrastructure match the **Terraform code**.

Terraform Code → Actual AWS Infrastructure


### `terraform plan -refresh-only`
**`terraform plan -refresh-only`** compares the **Terraform state file** with the **actual infrastructure** and generates a refresh plan to update the **state** so it matches the real infrastructure.

Actual AWS Infrastructure → Terraform State

---

> **Senior Signal:** Use **`terraform plan`** when you want to see what changes your code will make to the world. Use **`-refresh-only`** when you suspect the world has changed (drift) and you want to update your state file to reflect that reality without actually modifying any live resources.

### Scenario: Manual Infrastructure Changes
If someone manually opens **port 443** in **AWS**, **`terraform plan`** will try to remove it since it’s not in code. But **`refresh-only`** will just detect that change and update the state without modifying infrastructure. That’s why I use **`refresh-only`** to safely audit drift before applying changes.

> **Senior Signal:** In production, blindly running **`terraform plan`** can unintentionally remove critical manual fixes. So using **`refresh-only`** first helps avoid outages.
## 3. What is `terraform taint`?

**Answer:**
**`taint`** in **Terraform** is used to mark a resource for **forced recreation**. 

When a resource is tainted, **Terraform** will **destroy and recreate** it in the next **`apply`**, even if there are no changes in the configuration.

> **Senior Signal:** While it is important to know what tainting does, you should definitely mention in an interview that the `terraform taint` command was deprecated in Terraform v0.15.2. The modern best practice is to use **`terraform apply -replace="resource_address"`** instead. Pointing this out shows the interviewer that you are up-to-date with current Terraform standards!

## Real-World Scenario: Using `terraform taint` for GPU Instances

**Answer:**
I used **`terraform taint`** in a real scenario while provisioning a **vLLM GPU EC2 instance** using **Terraform**. During provisioning, we were installing **NVIDIA drivers** and container dependencies using **`remote-exec`** or shell provisioning scripts. The provisioning got stuck midway, leaving the **EC2 instance** in a partially configured state.

### The Problem:
The **EC2 instance** was created successfully, but the **NVIDIA driver installation** failed during the provisioning stage. **Terraform** considered the resource "created" (because the API call to AWS succeeded), but the server was not usable because the **GPU drivers** and **Docker containers** were not configured properly.



### The Solution:
Instead of manually deleting the **EC2 instance** through the AWS Console, I marked the resource as tainted using **`terraform taint`**. This tells **Terraform** that the resource is unhealthy and must be **recreated** during the next **`apply`**.

---

> **Senior Signal:** In high-performance computing (HPC) or AI infrastructure, provisioning often fails due to external network timeouts or driver compatibility issues. Using `taint` (or the modern `terraform apply -replace`) is the cleanest way to trigger a "clean slate" deployment. To prevent this in the future, it is often better to move away from `remote-exec` and use **Packer** to build a **Pre-baked Golden AMI** with drivers already installed, making the deployment process much faster and more reliable.

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

## 7. How does Terraform handle dependencies between resources?

**Answer:**
**Terraform** manages dependencies using a **dependency graph**. It automatically creates **implicit dependencies** when one resource references another, ensuring the correct order of creation.

For example, if an **EC2 instance** is launched in a **subnet**, and that **subnet** belongs to a **VPC**, **Terraform** will first create the **VPC**, then the **subnet**, and finally the **EC2 instance** because of these references.

 In cases where dependencies are not explicitly defined in the code, we can use **`depends_on`** to enforce them manually. For example, if a backend server depends on a database being fully ready but there is no direct reference, we can use **`depends_on`** to control the order.

 ## 8. What will happen if you delete a resource manually from AWS but it still exists in Terraform state?

**Answer:**
If a resource is manually deleted from **AWS** but still exists in the **Terraform state**, **Terraform** will behave as follows:

* It will detect the mismatch during the **`terraform plan`** phase. 
* Since the resource is defined in the **configuration** but missing in the actual infrastructure, it will plan to **recreate** it during **`terraform apply`**.

> **Senior Signal:** This behavior occurs because **Terraform** treats the configuration as the **desired state**, and its primary function is to reconcile the real-world infrastructure to match that declared state.

## How do you store secrets in terraform and how you call them in the code?

# Centralized Secret Management in Terraform using AWS SSM

In our Terraform configurations, we strictly avoid hardcoding sensitive information such as database passwords or API keys. Instead, we centralize our secrets by storing them as **SecureString** parameters within **AWS Systems Manager (SSM) Parameter Store**. 

During deployment, Terraform dynamically retrieves and injects these values without exposing them within the version-controlled codebase.



## The Workflow

1. **Secure Storage:** Secrets are managed directly in AWS SSM Parameter Store as encrypted `SecureString` types.
2. **Just-in-Time Retrieval:** Terraform uses a data source to fetch the plaintext value during the `plan` or `apply` phase.
3. **Dynamic Injection:** The retrieved value is referenced directly in the resources that require it.



## Terraform Implementation Example

### 1. Retrieve the Secret via Data Source
To securely fetch the secret at deployment time, use the `aws_ssm_parameter` data source and ensure `with_decryption` is set to `true`.


data "aws_ssm_parameter" "database_password" {
  name            = "/prod/database/password"
  with_decryption = true
}

## 9. What are Terraform workspaces, and when would you use them?

**Answer:**
**Terraform workspaces** allow us to manage multiple **state files** for the same configuration. They are used to deploy the same infrastructure code to different environments like **dev**, **staging**, and **production**, while keeping their states isolated.

For example, I can use the same **Terraform code** to create an **EC2 instance**, but by switching workspaces like **dev** and **prod**, **Terraform** will create separate instances for each environment because each workspace maintains its own state file.

 In our project, we maintained separate directories for dev and prod. Each environment had its own S3 backend and DynamoDB table for state locking, ensuring complete isolation and avoiding accidental impact across environments.”


 ## 10 What are Functions in Terraform?

Terraform functions are built-in functions used to manipulate data within Terraform configurations. They help perform operations such as string manipulation, list and map processing.Functions make Terraform code more dynamic, reusable, and easier to maintain. Some commonly used functions include `length()`, `lookup()`, `merge()`,. In real projects, they're often used to generate resource names, calculate subnet CIDRs, merge tags, read configuration files, and dynamically configure infrastructure.

Suppose we want one subnet in each Availability Zone. Instead of writing three subnet resources manually:
*   Subnet-A
*   Subnet-B
*   Subnet-C

We use `count`.

```hcl
variable "public_subnets" {
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

resource "aws_subnet" "public" {
  count       = length(var.public_subnets)
  cidr_block  = var.public_subnets[count.index]
}

We used the length() function with count so Terraform automatically created one subnet for each CIDR block. If we added another subnet to the list later, Terraform created it automatically without changing the resource definition.
