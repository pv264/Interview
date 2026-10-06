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
