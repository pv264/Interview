# 1 EC2 Intermittent Unresponsiveness — Troubleshooting Approach

If an EC2 instance becomes intermittently unresponsive specifically between **2 PM and 5 PM**, and CPU, memory, and disk utilization look normal, but I see the **system queue length increasing**, I would first suspect that the instance is experiencing **I/O or resource contention that isn't visible from the basic utilization metrics**.

I would first correlate the issue with the exact time window and check CloudWatch metrics such as:

- `DiskReadOps`
- `DiskWriteOps`
- EBS latency
- EBS burst balance
- EBS throughput/IOPS utilization
- Network traffic
- EC2 status checks

On the instance itself, I would use tools like:

```bash
iostat
vmstat
sar
top
ps
```

to determine whether processes are waiting on I/O, blocked, or consuming excessive resources.

For example, with:

```bash
iostat -xz 1
```

I would specifically look at:

- `%util`
- `await`
- `avgqu-sz`
- Read/write latency
- IOPS

If `await` and `avgqu-sz` are high, that would indicate requests are building up waiting for the storage device.

I would then identify which process is generating the I/O using tools such as:

```bash
iotop
pidstat -d
```

I would also check whether a scheduled activity is running between **2 PM and 5 PM** — for example:

- Backup jobs
- Database jobs
- Log rotation
- Cron jobs
- Batch processing
- Security scans
- Application workloads

Since the problem occurs during a specific time window, a **scheduled workload** would be one of my first things to investigate.

If the root cause is **EBS I/O saturation**, I would increase the provisioned IOPS/throughput or move to an appropriate EBS volume type.

If a particular application or batch job is causing the contention, I would optimize or reschedule that workload, or isolate it onto another instance.

Finally, I would monitor the instance after the change and verify that **queue length and latency return to normal during the 2 PM–5 PM period**.



# 2 EC2 SSH Connectivity — Sev-1 Troubleshooting

## Question

An EC2 instance is running normally, and the application is also working as expected. However, the application team has raised a Sev-1 incident because they are not able to SSH into the EC2 instance.

You have joined the incident call. What areas would you check to identify the root cause and restore the SSH connectivity?

---

If the application is working normally but users are unable to SSH into the EC2 instance, I would treat this as an SSH connectivity issue rather than assuming that the EC2 instance is down.

### 1. First, understand the exact SSH error

I would ask the application team to share the exact error they are getting.

For example:

```bash
ssh -vvv ec2-user@<EC2-IP>
```

The three common scenarios are:

```text
Connection timed out
```

This usually points towards a network, Security Group, NACL, routing, VPN, firewall, or connectivity issue.

```text
Connection refused
```

This usually means the instance is reachable, but nothing is accepting connections on port 22, so I would investigate `sshd`.

```text
Permission denied (publickey)
```

This indicates that network connectivity is working, but there is an authentication or user/key-related problem.

I would also determine whether the problem affects **all users or only a particular user/source IP**.

---

### 2. Check the EC2 status

From the AWS console or CLI, I would check the instance and system status checks:

```bash
aws ec2 describe-instance-status \
  --instance-ids <instance-id>
```

I would verify that:

- Instance status check is passing
- System status check is passing
- There are no ongoing AWS maintenance or recovery events

Since the application is healthy, I would expect these to be normal, but I would still verify them.

---

### 3. Check the network path to port 22

I would verify whether port 22 is reachable from the affected source.

From the client or bastion:

```bash
nc -vz <EC2-IP> 22
```

or:

```bash
telnet <EC2-IP> 22
```

If it times out, I would investigate the network path.

I would check:

- Security Group inbound rule for TCP 22
- NACL inbound and outbound rules
- Route table
- Internet Gateway if it is a public instance
- VPN connectivity if users connect through a corporate VPN
- Bastion host connectivity if SSH is through a bastion
- Corporate firewall rules

For the Security Group, I would verify that TCP 22 is allowed from the **approved corporate/bastion IP or security group**, rather than opening it to `0.0.0.0/0`.

---

### 4. If network connectivity is working, access through SSM

If AWS Systems Manager Session Manager is configured, I would use it to access the instance without relying on SSH.

For example:

```bash
aws ssm start-session --target <instance-id>
```

This is very useful during an incident because it allows me to troubleshoot the instance even when SSH is unavailable.

---

### 5. Check whether SSH service is running

Once inside the instance:

For Amazon Linux/RHEL:

```bash
sudo systemctl status sshd
```

For Ubuntu:

```bash
sudo systemctl status ssh
```

If the service is stopped, I would check why before simply restarting it:

```bash
sudo journalctl -u sshd --since "30 minutes ago"
```

