# Architecting a Highly Available & Fault-Tolerant Application on AWS

**Core Principle:** Design the system by removing all single points of failure and distributing components across multiple Availability Zones (AZs).

## 1. Network & Entry Point
* **Route 53:** Use Route 53 with **Health Checks** to route traffic only to healthy endpoints.
* **Load Balancing:** Traffic flows through an **Application Load Balancer (ALB)** deployed across multiple AZs, which distributes requests and continuously performs health checks on backend targets.

## 2. Compute Layer
* **Resilience:** Use **EC2 Auto Scaling Groups (ASG)** or container services like **ECS/EKS**.
* **Distribution:** Instances/Pods are spread across at least **two or three AZs**.
* **Automation:** Auto Scaling ensures failed instances are automatically replaced (Self-Healing) and the system scales out/in based on traffic (Elasticity).

## 3. Data Layer
* **Relational DB:** Use **Amazon RDS** or **Aurora** with **Multi-AZ enabled**. This provides a synchronous standby replica for automatic failover in case of a primary failure.
* **NoSQL:** For highly scalable workloads, use **DynamoDB** (which is multi-AZ by default).
* **Caching:** Add **Amazon ElastiCache** (Redis/Memcached) to cache frequent queries, reducing database load and improving latency.

## 4. Storage & Assets
* **Static Content:** Store static assets in **Amazon S3**, which is inherently durable and highly available.

## 5. Monitoring & Operations
* **Observability:** Use **Amazon CloudWatch** for monitoring metrics, setting alarms, and triggering automated scaling actions.

## 6. Disaster Recovery (DR)
* **Regional Failover:** Extend the design to **Multiple Regions** using Route 53 failover routing or Active-Active routing.
* **Data Replication:** Enable **Cross-Region Replication (CRR)** for S3 and Global Tables/Read Replicas for databases.

**Summary:** This architecture ensures high availability at the AZ level and fault tolerance even during instance or regional failures.
