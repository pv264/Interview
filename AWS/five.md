# RDS Performance Troubleshooting After AWS Migration

## Question

After migrating the application to AWS, the RDS instance is running very slowly. How would you trouble shoot the performance issue nd identify the root cause

---

If the RDS instance becomes slow after migrating the application to AWS, I would first identify whether the bottleneck is in the **database itself, the application, the network, or the migration configuration**.

I would follow this flow:

**Application → Network → RDS → Queries → Storage → Connections → Configuration**

### 1. First understand what "slow" means

I would first get specific information from the application team:

- Are all database operations slow or only specific queries?
- When did the problem start?
- Is it constant or intermittent?
- Is the entire application slow or only certain APIs?
- Was the application previously running on-premises or on another cloud?
- What was the database engine/version and instance size before migration?
- What changed during the migration?

I would also compare the application response time before and after migration.

This helps determine whether I'm dealing with a database bottleneck or something outside RDS.

---

### 2. Check RDS CloudWatch metrics

My first AWS-level check would be the RDS CloudWatch metrics.

Important metrics include:

```text
CPUUtilization
FreeableMemory
DatabaseConnections
ReadIOPS
WriteIOPS
ReadLatency
WriteLatency
DiskQueueDepth
FreeStorageSpace
NetworkReceiveThroughput
NetworkTransmitThroughput
```

I would look at these metrics specifically during the period when the application is slow.

For example:

```text
CPUUtilization       → 95%
FreeableMemory       → Very low
DiskQueueDepth       → High
ReadLatency          → High
DatabaseConnections  → Near limit
```

This would immediately indicate that RDS is under resource pressure.

---

### 3. Check CPU utilization

If CPU is consistently high:

```text
CPUUtilization > 80–90%
```

I would determine what is consuming the CPU rather than simply resizing the instance.

I would look at database performance insights and slow queries.

For example, a query doing a large table scan could consume significant CPU.

The resolution might be:

- Add/modify indexes
- Optimize queries
- Update statistics
- Fix inefficient joins
- Reduce unnecessary queries
- Increase RDS instance capacity if the workload genuinely requires it

---

### 4. Check memory pressure

I would check:

```text
FreeableMemory
```

If memory is consistently low, the database may be under memory pressure.

I would investigate:

- Large queries
- Excessive connections
- Buffer/cache pressure
- Instance sizing
- Database configuration

I would also check swap-related behavior where applicable.

If the workload genuinely requires more memory, I would consider moving to a larger RDS instance.

---

### 5. Check storage and I/O performance

This is especially important if queries are waiting on disk.

I would check:

```text
ReadIOPS
WriteIOPS
ReadLatency
WriteLatency
DiskQueueDepth
FreeStorageSpace
```

For example:

```text
ReadLatency       → High
WriteLatency      → High
DiskQueueDepth    → High
IOPS              → Near provisioned limit
```

This could indicate an EBS/storage bottleneck.

I would check what storage type the RDS instance is using, such as:

```text
gp2
gp3
io1/io2
```

If using gp3, I would check whether the provisioned IOPS and throughput are sufficient.

If using gp2, I would investigate whether the workload is exhausting burst performance.

Depending on the workload, I might increase provisioned IOPS/throughput or move to an appropriate storage configuration.

---

### 6. Check Database Connections

I would check:

```text
DatabaseConnections
```

If the number of connections is close to the database's maximum:

```text
Application
   |
   +-- Connection 1
   +-- Connection 2
   +-- Connection 3
   ...
   +-- Connection N
```

the application could be waiting for an available database connection.

I would investigate:

- Application connection pool
- Maximum DB connections
- Connection leaks
- Long-running idle connections
- Connection pooling configuration

For example, with PostgreSQL I could check:

```sql
SELECT count(*) FROM pg_stat_activity;
```

and:

```sql
SELECT state, count(*)
FROM pg_stat_activity
GROUP BY state;
```