Then I would validate the SSH configuration:

```bash
sudo sshd -t
```

If the configuration is valid and the service is simply stopped, I could restart it:

```bash
sudo systemctl restart sshd
```

Then verify:

```bash
sudo systemctl status sshd
```

---

### 6. Verify that port 22 is actually listening

I would check:

```bash
sudo ss -lntp | grep ':22'
```

I expect something similar to:

```text
LISTEN 0 128 0.0.0.0:22 0.0.0.0:*
```

If port 22 isn't listening, I would investigate `sshd`.

If it is listening but remote users still cannot connect, I would go back to the network/security layer.

---

### 7. Check SSH logs

For Amazon Linux/RHEL:

```bash
sudo journalctl -u sshd
```

or:

```bash
sudo tail -f /var/log/secure
```

For Ubuntu:

```bash
sudo journalctl -u ssh
```

or:

```bash
sudo tail -f /var/log/auth.log
```

I'm looking for:

- Authentication failures
- Invalid SSH configuration
- PAM errors
- Too many connections
- Account lockouts
- Permission issues
- SSH daemon errors

---

### 8. Check whether the instance is resource constrained

Even though the application is working, the instance could still be under resource pressure.

I would check:

```bash
top
```

```bash
free -m
```

```bash
df -h
```

```bash
df -i
```

```bash
uptime
```

And:

```bash
vmstat 1
```

I would specifically look for:

- High CPU
- Memory exhaustion
- Swap activity
- Disk space exhaustion
- Inode exhaustion
- High I/O wait
- High load average
- Too many processes

For example, if the root filesystem is 100% full:

```text
/dev/xvda1   20G   20G   0G   100%
```

SSH may fail because the system cannot create temporary files, write logs, or perform other operations required during login.

---

### 9. Check for too many SSH connections/processes

I would also check existing SSH connections:

```bash
sudo ss -ant | grep ':22'
```

and processes:

```bash
ps -ef | grep ssh
```

If there are a large number of connections or stuck processes, I would investigate whether we are hitting SSH limits such as:

```text
MaxStartups
MaxSessions
```

in:

```bash
sudo vi /etc/ssh/sshd_config
```

I would not change these values blindly; I would first identify why the connections are accumulating.

---

### 10. Check recent changes

Because this is a Sev-1 incident, I would correlate the failure with recent changes.

For example:

- Security Group modification
- NACL modification
- Route table change
- VPN/firewall change
- OS patching
- SSH configuration change
- User/key changes
- Deployment
- Instance/network changes

I would check CloudTrail and infrastructure change history if an AWS-side change is suspected.

---

### 11. Restore connectivity

The fix depends on what I identify.

For example:

**If Security Group is wrong:**

Restore the correct TCP 22 rule from the approved source.

**If `sshd` is stopped:**

```bash
sudo systemctl restart sshd
```

**If SSH configuration is invalid:**

```bash
sudo sshd -t
```

Fix the configuration and restart SSH.

**If disk is full:**

Identify what is consuming space:

```bash
sudo du -xhd1 / | sort -h
```

Clean up unnecessary files/logs or rotate logs appropriately.

**If the issue is memory/process exhaustion:**

Identify the offending process:

```bash
ps aux --sort=-%mem | head
```

or:

```bash
ps aux --sort=-%cpu | head
```

Then take the appropriate corrective action.

---

### 12. Validate the fix

After making the change, I would test from the affected source:

```bash
ssh -vvv ec2-user@<EC2-IP>
```

I would confirm that:

1. Port 22 is reachable.
2. SSH authentication succeeds.
3. The application is still healthy.
4. No unexpected changes were introduced.
5. The issue does not recur.

### How I would summarize this during the interview

> "Since the application is healthy, I wouldn't immediately assume the EC2 instance is down. I would first identify whether SSH is timing out, being refused, or failing authentication using `ssh -vvv`. Then I would determine whether the issue affects all users or only a particular source. I would check EC2 status checks and the network path, including Security Groups, NACLs, routing, VPN or bastion connectivity, and port 22 using `nc -vz`.
>
> If the network path is healthy, I would use SSM Session Manager to access the instance and check `systemctl status sshd`, `ss -lntp`, SSH logs, and `sshd -t`. I would also check system resources using `top`, `free`, `df`, `df -i`, `uptime`, and `vmstat`, because disk exhaustion, memory pressure, I/O wait, or process exhaustion can also affect SSH.
>
> I would then correlate the incident with recent infrastructure or OS changes. Once I identify the root cause, I would make the minimum required change, restore SSH connectivity, and validate it from the affected users' network. I would avoid simply rebooting the instance because the application is healthy and a reboot could introduce unnecessary risk during a Sev-1 incident."





