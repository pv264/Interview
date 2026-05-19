# CI/CD Pipeline Security: Preventing Unauthorized Access & Supply Chain Attacks

**"How do you secure your CI/CD pipeline to prevent unauthorized access or supply chain attacks?"**

To secure our CI/CD pipeline and prevent unauthorized access or supply chain attacks, we follow multiple security layers, including least privilege access, secrets management, image scanning, and artifact integrity validation.

## 🔹 1. Access Control & Identity Management
*   ✅ **Service Accounts (Least Privilege Access):** CI/CD tools (Jenkins, GitHub Actions, GitLab CI) run with minimal permissions using Kubernetes RBAC.
*   ✅ **IAM Roles & Policies:** Restricts access to AWS/GCP services based on job roles.
*   ✅ **Multi-Factor Authentication (MFA):** Enforced for CI/CD system access.
*   ✅ **Git Branch Protection Rules:** Prevents unauthorized code merges.

## 🔹 2. Secrets Management
*   ✅ **Avoid Hardcoded Secrets:** Use HashiCorp Vault, AWS Secrets Manager, or Kubernetes Secrets.
*   ✅ **Environment Variables Encryption:** Secure sensitive data before injecting it into the pipeline.
