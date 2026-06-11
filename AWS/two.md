## 1 What is SSL/TLS Termination?

**Answer:**
**SSL/TLS Termination** is the process of decrypting **HTTPS** traffic at a specific point in your infrastructure, usually a **Load Balancer**, **Ingress Controller**, **API Gateway**, or **Reverse Proxy**.

Instead of the application server handling the CPU-intensive encryption and decryption, this front-facing component handles it and forwards the request (typically as plain HTTP) to the backend servers.



> **Senior Signal:** Terminating TLS at the Load Balancer (like an AWS ALB using ACM) is standard practice because it centralizes certificate management and offloads CPU strain from your application nodes. However, in highly regulated environments (like PCI-DSS, HIPAA, or modern Zero-Trust architectures), security teams may require **End-to-End Encryption**. In those cases, you would either use **TLS Pass-through** (using a Network Load Balancer) or configure the ALB to re-encrypt the traffic before sending it to the backend.

## What is AWS Certificate Manager (ACM)?

**Answer:**
**AWS Certificate Manager (ACM)** is a managed AWS service used to provision, store, manage, and automatically renew **SSL/TLS certificates**. 

These certificates are attached to AWS managed services to enable **HTTPS** communication and secure data transmission in transit between clients and your AWS resources. Common integrations include:
* **Application Load Balancers (ALB)**
* **Amazon CloudFront** (for global edge caching)
* **API Gateway**



> **Senior Signal:** The biggest operational advantage of ACM is **zero-touch automatic renewal**. If you use DNS validation (especially combined with Route 53), ACM will automatically renew the certificate before it expires and seamlessly deploy the new certificate to your load balancers without any downtime or manual rotation. A common interview "gotcha" is asking if you can download a public ACM certificate to manually install on an Nginx EC2 instance—the answer is **no**; public ACM certificates are tightly locked to AWS-managed endpoints.
