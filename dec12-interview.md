## 1.how can we give temporary access to object stored in s3 bucket to an external user by keeping it pvt?
 <p>If we need to give temporary access to an S3 object while keeping the bucket private, the best method is generating a pre-signed URL.
A pre-signed URL is created by someone who already has permission to the object, and it gives short-lived access (for example, 10 minutes or 1 hour) to anyone who has the link.
We don’t modify bucket policies, and external users do not need AWS accounts.
When the URL expires, access is automatically revoked.”</p>