# Auto Scaling Troubleshooting — EC2 Instances Not Launching

## Question

Auto scaling is not working as expected and new instances are not being launched within the required time frame how would you trouble shoot and resolve the issue

---

If Auto Scaling is not working as expected and new EC2 instances are not being launched within the required time, I would first determine **where the scaling process is breaking**.

The flow I would troubleshoot is:

**CloudWatch metric → Alarm → Scaling policy → ASG desired capacity → Launch request → EC2 instance → Target registration**

### 1. Check the current ASG state

First, I would check the Auto Scaling Group:

```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names <asg-name>
```

I would look at:

- Desired capacity
- Current capacity
- Minimum capacity
- Maximum capacity
- Instance health
- Availability Zones
- Launch Template/version

For example, if:

```text
Desired = 4
Current = 2
Max = 4
```

then the ASG knows it needs two more instances.

If:

```text
Desired = 2
Current = 2
```

but I expected scaling to happen, then I would investigate the **CloudWatch alarm and scaling policy**.

---

### 2. Check CloudWatch metrics

Next, I would verify whether the scaling metric is actually crossing the configured threshold.

For example, if scaling is based on CPU:

```text
CPU > 70%
```

or for an ALB-based application:

```text
RequestCountPerTarget > threshold
```

I would check the CloudWatch metric for the exact period when the scaling should have happened.

I would verify:

- Metric is receiving data
- Correct dimensions are being used
- Threshold is correct
- Evaluation period is correct
- Datapoints are sufficient to trigger the alarm
- There isn't a delay in metric publishing

This is important because sometimes the application is under load, but the ASG is looking at the **wrong metric, wrong target group, or wrong dimensions**.

---

### 3. Check the CloudWatch alarm

I would inspect the alarm:

```bash
aws cloudwatch describe-alarms \
  --alarm-names <alarm-name>
```

I would verify whether it is:

```text
OK
ALARM
INSUFFICIENT_DATA
```

If it is `ALARM`, I know the metric condition is being met.

If the alarm is `OK`, I would investigate the metric or threshold.

If it is `INSUFFICIENT_DATA`, I would investigate why CloudWatch isn't receiving the expected metric.

---

### 4. Check the scaling policy

Next, I would verify the scaling policy attached to the ASG:

```bash
aws autoscaling describe-policies \
  --auto-scaling-group-name <asg-name>
```

I would check:

- Policy type
- Scaling adjustment
- Target value if using target tracking
- Cooldown
- Warm-up period
- Whether the policy is actually associated with the correct ASG

For example, with target tracking:

```text
Desired CPU = 60%
```

or:

```text
RequestCountPerTarget = 100
```

I would confirm the configured target actually matches the application's expected capacity.

---

### 5. Check ASG Activity History

This is one of the most important checks.

I would run:

```bash
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name <asg-name>
```

This tells me whether Auto Scaling actually attempted to launch instances and, if it failed, **why**.

For example, I might see:

```text
Launching a new EC2 instance
Failed: InsufficientInstanceCapacity
```

or:

```text
Failed: Invalid IAM instance profile
```

or:

```text
Failed: Launch Template version does not exist
```

or:

```text
Failed: Insufficient free IP addresses
```

This immediately narrows down the problem.

---

### 6. Check Launch Template

If Auto Scaling is attempting to launch instances but they aren't coming up, I would check the Launch Template:

```bash
aws ec2 describe-launch-template-versions \
  --launch-template-id <launch-template-id>
```

I would verify:

- AMI ID
- Instance type
- Security Groups
- IAM instance profile
- User data
- EBS configuration
- Key pair if required
- Correct Launch Template version

A common real-world issue is that someone updated the Launch Template but the ASG is still using an **older version**.

---

### 7. Check EC2 capacity and Availability Zones

If the ASG wants to launch an instance but EC2 cannot provision it, I would check for capacity problems.

For example:

```text
InsufficientInstanceCapacity
```

could mean AWS doesn't currently have enough capacity for that instance type in that AZ.

I would check:

- Availability Zones
- Instance type availability
- Subnet capacity
- EC2 service limits
- Regional capacity

If appropriate, I could configure multiple AZs or use multiple instance types through an **EC2 Auto Scaling Mixed Instances Policy**.

---

### 8. Check subnet IP availability

This is a common issue that can be missed.

I would check:

```bash
aws ec2 describe-subnets \
  --subnet-ids <subnet-id>
```

and look at:

```text
AvailableIpAddressCount
```

If the subnet has no available private IP addresses, the ASG cannot launch additional instances even though the scaling policy is working correctly.

