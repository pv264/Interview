## 1.how can we give temporary access to object stored in s3 bucket to an external user by keeping it pvt?
 If we need to give temporary access to an S3 object while keeping the bucket private, the best method is generating a pre-signed URL.
A pre-signed URL is created by someone who already has permission to the object, and it gives short-lived access (for example, 10 minutes or 1 hour) to anyone who has the link.
We don’t modify bucket policies, and external users do not need AWS accounts.
When the URL expires, access is automatically revoked.”
## 2.one of the application is running on AWS account A and it needs to access the s3 bucket in account b ?
To enable cross-account access, we only need to create a role in Account A and then allow that role ARN in the S3 bucket policy of Account B. No IAM roles are required in Account B.
## 3. I have two AWS buckets in 2 diff regions. In one bucket static website is hosted and in second bucket images are stored.the static website has to fetch the images what kind of setup is required
n this scenario, where a static website hosted in one S3 bucket needs to fetch images from another S3 bucket in a different region, the recommended production approach is to use CloudFront in front of the S3 buckets.
CloudFront acts as a global CDN, improving performance by caching content closer to users, reducing cross-region latency, and providing HTTPS and security features. When both the website and images are served through CloudFront, it also avoids most browser-side CORS issues.
If CloudFront is not used, then the minimum required setup is configuring CORS on the image bucket and allowing public read access for the objects, because static websites run in the browser and cannot use IAM roles. Without proper CORS configuration, the browser will block cross-origin requests.
So in summary, CloudFront is the best practice for production, while CORS is mandatory for a direct S3-to-S3 static website setup.”**

## 4. you have a lambda function assosciated with vpc in AWS account A. This has to connect with one application which is running on on ec2 in AWS account B. How will you establish the communication

Since the Lambda function is running inside a VPC in Account A and it needs to communicate with an EC2 instance in Account B, we must establish network-level connectivity between the two VPCs.

The most common and recommended approach is to use VPC Peering or AWS Transit Gateway, depending on scale.

We create a VPC peering connection between Account A’s VPC and Account B’s VPC, update the route tables in both VPCs to route traffic to each other, and configure security groups and NACLs to allow the required ports. Once this is done, the Lambda function can access the EC2 instance using its private IP address, without exposing the EC2 instance to the internet.

For larger or multi-VPC environments, we would use Transit Gateway instead of peering. If private connectivity is not required, an alternative is exposing the EC2 application through an ALB or NLB with public access, but private connectivity is always preferred for security.”

## 5. I want specific pods to be scheduled on specific nodes, How will you ensure this
To ensure that only specific pods are scheduled on specific nodes, I use taints and tolerations.

First, I taint the node, which tells Kubernetes not to schedule any pods on that node by default. Then, I add a matching toleration to only those pods that are allowed to run on that node.

This way, Kubernetes ensures that only pods with the correct toleration can be scheduled on the tainted node, and all other pods are rejected.”

## 6.How will you establish communication between pods running in two diff name spaces
Pods in different namespaces can communicate by default in Kubernetes because all pods share the same cluster network. Communication is usually done using Services with fully qualified domain names (FQDN). If restrictions are needed, Network Policies are used to control traffic.”

## 7. What is the advantage of Secrets over configmaos in kubernetes
The main advantage of Secrets over ConfigMaps is security. Secrets are designed to store sensitive information like passwords and tokens, whereas ConfigMaps are meant for non-sensitive configuration. Secrets support RBAC restrictions, encryption at rest in etcd, and integration with external secret managers. ConfigMaps store data in plain text and do not provide these security features.”
## 8. Can we delete a docker image when the container is running with that image
Docker does not allow deleting an image if there are running or stopped containers using that image. The image is still referenced by the container, so Docker prevents its removal.”
## 9. how will you troubleshoot 401 and 403 error codes. and what are these errors
“401 means Unauthorized, where authentication is missing or invalid, such as an expired token or wrong credentials.

403 means Forbidden, where authentication is successful but the user does not have permission to access the resource.

To troubleshoot 401, I verify authentication headers, tokens, credential validity, and the auth service.
To troubleshoot 403, I check IAM or application permissions, resource policies, explicit denies, network rules, and logs like CloudTrail.
In AWS, 401 usually indicates credential issues, while 403 indicates permission or policy-related issues.”
In Kubernetes, a 401 error means authentication to the API server failed, usually due to an invalid or expired token, wrong kubeconfig, or incorrect ServiceAccount.
A 403 error means authentication succeeded, but RBAC denied the action due to missing roles or role bindings.

To troubleshoot 401, I check kubeconfig, tokens, ServiceAccounts, and cluster authentication.
## 10. what is multi-branch pipeline
A multi-branch pipeline is a CI/CD pipeline that automatically detects all branches in a repository and creates a separate pipeline for each branch, allowing independent build, test, and deployment workflows.”
## 11. How can you save the cost on AWS RDS Instances for non production environment?
To save cost on RDS in non-production environments, I use smaller burstable instances, disable Multi-AZ, reduce backup retention, and delete unused snapshots. The biggest cost saving comes from stopping the RDS instance when it’s not in use and scheduling start/stop using automation. Where applicable, I also use Graviton instances or Aurora Serverless to further reduce cost.”