I would avoid simply increasing `max_connections` because that can create additional memory pressure.

A connection pool such as **PgBouncer** may be appropriate depending on the architecture.

---

### 7. Check Performance Insights

For RDS, I would use **Performance Insights** to identify what the database is spending time on.

I would look at:

- Top SQL
- DB load
- Wait events
- CPU
- I/O waits
- Lock waits
- Connection-related waits

For example, if I see:

```text
DB Load
   |
   +--- CPU
   +--- IO
   +--- Lock
```

and most of the load is caused by a particular SQL query, I would investigate that query rather than immediately scaling RDS.

---

### 8. Investigate slow queries

If the database is PostgreSQL, I could check currently running queries:

```sql
SELECT pid,
       usename,
       state,
       query_start,
       now() - query_start AS duration,
       query
FROM pg_stat_activity
WHERE state <> 'idle'
ORDER BY query_start;
```

For a particular query, I would use:

```sql
EXPLAIN ANALYZE
SELECT ...;
```

I would look for:

- Sequential scans
- Missing indexes
- Large joins
- Excessive rows being processed
- Poor query plans
- Sorting/aggregation overhead

If I find a query performing a sequential scan on millions of rows where an index should be used, I would work with the development/DB team to optimize it.

---

### 9. Check locking/blocking

Sometimes CPU and I/O look normal, but queries are slow because they are **waiting for locks**.

For PostgreSQL, I would investigate active sessions and locks.

For example:

```sql
SELECT pid,
       usename,
       state,
       wait_event_type,
       wait_event,
       query
FROM pg_stat_activity
WHERE state <> 'idle';
```

If I see many sessions waiting on locks, I would identify the blocking transaction and work with the database/application team to resolve it.

---

### 10. Check network connectivity

Because this happened after migration, I would also verify the network path between the application and RDS.

I would check:

```text
Application EC2/EKS
       |
       ↓
VPC
       |
       ↓
Subnet
       |
       ↓
RDS
```

I would verify:

- Same or appropriate AZ placement
- Security Groups
- Route tables
- Network ACLs
- DNS resolution
- Network latency
- Cross-AZ traffic if applicable

From the application server I could check:

```bash
nslookup <rds-endpoint>
```

and:

```bash
nc -vz <rds-endpoint> 5432
```

For PostgreSQL, I could also test connection timing:

```bash
time psql -h <rds-endpoint> -U <user> -d <database>
```

If the database query itself is fast but establishing connections takes significant time, I would investigate network/DNS/connection-pooling issues.

---

### 11. Check migration differences

Since the problem started after migration, I would compare the old and new environments.

I would compare:

```text
Database engine/version
Instance size
CPU
Memory
Storage type
IOPS
Storage throughput
Database parameters
Indexes
Statistics
Extensions
Connection pool
Network latency
Query plans
```

One important possibility is that the migration changed the database execution plan.

For example:

```text
Before migration:
Index Scan → Fast

After migration:
Sequential Scan → Slow
```

This can happen because statistics, indexes, database configuration, or data distribution differ.

I would therefore verify indexes and update statistics where appropriate.

For PostgreSQL, for example:

```sql
ANALYZE;
```

I would do this carefully and according to the database team's operational procedures.

---

### 12. Check database logs

I would also review the RDS logs for:

- Slow queries
- Connection errors
- Deadlocks
- Authentication problems
- Checkpoint activity
- Database errors
- Storage-related warnings

I would enable or use slow-query logging where appropriate, rather than enabling verbose logging blindly on a production database.

---

### 13. Check RDS configuration

I would review:

- DB instance class
- Storage type
- Provisioned IOPS
- Parameter group
- Option group where applicable
- Multi-AZ configuration
- Maintenance events
- Pending modifications
- Engine version

I would also check whether the RDS instance is simply undersized compared with the workload.

---

### 14. Identify the actual root cause

For example, suppose I find:

