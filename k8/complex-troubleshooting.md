## Scenario: High Latency with Normal CPU/Memory on EKS

**The Situation:**
Your company is running a production application on EKS. Traffic has suddenly increased **3x in the last 30 minutes**.

**The Symptoms:**
* Response time increased from 200ms → 2 seconds.
* CPU usage is only 40%.
* Memory usage is normal.
* No pod crashes.
* HPA (Horizontal Pod Autoscaler) did **NOT** scale.

**👉 Troubleshooting Strategy & Answer:**

**1. Isolate the Bottleneck (The "Why")**
Since CPU and memory are normal but latency increased alongside higher traffic, I immediately suspect a **concurrency issue** or a **downstream dependency bottleneck**. 
* The application pods are running fine, but they are likely waiting on something else (e.g., database locks, exhausted thread pools, or slow 3rd-party APIs).

**2. Investigation Steps**
* **ALB Latency:** Analyze ALB metrics (`TargetResponseTime`) to confirm the delay is happening inside the backend application.
* **App/Pod Metrics:** Check APM tools (like Datadog, New Relic, or AppDynamics) for **thread pool utilization** and active worker connections. 
* **Dependencies:** Check **Database connections** (RDS/DynamoDB) to see if the connection pool is exhausted or if there are slow queries queueing up.

**3. Fix the Autoscaling (HPA)**
* **The Flaw:** The HPA did not scale because it was likely configured to scale based on CPU utilization (e.g., scale at 70% CPU). Since CPU only hit 40%, the scaling trigger was never met.
* **The Fix:** CPU-only scaling is not sufficient for this workload. I would review and update the HPA logic to use **Custom Metrics** (e.g., scaling based on `Request Count Per Target` from the ALB, or concurrent connections).



**4. Long-Term Prevention**
Based on the findings, I would adjust the scaling strategy to be request-driven and optimize backend capacity (like increasing DB connection pool limits) to prevent similar issues during future traffic spikes.
## Incident Response: 2:15 AM Production Outage (ALB 503)

**The Situation:**
* Entire application is down (ALB returns 503).
* Target group shows 0 healthy targets.
* EC2 instances and Kubernetes cluster are UP.

**👉 Executive Strategy (The On-Call Mindset):**
"Since the ALB shows no healthy targets but the underlying infrastructure is up, I would immediately inspect Target Group health reasons and validate Kubernetes service endpoints and pod readiness state. If this was caused by a bad deployment, I would perform an immediate rollback to restore traffic. After recovery, I would perform an RCA and improve health check alignment and deployment validation to prevent recurrence."

---

### Step-by-Step Execution:

**1. What do you check first?**
* I go straight to the **AWS Target Group Health Checks** to see *why* they are failing (e.g., Connection Timeout, Request Timeout, or HTTP 500 errors).
* Simultaneously, I check the Kubernetes **Endpoints** to see if the pods are actually ready to receive traffic.



**2. What commands or AWS components do you use?**
* **AWS Console/CLI:** Check ALB Target Group health reasons and Security Groups (did a recent rule change block ALB -> Node traffic?).
* **Kubernetes CLI:**
  * `kubectl get endpoints <service-name>` (Are pod IPs actually registered to the service?)
  * `kubectl get pods` (Are they `Running` but `0/1 Ready`?)
  * `kubectl describe pod <pod-name>` (Look at the Events section for failing readiness probes).
  * `kubectl logs -n kube-system deploy/aws-load-balancer-controller` (Check if the ingress controller failed to register targets).

**3. How do you restore service FAST?**
* **Mitigation over deep investigation:** At 2:15 AM, the goal is MTTR (Mean Time To Recovery).
* If a recent deployment caused the health checks to fail:
  ```bash
  kubectl rollout undo deployment <app-name>

  ## Incident Response: Corrupted Terraform State & Infrastructure Drift

**The Situation:**
* Your Terraform state file got corrupted in production.
* Someone accidentally ran `terraform apply`.
* Infrastructure drift occurred.

**👉 Executive Strategy (The On-Call Mindset):**
"If Terraform state was corrupted and an apply caused drift, my first step would be to stop further changes and assess the impact. If using an S3 backend with versioning, I would restore the previous state file version. If not, I would manually reconcile using `terraform refresh` and `terraform import`. After stabilizing production, I would implement strict remote backend configuration, state locking, versioning, and a CI/CD-controlled apply process to prevent recurrence."

---

### Step-by-Step Execution:

**1. Stop and Assess**
* Immediately halt any further Terraform runs or manual cloud console changes to prevent compounding the drift.
* Assess the actual impact on the live production environment (e.g., were critical resources deleted, or just modified?).

**2. State Recovery (The Happy Path)**
* If the state is stored in an **S3 backend with versioning enabled**, navigate to the S3 bucket, find the `terraform.tfstate` object, and restore the last known good version before the corruption.
* Run `terraform plan` (or `terraform apply -refresh-only`) to verify the restored state matches the real-world infrastructure.



**3. Manual Reconciliation (The Hard Path)**
* If versioning was *not* enabled (or the state was local), you must manually rebuild the state.
* Identify the drifted/orphaned resources.
* Use `terraform import` to bring existing, real-world resources back into the state file one by one.
* Use `terraform apply -refresh-only` to update the state file with the current configuration of those resources.

**4. Long-Term Prevention**
* **Remote Backend:** Always use a robust remote backend (like AWS S3).
* **Versioning:** Strictly enforce S3 object versioning on the state bucket.
* **State Locking:** Implement a DynamoDB table for state locking to prevent concurrent apply operations.
* **CI/CD Automation:** Remove direct `terraform apply` access from local engineer machines. Force all applies to go through a peer-reviewed, automated CI/CD pipeline.
