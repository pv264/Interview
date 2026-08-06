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


## 2. How do you restrict access to a specific object and specific user in S3?

**Answer:**
To restrict access to a specific object in S3 for only one specific IAM user, I create an **S3 bucket policy** that grants access only to that user’s IAM ARN for that exact object key, and explicitly denies access to everyone else.

In the policy, I specify:
* **Principal:** The specific IAM user's ARN.
* **Resource:** The exact object ARN (e.g., `arn:aws:s3:::my-bucket/my-specific-file.txt`).
* **Action:** The required permission (for example, `s3:GetObject`).

This ensures that only that designated user can access that object, regardless of the baseline permissions other users or roles might have.

> **Senior Signal:** To make this implementation absolutely bulletproof, mention that you would use an **Explicit Deny** statement combined with a **`NotPrincipal`** element in the bucket policy. Because AWS always evaluates an explicit `Deny` over any `Allow` permissions, this approach guarantees that absolutely no one else—not even an AWS Administrator with `s3:*` privileges—can access that specific object.

## 3 what is your experience working with Lambda
# Infrastructure Automation: Automatically Stopping EC2 Instances

I have worked on AWS Lambda for infrastructure automation. One of the tasks I implemented was automatically stopping EC2 instances to reduce costs when they were not required.

## Implementation Details

* **Lambda & IAM Role:** We created a Lambda function in Python and assigned it an IAM execution role with permissions such as `ec2:StopInstances` and CloudWatch Logs permissions.
* **Trigger:** The Lambda function was triggered on a schedule using Amazon EventBridge. At the scheduled time, EventBridge invoked the Lambda function.
* **Execution (Boto3):** The function used the AWS SDK (Boto3) to identify the target EC2 instances—either by specific instance IDs or by tags like `Environment=Dev`—and then called the `StopInstances` API.
* **Logging:** After stopping the instances, the function wrote logs to CloudWatch so we could verify that the execution completed successfully.


# Difference Between Target Tracking and Step Scaling

Both **Target Tracking** and **Step Scaling** are Auto Scaling policies in AWS that automatically add or remove EC2 instances based on CloudWatch metrics.

The main difference is **how they decide how many instances to add or remove.**

---

# 1. Target Tracking Scaling

Target Tracking works like a thermostat in an air conditioner.

For example:

Suppose I set the target CPU utilization to:

```text
50%
```

Now AWS continuously monitors CPU.

If CPU increases above 50%:

```text
CPU = 70%
```

AWS automatically adds instances until CPU comes back close to 50%.

If CPU later drops to:

```text
30%
```

AWS automatically removes instances until CPU returns near the target.

The important point is:

**I only define the target value.**

AWS automatically decides:

* When to scale
* How many instances to add
* How many instances to remove

It's simple and requires very little tuning.

---

# Example

Target CPU:

```text
50%
```

Current CPU:

```text
75%
```

AWS may decide:

```text
Add 2 Instances
```

After scaling:

```text
CPU = 48%
```

AWS stops scaling.

---

# When to Use Target Tracking

I would use Target Tracking when:

* CPU is a good representation of workload.
* Traffic patterns are predictable.
* I don't need fine-grained control over scaling.

For example:

* Web applications
* REST APIs
* General-purpose application servers

---

# 2. Step Scaling

Step Scaling gives much more control.

Instead of defining a target, I define multiple thresholds.

For example:

```text
CPU > 60%

Add 1 Instance
```

```text
CPU > 75%

Add 2 Instances
```

```text
CPU > 90%

Add 4 Instances
```

Similarly, I can define scale-in rules.

AWS simply follows the rules I configure.

I decide exactly:

* When to scale
* How many instances to add
* How many instances to remove

---

# Example

CloudWatch Alarm:

```text
CPU = 92%
```

My policy says:

```text
CPU > 90%

↓

Add 4 Instances
```

AWS immediately launches four new instances.

---

# Real Project Example

In our LLM infrastructure, we **didn't use CPU utilization** because it wasn't a good indicator of workload.

Our Haystack application spent much of its time waiting for downstream services like **Milvus** and the **vLLM inference server**. During load testing, CPU utilization remained relatively low even though request queues and response times increased.

Instead, we used the ALB **RequestCountPerTarget** metric.

Based on our performance testing:

* Two Haystack instances could handle approximately **60 requests every 10 seconds**.
* That translates to **360 requests per minute**.
* Dividing that across two instances gave us a threshold of **180 requests per target per minute**.

We configured CloudWatch alarms and **Step Scaling** policies.

For example:

* If RequestCountPerTarget exceeded the threshold, the Auto Scaling Group added another Haystack instance.
* As traffic increased further, additional instances were launched according to the scaling policy.

We chose Step Scaling because it gave us precise control over how aggressively the application layer scaled based on real traffic rather than CPU utilization.

---

# Key Differences

| Target Tracking                                  | Step Scaling                                                       |
| ------------------------------------------------ | ------------------------------------------------------------------ |
| Set a target value (for example, CPU 50%)        | Define multiple thresholds and scaling actions                     |
| AWS decides how many instances to add or remove  | You define exactly how many instances to add or remove             |
| Easier to configure                              | More flexible and customizable                                     |
| Best for predictable workloads                   | Best for workloads with varying traffic patterns or custom metrics |
| Commonly uses CPU or average utilization metrics | Can use custom CloudWatch metrics such as RequestCountPerTarget    |

---

# Which One Would You Choose?

It depends on the application.

If CPU accurately reflects the workload, Target Tracking is usually sufficient because AWS automatically maintains the desired utilization.

If the application requires more control or CPU isn't a good indicator of load, I would use Step Scaling with a metric that better represents the application's behavior.

---

# Interview Summary

> **"Target Tracking and Step Scaling are both Auto Scaling policies, but they work differently. In Target Tracking, I define a target metric such as 50% CPU utilization, and AWS automatically adjusts the number of instances to maintain that target. It's simple to configure and works well when the chosen metric accurately reflects the workload. In Step Scaling, I define multiple CloudWatch thresholds and specify exactly how many instances should be added or removed at each threshold. It provides greater control and is useful when scaling decisions need to be based on custom metrics or application-specific behavior. In my LLM project, we used Step Scaling with the ALB RequestCountPerTarget metric because CPU utilization didn't accurately represent the application's workload."**

