## How do I ensure that RDS is deployed in the correct VPC when using modules?

**Answer:**
When using modules, I create the **VPC** in a dedicated module and expose the **VPC ID** and **subnet IDs** as **outputs**. 

In the **root module**, I pass these outputs into the **RDS module** as **input variables**. Inside the **RDS module**, I use the provided **VPC ID** for **security groups** and **subnet IDs** for the **DB subnet group**, ensuring that **RDS** is deployed in the correct **VPC**.



### Implementation Workflow:

1.  **VPC Module:** Define the network and declare `output "vpc_id" { value = aws_vpc.main.id }`.
2.  **Root Module:** Capture the output: `module.vpc.vpc_id`.
3.  **RDS Module:** Receive the value via a variable and apply it to the `aws_db_subnet_group` and `aws_security_group`.

> **Senior Signal:** This is the standard "Dependency Injection" pattern in **Terraform**. By passing IDs between modules rather than hardcoding them, you ensure that your infrastructure is modular, reusable, and that **RDS** always resides within the specific network boundaries defined by your **VPC module**.
