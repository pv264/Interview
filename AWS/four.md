# EC2 Intermittent Unresponsiveness — Troubleshooting Approach

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