```text
CPU                  → 40%
Memory               → Normal
Connections          → Normal
DiskQueueDepth       → High
ReadLatency          → High
Top SQL              → Large SELECT
Query Plan            → Sequential Scan
```

Then I would conclude:

> The primary issue is not insufficient CPU or memory. The application is generating an inefficient query that is performing a large sequential scan, resulting in high I/O latency and queueing.

I would optimize the query/add the appropriate index and then monitor the RDS metrics again.

Another example:

```text
CPUUtilization       → 40%
FreeableMemory       → Normal
ReadLatency          → Normal
DatabaseConnections  → At maximum
```

Then the root cause is likely **connection exhaustion**, not an undersized RDS instance.

---

### 15. Validate after the fix

After making the change, I would monitor:

```text
CPU
Memory
IOPS
Latency
DiskQueueDepth
Connections
DB Load
Application latency
Error rate
```

I would compare these metrics against the baseline from before the incident.

I would also confirm with the application team that API response times have returned to normal.

### How I would explain it in the interview

> "Since the RDS performance issue started after migration to AWS, I would first establish whether the bottleneck is database, storage, network, connection-related, or query-related. I would start with CloudWatch metrics such as CPUUtilization, FreeableMemory, DatabaseConnections, Read/Write IOPS, Read/Write Latency, DiskQueueDepth and FreeStorageSpace.
>
> Then I would use RDS Performance Insights to identify the top SQL statements and database wait events. If I find a slow query, I would analyze it using the database's query-analysis tools such as `EXPLAIN ANALYZE` and check for missing indexes, sequential scans, inefficient joins or lock contention.
>
> I would also check database connections and connection-pool configuration, because connection exhaustion can make an otherwise healthy database appear slow. Since this is a post-migration issue, I would compare the old and new database instance size, storage configuration, IOPS, database parameters, indexes, statistics, query plans and network latency.
>
> If the bottleneck is storage, I would tune IOPS or throughput. If it's a query, I would optimize the query or indexes. If it's connection exhaustion, I would fix the connection pool rather than blindly increasing max connections. If the workload genuinely exceeds the current instance capacity, then I would scale the RDS instance.
>
> Finally, I would validate the fix by comparing database latency, wait events, connections and application response time against the previous baseline and continue monitoring to make sure the issue doesn't recur."


# Transit Gateway vs VPC Peering

If I need to connect two VPCs, I would generally consider **VPC Peering**. It provides a direct private network connection between the two VPCs.

For example, if I have an application in one VPC and a shared service in another VPC, and they need to communicate with each other, I can create a VPC peering connection and add the appropriate routes in both VPCs.

I would prefer VPC Peering when the environment is relatively small and the connectivity requirement is mainly **point-to-point**.

However, VPC Peering becomes difficult to manage as the number of VPCs increases because each VPC needs individual peering connections. Also, VPC Peering is **not transitive**.

For example:

```text
VPC-A → VPC-B → VPC-C
```

VPC-A cannot automatically communicate with VPC-C through VPC-B.

If I have a larger AWS environment with multiple VPCs, multiple AWS accounts, or hybrid connectivity with an on-premises data center, I would use **AWS Transit Gateway**.

Transit Gateway acts as a centralized networking hub:

```text
Application VPC →\
Development VPC → **Transit Gateway** → On-Premises\
Security VPC →
```

Instead of creating many individual peering connections, each VPC connects to the Transit Gateway and routing can be managed centrally.

For example, if an organization has 20 or 30 VPCs across multiple AWS accounts, I would prefer Transit Gateway because it simplifies routing and network management. It can also integrate with **Site-to-Site VPN and Direct Connect** for hybrid connectivity.

So my decision would be:

- **Two or a few VPCs with simple point-to-point connectivity → VPC Peering**
- **Many VPCs/accounts or centralized/hybrid networking → Transit Gateway**

I wouldn't say Transit Gateway is always better. I would choose based on the **number of VPCs, connectivity pattern, scalability, and network management requirements**.
