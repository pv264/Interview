# EC2 Unresponsive Instance Troubleshooting Guide

When an EC2 instance suddenly becomes unresponsive, I follow a structured, step-by-step approach to identify the root cause, restore service, and prevent future recurrences.

---

## 1. Initial Infrastructure & Status Checks
* **EC2 Instance State:** Verify if the instance is `Running`, `Stopped`, or `Rebooting`.
* **AWS Status Checks:** 
  * Check the **System Status Check** to verify if the underlying AWS hardware/infrastructure is healthy.
  * Check the **Instance Status Check** to determine if the issue is inside the instance's OS or software layer.

---

## 2. Resource Utilization Analysis
* Review **Amazon CloudWatch Metrics** to spot potential bottlenecks or crashes:
  * **CPU Utilization:** Check for 100% CPU spikes or exhaustion.
  * **Memory Usage:** Look for memory leaks or high utilization.
  * **Disk I/O & Disk Space:** Check for full disks or high read/write latency.
  * **Network Usage:** Inspect `NetworkIn` and `NetworkOut` for traffic drops or sudden spikes.

---

## 3. Network & Connectivity Verification
* Audit networking configurations to ensure traffic is reaching the instance:
  * **Security Groups:** Confirm inbound and outbound rules allow required traffic.
  * **Network ACLs (NACLs):** Verify subnet-level allow/deny traffic rules.
  * **Route Tables:** Ensure correct routing to Internet Gateways or NAT Gateways.
  * **SSH Access:** Attempt standard SSH connectivity to rule out network-level blocks.

---

## 4. Deep-Dive Diagnostics
* If **SSH is unavailable**, connect via **AWS Systems Manager (SSM) Session Manager**:
  * **System Logs:** Inspect `/var/log/messages`, `/var/log/syslog`, or `dmesg` for kernel panics or Out-Of-Memory (OOM) killer events.
  * **Processes:** Check running processes using commands like `top`, `htop`, or `ps aux` to identify runaway processes.
  * **Disk & Memory:** Run `df -h` and `free -m` to inspect disk space and RAM directly on the host OS.

---

## 5. Application Troubleshooting
* If the underlying infrastructure and OS are healthy:
  * Check the **Application Service Status** (e.g., `systemctl status <service-name>`).
  * Inspect **Application Error Logs** for unhandled exceptions or crashes.
  * Review recent **Deployments** and **Configuration Changes** that might have introduced bugs or resource degradation.

---

## 6. Remediation & Prevention
* **Recovery:** Resolve the immediate root cause (e.g., restart services, clear disk space, reboot instance) to minimize downtime.
* **Prevention:** Implement long-term guards such as CloudWatch alarms, auto-recovery actions, Auto Scaling Groups, and automated health checks to prevent recurring issues.