The solution would be to expand the subnet/VPC CIDR or use additional subnets with available IP capacity.

---

### 9. Check IAM permissions

I would verify that the ASG/EC2 configuration has the required IAM permissions.

For example, if the instance profile or related configuration is incorrect, instance launch can fail.

I would check:

```bash
aws iam get-instance-profile \
  --instance-profile-name <profile-name>
```

I would also check CloudTrail if I suspect an IAM or API authorization failure.

---

### 10. Check whether instances are launching but immediately terminating

Another important scenario is:

```text
Scaling triggered
       ↓
EC2 launches
       ↓
Health check fails
       ↓
ASG terminates instance
```

So I would check:

```bash
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name <asg-name>
```

and the EC2 instance state/history.

I would investigate:

- EC2 status checks
- ELB health checks
- Application startup
- User-data script
- Security Groups
- Target Group health
- Application port
- Health-check path

For example, if the ALB health check is:

```text
HTTP : 8080 /health
```

but the application is actually listening on:

```text
HTTP : 8000
```

the instance may launch successfully but immediately become unhealthy and be replaced.

---

### 11. Check target group registration

If instances launch but users still experience capacity problems, I would check the ALB target group:

```bash
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>
```

I would verify that new instances are:

```text
healthy
```

rather than:

```text
unhealthy
```

This helps distinguish between:

> **"ASG isn't launching instances"**

and:

> **"ASG launches instances, but they aren't becoming usable."**

---

### 12. Check scaling timing

Since the question specifically says instances aren't launching **within the required time frame**, I would also investigate scaling delays.

For example:

```text
Metric crosses threshold
        ↓
CloudWatch evaluation
        ↓
Alarm changes state
        ↓
Scaling policy executes
        ↓
EC2 launch
        ↓
Instance boot
        ↓
Application startup
        ↓
Health check
        ↓
Target becomes healthy
```

There can be delays at several points.

I would review:

- CloudWatch evaluation periods
- ASG instance warm-up
- Cooldown
- Application startup time
- User-data execution time
- AMI boot time
- ALB health-check interval/threshold
- Container startup time

If the instance takes 5 minutes to become healthy, launching it after the load spike may already be too late.

In that case, I might adjust the **scaling threshold, evaluation period, instance warm-up, or minimum capacity** based on the application's actual startup characteristics.

---

### 13. Check AWS service quotas and account limits

I would also check whether we are hitting an AWS limit.

For example:

- EC2 instance limits
- vCPU limits
- EBS limits
- Elastic IP limits
- ASG limits

If the ASG activity history shows a quota-related failure, I would request an appropriate quota increase or redesign the capacity configuration.

---

### 14. Resolution

Once I identify the failure point, I would make the appropriate fix.

For example:

| Problem | Resolution |
|---|---|
| CloudWatch metric wrong | Correct metric/dimensions |
| Alarm threshold incorrect | Adjust threshold/evaluation |
| Scaling policy incorrect | Correct policy |
| ASG max capacity reached | Increase max capacity if justified |
| Launch Template wrong | Fix and use correct version |
| Subnet IP exhaustion | Add/expand subnet capacity |
| EC2 capacity issue | Use additional AZs/instance types |
| IAM issue | Correct required permissions |
| User-data failure | Fix bootstrap script |
| Health check failure | Fix app/port/path/SG |
| Slow application startup | Optimize startup/warm-up/scaling strategy |
| AWS quota reached | Request quota increase |
| Scaling too late | Tune thresholds and predictive/target tracking strategy |

### How I would answer in the interview

> "If Auto Scaling is not launching instances within the required time, I would first identify where the scaling flow is breaking. I would check the ASG's desired, current, minimum and maximum capacity using `describe-auto-scaling-groups`. Then I would verify the CloudWatch metric and alarm to make sure the scaling condition was actually triggered.
>
> If the alarm is in ALARM state, I would check the scaling policy and then immediately check ASG activity history using `describe-scaling-activities`, because that usually tells me whether the launch was attempted and why it failed.
>
> If the ASG attempted to launch an instance, I would investigate the Launch Template, AMI, IAM instance profile, subnet IP availability, Availability Zone capacity, and AWS service quotas. If the instance launches but doesn't become usable, I would check EC2 status checks, user-data, application startup and ALB target health.
>
> Since the requirement is specifically about launching within a certain time frame, I would also look at CloudWatch evaluation periods, instance warm-up, cooldown, application startup time and health-check configuration. After identifying the bottleneck, I would make the minimum required configuration change, test scaling under load, and verify that the new instance becomes healthy within the required SLA."
