## 1. CloudWatch metrics were missing during an incident. How would you troubleshoot and resolve it?

**Answer:**
If CloudWatch metrics are missing during an incident, I would systematically troubleshoot by narrowing down the point of failure:

### 1. Identify the Metric Type
First, I would determine whether the missing data involves **AWS-native metrics** (like basic CPU/Network metrics provided by AWS) or **custom metrics** (like memory utilization or application-specific data collected through the CloudWatch Agent).

### 2. Verify the CloudWatch Agent & IAM
If they are custom metrics, I would check the instance itself:
* Verify that the **CloudWatch Agent** is running properly.
* Check the agent's internal logs for configuration errors or metric publishing failures.
* Ensure the EC2 instance's attached IAM Role has the required permissions (specifically `cloudwatch:PutMetricData` or the managed `CloudWatchAgentServerPolicy`).

### 3. Check Network Connectivity
Validate that the instance can actually reach the AWS CloudWatch service. It must have outbound access to the CloudWatch API endpoints via a NAT Gateway, an Internet Gateway, or a **VPC Endpoint** (AWS PrivateLink).

### 4. Confirm Viewing Context
I would double-check the AWS Console to ensure I am looking at the correct **AWS Region**, **Namespace**, and exact **Dimensions**. A slight mismatch in dimensions will cause the metric to disappear from your expected dashboard.

### 5. Fallback Strategy
If metrics are still unavailable and I need to resolve the active incident immediately, I would use alternative monitoring sources such as **application logs**, **ALB access logs**, or our **Prometheus and Grafana** stack to investigate the root cause while restoring metric collection in the background.

> **Senior Signal:** Pointing out the distinction between AWS-native metrics and agent-based custom metrics immediately shows deep AWS knowledge. Additionally, mentioning that you would pivot to alternative tools (like Prometheus or ALB logs) to *solve the actual incident first* rather than getting tunnel vision on fixing the monitoring tool itself demonstrates strong incident management maturity and prioritization skills!
>
> ## 3 An application is experiencing high latency, and you suspect the NAT Gateway is the bottleneck. How would you identify and resolve the issue?

**Answer:**
If application latency is caused by a NAT Gateway bottleneck, I would systematically identify and resolve the issue through the following steps:

### 1. Identify and Confirm the Issue
I would first confirm the bottleneck by checking **CloudWatch metrics** for the NAT Gateway, specifically looking at:
* `ActiveConnectionCount`
* `PacketsProcessed` and `BytesProcessed`
* `ErrorPortAllocation` (which indicates port exhaustion)

### 2. Understand the Root Cause
A NAT Gateway can become a bottleneck when many instances in private subnets generate massive amounts of outbound internet traffic at the same time. This can cause **connection exhaustion** or **port exhaustion** (as a single NAT Gateway has limits on concurrent connections to a single destination).

### 3. Resolve the Bottleneck
To resolve the issue, I would implement the following architectural fixes:
* **Analyze Traffic Patterns:** Identify which applications are generating the most traffic and reduce unnecessary outbound calls.
* **Use VPC Endpoints (AWS PrivateLink):** Route traffic destined for AWS services like S3 and DynamoDB through VPC Endpoints rather than the NAT Gateway. This keeps traffic entirely on the AWS private network.
* **Scale Horizontally:** Distribute the outbound traffic by deploying multiple NAT Gateways across different Availability Zones (AZs) and updating the route tables accordingly.

After implementing the fixes, I would continue to monitor the application latency and NAT Gateway CloudWatch metrics to ensure the issue is completely resolved.

> **Senior Signal:** Pointing out **VPC Endpoints** is a great technical answer, but emphasizing the *cost* aspect makes it a Senior answer. NAT Gateways charge per GB of data processed. By routing S3 or DynamoDB heavy traffic through a **Gateway VPC Endpoint** (which is free), you not only solve the port exhaustion and latency issues, but you also completely eliminate the NAT data processing fees for that traffic, often saving the company a massive amount of money!
