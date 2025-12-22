## 1 How to make an ec2-insatnce private?
To make an EC2 instance private, I launch it in a private subnet that has no route to an Internet Gateway and ensure that no public or Elastic IP is assigned. I restrict the security group to allow access only from internal sources like a Bastion Host, Load Balancer, or VPC CIDR. If the instance needs outbound internet access, I configure a NAT Gateway in a public subnet. For secure access, I prefer AWS Systems Manager instead of SSH.

## 2 What is NAT gateway?
A NAT Gateway allows instances in a private subnet to access the internet outbound while preventing inbound internet traffic. It is deployed in a public subnet with an Elastic IP and routes private subnet traffic to the internet via an Internet Gateway. This ensures security by keeping private instances inaccessible from the internet while still allowing updates, downloads, and API access.

## 3 I have created an Ec2 instance in a public subnet with internet gateway attached to it, I want to make it as a private instance without modifying the route tables, How can I do
Even if an EC2 instance is launched in a public subnet with an Internet Gateway route, it can be made private without modifying route tables by ensuring it has no public or Elastic IP and by restricting the security group to block all inbound internet traffic. An EC2 instance without a public IP cannot be accessed directly from the internet, regardless of the subnet route configuration. Access can then be done securely using a bastion host or AWS Systems Manager.

## 4 what are the parameters that we should consider while creating an auto-scaling groups
When setting up an Auto Scaling Group, I consider the minimum, desired, and maximum capacity, the launch template configuration, networking across multiple subnets with load balancer integration, health checks and grace periods, suitable scaling policies, termination rules, monitoring using CloudWatch, and cost optimization through Spot or mixed instances. All these factors together ensure the system is scalable, highly available, secure, and cost-efficient.

Auto Scaling Groups can scale based on CloudWatch metrics such as CPU utilization, Application Load Balancer metrics like RequestCountPerTarget and response time, memory utilization using custom metrics, network throughput, queue depth for SQS-based workloads, application-level custom metrics, scheduled scaling for predictable traffic, and predictive scaling using historical patterns. The choice of metric depends on the application behavior and workload characteristics.

## 5 Do amazon S3 is a regional or global service?
Amazon S3 is a regional service because each bucket is created in a specific AWS region and data is stored within that region. However, it offers global access over the internet and uses a globally unique bucket namespace, which often leads to the misconception that it is a global service.

## 6 After completing a customer contract, I need to transfer data stored in an S3 bucket from the customer’s AWS account to a different AWS account. What is the recommended way to configure this?

I would use a cross-account IAM role. The customer’s account creates a role with read access to the S3 bucket, and my account assumes that role to copy the data into my own S3 bucket. The destination bucket allows write access to the role. This keeps everything private, secure, and auditable.
If it is continous activity
S3 cross-account replication can be used, but it is typically recommended for continuous or future data replication scenarios. For a one-time transfer after a customer contract ends, a cross-account IAM role with S3 copy or sync is the preferred and simpler approach. Replication also requires versioning and additional configuration, making it less suitable for one-off data transfers.

## 7 What is the default route in the main route table?
By default, a VPC’s main route table includes a local route for the VPC CIDR that allows communication within the VPC. This route is automatically created and cannot be modified, while any internet or external routes must be configured manually.
