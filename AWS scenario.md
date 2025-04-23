<b>.<p>1 .first question you've been tasked with setting up a small web application on AWS how would you proceed to set up a small web application on AWS? </b></p>
 Ans: start by launching an ec2 instance which will serve as your web server select an appropriate Amazon machine image also known as Ami like Amazon Linux or Windows server that fits your application requirements
once the instance is running install a web server software like Apache or engine X depending on your application stack next deploy your web application files onto the server for data storage use Amazon RDS to create a relational database that supports your your application ensuring it is configured to communicate securely with your ec2 instance,
setup security groups to Define which ports are open to the internet like HTTP on Port 8 and https on Port 443 to ensure your application is accessible yet secure.

<b>.<p>2. you need to store images and documents securely on AWS which service would you use and what steps would you follow for securely storing images and documents?</b></p>.
 Ans: Amazon S3 is the ideal Choice due to its durability and scalability begin by creating a new S3 bucket in your preferred AWS region enable versioning on the bucket to keep an immutable history of your objects and to facilitate easy recovery from accidental deletions or overrides for enhanced security activate ser side encryption with Amazon S3 manage Keys which is the SS S3 to encrypt your store data set up an IM policy that explicitly grants access to the S3 resources only to authorize users or applications ensuring that your data is protected against unauthorized access.

<b>.<p>3. 3. your team wants to ensure all their AWS resources are only accessible within office premises what steps would you take to secure access to restrict AWS resource access to office premises?</b></p>
  Ans: you can use a combination of network restrictions and IM am policies first determine your office IP range then you want to configure a VPC with an attached internet gateway and set up network access control lists on knackles or security groups to allow traffic only from your office IP range for additional security defy your IM am policies to include a condition that restricts access to the same IP range this ensures that even if credentials are compromised they cannot be used outside the specified IP range.
 <b>.<p>4 A startup wants to launch a coste effective static website quickly on AWS what services and steps would you recommend?</b></p>
 To launch a static website cost effectively utilize Amazon S3 and R 53 start by uploading the website static files you know the HTML CSS JavaScript files and images to and S3 buckets configure the bucket for 
  static website hosting and set permissions to make the website publicly accessible for a custom domain register the domain using Amazon Route 53 or configure Route 53 to manage an existing domain's DNS settings then you want to point the domain to your S3 bucket using a DNS record this setup not only ensures a cost effective solution but also leverages aws's scalability and reliability.
  
  <b>.<p>5you need to analyze access patterns and usage of your AWS environment which tools would you use and why would you use them to analyze access patterns and usage</b></p>
   Amazon Cloud watch is an excellent tool it provides detailed insight into resource utilization and systemwide operational are Health you want to set up monitoring for key metrics across your AWS services like CPU utilization Network traffic and dis IO operations Amazon cloudwatch allows you to create dashboards to visualize usage patterns and set alarms to notify you when thresholds are exceeded this information helps to optimize resource allocation improve your application performance and reduce costs by adjusting capacity based on actual usage 
          
          
         
                
          
         
      
          
