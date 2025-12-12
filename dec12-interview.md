## 1.how can we give temporary access to object stored in s3 bucket to an external user by keeping it pvt?
 If we need to give temporary access to an S3 object while keeping the bucket private, the best method is generating a pre-signed URL.
A pre-signed URL is created by someone who already has permission to the object, and it gives short-lived access (for example, 10 minutes or 1 hour) to anyone who has the link.
We don’t modify bucket policies, and external users do not need AWS accounts.
When the URL expires, access is automatically revoked.”
## 2.one of the application is running on AWS account A and it needs to access the s3 bucket in account b ?
To enable cross-account access, we only need to create a role in Account A and then allow that role ARN in the S3 bucket policy of Account B. No IAM roles are required in Account B.


