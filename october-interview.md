## your application running on EC2 experience traffics spike only during business hours. how would you optimize cost and performance
“Since traffic spikes only during business hours, I’d implement an Auto Scaling Group behind an Application Load Balancer.
I’d configure scheduled scaling policies to scale up before business hours and scale down after hours to reduce costs.
For baseline capacity, I’d use Reserved Instances or Savings Plans, and for burst capacity, I’d mix in Spot Instances.
Additionally, I’d enable CloudWatch monitoring and Compute Optimizer for ongoing right-sizing.
If the workload supports it, I’d even consider migrating to Fargate or Lambda for better elasticity and pay-per-use efficiency.”
I’d define a launch template, attach it to an ASG, and configure CloudWatch alarms to trigger scaling policies based on CPU or request count.
