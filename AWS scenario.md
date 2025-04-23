<b.1 .first question you've been tasked with setting up a small web application on AWS how would you proceed to set up a small web application on AWS? </b>
 Ans: start by launching an ec2 instance which will serve as your web server select an appropriate Amazon machine image also known as Ami like Amazon Linux or Windows server that fits your application requirements
once the instance is running install a web server software like Apache or engine X depending on your application stack next deploy your web application files onto the server for data storage use Amazon RDS to create a relational database that supports your your application ensuring it is configured to communicate securely with your ec2 instance,
setup security groups to Define which ports are open to the internet like HTTP on Port 8 and https on Port 443 to ensure your application is accessible yet secure
          
          
