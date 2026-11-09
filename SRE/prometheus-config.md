In our environment, we use **Prometheus for monitoring application and infrastructure metrics, and Grafana for visualization and dashboards.**

Prometheus follows a **pull-based monitoring approach**, where it periodically scrapes metrics from configured targets over HTTP.

For application monitoring, we work with developers to expose application metrics through a `/metrics` endpoint using Prometheus client libraries. For example, in Java applications, we use Spring Boot Actuator along with Micrometer to expose metrics.

For infrastructure monitoring, we install **Node Exporter** on EC2 instances to collect system-level metrics such as CPU, memory, disk and network utilization.

For container monitoring, we use **cAdvisor**, and in Kubernetes environments, we use components like kube-state-metrics and Kubelet to collect cluster and container-level metrics.

We configure all these targets in the `prometheus.yml` file, where we define the job names, target endpoints and scrape intervals. For example, we generally configure a 15-second scrape interval.

Prometheus periodically sends HTTP GET requests to these endpoints, collects the metrics and stores them in its time-series database.

Finally, we integrate Prometheus with Grafana as a data source and create dashboards to monitor CPU utilization, memory consumption, API request rates, error rates and response latency.

We also configure alerts for critical conditions, such as high CPU utilization, increased application errors and Kubernetes pod failures, so that the on-call engineer gets notified and can take immediate action.
