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
