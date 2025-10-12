## 1.your application running on EC2 experience traffics spike only during business hours. how would you optimize cost and performance
“Since traffic spikes only during business hours, I’d implement an Auto Scaling Group behind an Application Load Balancer.
I’d configure scheduled scaling policies to scale up before business hours and scale down after hours to reduce costs.
For baseline capacity, I’d use Reserved Instances or Savings Plans, and for burst capacity, I’d mix in Spot Instances.
Additionally, I’d enable CloudWatch monitoring and Compute Optimizer for ongoing right-sizing.
If the workload supports it, I’d even consider migrating to Fargate or Lambda for better elasticity and pay-per-use efficiency.”
I’d define a launch template, attach it to an ASG, and configure CloudWatch alarms to trigger scaling policies based on CPU or request count.

## 2.you have deployed your application on EC2 Instance and it has to fetch some images from the internet and its not able to download. what might be the issue
If my EC2 instance can’t download images from the internet, I’ll start by checking its network connectivity.
For an instance in a public subnet, I’ll confirm that the subnet’s route table includes a route to an Internet Gateway (IGW), that the instance has a public IP address, and that both security group and NACL outbound rules allow internet access.
If the instance is in a private subnet, I’ll verify that its route table points to a NAT Gateway located in a public subnet to enable outbound internet traffic.

## 3. Someone accidentally deleted data from S3 bucket how do you restore it.
“If I accidentally deleted data from an S3 bucket, the recovery approach would depend on whether versioning was enabled.
If versioning is enabled, I can easily restore the object by deleting the delete marker or retrieving a previous version from the object’s version history.
If versioning isn’t enabled, I’d check whether S3 replication or AWS Backup was configured and attempt to restore the object from those sources.
To avoid such incidents in the future, I’d enable S3 Versioning, implement MFA Delete or Object Lock for additional protection, and set up replication or backup policies to ensure data durability and quick recovery.”

## 4 How do you connect your on-prem data center to AWS?
To connect my on-premises data center with AWS, I would typically choose between AWS Site-to-Site VPN or AWS Direct Connect, based on performance and latency requirements.
For a fast and secure setup, I’d configure an IPSec VPN tunnel between the on-premises router (Customer Gateway) and an AWS Virtual Private Gateway attached to the VPC.

For larger-scale or latency-sensitive workloads, I’d prefer AWS Direct Connect, which provides a dedicated private network connection to AWS for more consistent performance.
In a production environment, I’d usually combine Direct Connect with a VPN — using Direct Connect as the primary link and VPN as the backup to ensure high availability.

If multiple VPCs or on-premises locations are involved, I’d use an AWS Transit Gateway to centrally manage and simplify all hybrid connectivity.”

## 5 I have 2 Ec2 instances running in different vpcs. Both the applications rinning on it need to communicate with each other, but they are not able to communicate how do you fix that
Step 1: Establish a Network Path Between the VPCs
First, we need to create a network route between the two VPCs. I have two primary options for this:

VPC Peering: This is the simplest solution for connecting just two VPCs. A VPC peering connection is a direct, one-to-one network link between them. It makes them behave as if they are on the same private network. I would create a peering request from one VPC and accept it in the other.

AWS Transit Gateway: If the organization plans to connect multiple VPCs (more than two or three), a Transit Gateway is a much more scalable solution. It acts as a central hub or a cloud router. I would attach both VPCs to the Transit Gateway, and it would handle the routing between them. This avoids the complex "mesh" of peering connections that becomes hard to manage at scale.

For this specific problem with just two instances, VPC Peering is the most direct and cost-effective fix.

Step 2: Update the Route Tables
Creating the connection isn't enough; we have to tell the VPCs how to find each other.

In VPC A, I would update its route table to send all traffic destined for VPC B's IP address range (CIDR block) to the VPC peering connection or the Transit Gateway.

Similarly, in VPC B, I would update its route table to send traffic destined for VPC A's CIDR block back through that same connection.

Without this step, the instances won't know how to route the traffic.

## 6 Explain the Architecture of kubernetes on a high level
2. Control Plane Components

The Control Plane is responsible for the cluster’s global decisions (scheduling, scaling, updates) and managing the state.

Component	Role
API Server (kube-apiserver)	Exposes the Kubernetes API. All interactions with the cluster go through this. Acts as the front-end.
etcd	Distributed key-value store. Stores all cluster data like cluster state, configuration, and secrets. Think of it as Kubernetes’ database.
Controller Manager	Runs various controllers (e.g., node controller, deployment controller) that manage the state of objects and ensure desired vs actual state alignment.
Scheduler	Assigns workloads (pods) to nodes based on resources, policies, affinity/anti-affinity, etc.
3. Worker Node Components

Worker nodes host the workloads (your containers) and report back to the control plane.

Component	Role
kubelet	Agent running on every node. Ensures containers described in PodSpecs are running. Reports node status to the API server.
kube-proxy	Manages networking rules, load-balancing, and service discovery within the cluster.
Container Runtime	Software responsible for running containers (e.g., Docker, containerd).
Pods	The smallest deployable units. Can contain one or more containers.

