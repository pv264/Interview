# Application and Infrastructure Monitoring – Prometheus, Grafana and Alertmanager

## 1. Interview Question

**How do you configure metrics and alerts for application and infrastructure-level monitoring?**

### Interview-Ready Answer

In our environment, we implement monitoring at two levels: application-level monitoring and infrastructure-level monitoring.

We primarily use Prometheus for metrics collection, Grafana for visualization, and Alertmanager for alert notifications.

### 1. Application-Level Monitoring

At the application level, we monitor metrics such as:

- Request count and request rate.
- Application response time and latency.
- HTTP 4xx and 5xx errors.
- JVM memory and thread utilization.
- Database connection pool utilization.

For Java Spring Boot applications, developers integrate Spring Boot Actuator and Micrometer to expose application metrics through the `/actuator/prometheus` endpoint.

We configure the application metrics settings in the `application.yml` file and add the required dependencies in `pom.xml`.

We configure Prometheus to scrape this endpoint at regular intervals, typically every 15 seconds.

For example, if the application error rate exceeds 5% for five minutes or the P95 response time exceeds two seconds, we configure Prometheus alert rules to detect these issues.

### 2. Infrastructure-Level Monitoring

At the infrastructure level, we monitor EC2 instances, Docker containers, CPU, memory, disk and network utilization.

We use:

- **Node Exporter:** Collects Linux server metrics such as CPU, memory, disk and network utilization.
- **cAdvisor:** Collects Docker container metrics such as CPU usage, memory consumption and container resource utilization.
- **AWS CloudWatch:** Monitors AWS services such as EC2, ALB, RDS and Auto Scaling.

We configure Node Exporter and cAdvisor as monitoring targets in the Prometheus configuration file.

For example, we configure alerts when CPU utilization exceeds 85%, memory utilization exceeds 90%, or disk space becomes critically low.

### 3. Prometheus Configuration

We configure all application and infrastructure monitoring targets in the `prometheus.yml` file.

We define separate scrape jobs for:
- Spring Boot application metrics.
- Node Exporter metrics.
- cAdvisor container metrics.

We also configure the scrape interval, which determines how frequently Prometheus collects metrics.

### 4. Alert Configuration

We define alert rules in a separate `alerts.yml` file using PromQL expressions.

For example:
- CPU utilization above 85% for five minutes.
- Memory utilization above 90%.
- Application error rate above 5%.
- Application response time above two seconds.

We configure Alertmanager integration in `prometheus.yml` and configure notification destinations such as Slack or email in `alertmanager.yml`.

Whenever an alert condition is satisfied, Prometheus forwards the alert to Alertmanager, which sends notifications to the SRE team.

### 5. Grafana Dashboards

We integrate Prometheus with Grafana and configure Prometheus as a data source.

We create separate dashboards for application and infrastructure monitoring.

The application dashboard displays request rate, response time, error rate and JVM metrics.

The infrastructure dashboard displays CPU, memory, disk, network and container utilization.

### 6. Real-Time Production Incident Example

Suppose users report that our application is responding slowly.

First, I check the Grafana dashboard to identify whether the issue is related to application performance or infrastructure resources.

If EC2 CPU and memory utilization are normal, I investigate application logs, database query latency and connection pool utilization.

For example, if database connections are exhausted due to slow queries, I coordinate with the development and database teams to identify and resolve the issue.

After implementing the fix, I verify that application response time and error rates have returned to normal.

Overall, our objective is to proactively identify issues, reduce MTTR (Mean Time to Recovery) and maintain application availability and reliability.

---

# 2. Monitoring Architecture

We use the following monitoring architecture:

```text
             Application + Infrastructure
                         |
              Metrics Collection
                         |
           +-------------+-------------+
           |             |             |
      Application    Node Exporter   cAdvisor
       Metrics        EC2 Metrics   Container Metrics
           |             |             |
           +-------------+-------------+
                         |
                     Prometheus
                         |
                  +------+------+
                  |             |
               Grafana      Alertmanager
              Dashboards    Notifications
                                |
                         Slack / Email
```

For AWS services, we additionally use CloudWatch to collect metrics from EC2, ALB, RDS and other AWS resources.

---

# 3. Project Directory Structure

We maintain the monitoring configuration files in a dedicated directory.

```text
monitoring/
│
├── docker-compose.yml
│
├── prometheus/
│   ├── prometheus.yml
│   └── alerts.yml
│
└── alertmanager/
    └── alertmanager.yml
```

### Purpose of Each File

| File | Purpose |
|---|---|
| pom.xml | Add Actuator and Micrometer dependencies |
| application.yml | Enable application metrics endpoint |
| prometheus.yml | Configure Prometheus scrape targets |
| alerts.yml | Define application and infrastructure alert rules |
| alertmanager.yml | Configure notification destinations |
| docker-compose.yml | Deploy monitoring components |

---

# 4. Application-Level Monitoring – Sample Code

Let's assume we have a Java Spring Boot payment application running inside a Docker container.

## Step 1: Add Dependencies in pom.xml

We add Spring Boot Actuator and Micrometer Prometheus Registry dependencies.

```xml
<dependencies>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>

    <dependency>
        <groupId>io.micrometer</groupId>
        <artifactId>micrometer-registry-prometheus</artifactId>
    </dependency>

</dependencies>
```

**Explanation:**

- Spring Boot Actuator exposes application health and monitoring endpoints.
- Micrometer collects application metrics and exposes them in Prometheus-compatible format.

## Step 2: Configure application.yml

```yaml
server:
  port: 8080

management:
  endpoints:
    web:
      exposure:
        include: health,prometheus

  endpoint:
    health:
      show-details: always

  metrics:
    tags:
      application: payment-service
      environment: production
```

The application exposes metrics through:

```text
http://localhost:8080/actuator/prometheus
```

Example metrics:

```text
http_server_requests_seconds_count
http_server_requests_seconds_sum
jvm_memory_used_bytes
jvm_threads_live_threads
```

## Step 3: Create Custom Application Metrics

Suppose developers want to monitor successful and failed payment transactions.

They can implement custom metrics using Micrometer.

```java
@RestController
public class PaymentController {

    private final Counter paymentSuccess;
    private final Counter paymentFailure;

    public PaymentController(MeterRegistry registry) {

        paymentSuccess = Counter.builder("payment_success_total")
                .description("Successful payments")
                .register(registry);

        paymentFailure = Counter.builder("payment_failure_total")
                .description("Failed payments")
                .register(registry);
    }

    @PostMapping("/payment")
    public String processPayment(
            @RequestParam boolean success) {

        if (success) {
            paymentSuccess.increment();
            return "Payment successful";
        }

        paymentFailure.increment();
        return "Payment failed";
    }
}
```

**Explanation:**

Whenever a payment succeeds, the success counter increases by one.

Whenever a payment fails, the failure counter increases by one.

These custom metrics are exposed through the Prometheus endpoint.

This is how developers instrument application-specific metrics.

---

# 5. Infrastructure-Level Monitoring – Sample Code

For infrastructure monitoring, we use Node Exporter and cAdvisor.

## Step 1: Run Node Exporter

Node Exporter collects Linux server metrics such as CPU, memory, disk and network utilization.

We can run it using Docker.

```bash
docker run -d \
  --name node-exporter \
  --restart unless-stopped \
  -p 9100:9100 \
  --pid="host" \
  -v "/:/host:ro,rslave" \
  prom/node-exporter:latest \
  --path.rootfs=/host
```

Node Exporter exposes metrics at:

```text
http://localhost:9100/metrics
```

Example metrics:

```text
node_cpu_seconds_total
node_memory_MemTotal_bytes
node_memory_MemAvailable_bytes
node_filesystem_avail_bytes
node_network_receive_bytes_total
```

## Step 2: Run cAdvisor

cAdvisor collects Docker container-level metrics.

```bash
docker run -d \
  --name cadvisor \
  --restart unless-stopped \
  -p 8081:8080 \
  --privileged \
  -v /:/rootfs:ro \
  -v /var/run:/var/run:ro \
  -v /sys:/sys:ro \
  -v /var/lib/docker:/var/lib/docker:ro \
  -v /dev/disk:/dev/disk:ro \
  gcr.io/cadvisor/cadvisor:latest
```

cAdvisor exposes metrics at:

```text
http://localhost:8081/metrics
```

Example metrics:

```text
container_cpu_usage_seconds_total
container_memory_usage_bytes
container_network_receive_bytes_total
```

### Difference Between Node Exporter and cAdvisor

| Node Exporter | cAdvisor |
|---|---|
| Monitors EC2/Linux host | Monitors Docker containers |
| CPU utilization of the server | CPU usage of containers |
| Server memory utilization | Container memory usage |
| Disk and network metrics | Container network and filesystem metrics |

---

# 6. Prometheus Configuration – prometheus.yml

Now we need to configure Prometheus to collect metrics from the application and infrastructure.

We define the configuration in `prometheus.yml`.

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

rule_files:
  - /etc/prometheus/alerts.yml

scrape_configs:

  # Application Monitoring
  - job_name: 'springboot-app'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets:
          - 'payment-app:8080'

  # EC2 Infrastructure Monitoring
  - job_name: 'node-exporter'
    static_configs:
      - targets:
          - 'node-exporter:9100'

  # Docker Container Monitoring
  - job_name: 'cadvisor'
    static_configs:
      - targets:
          - 'cadvisor:8080'
```

### Explanation

| Configuration | Purpose |
|---|---|
| scrape_interval: 15s | Collect metrics every 15 seconds |
| evaluation_interval: 15s | Evaluate alert rules every 15 seconds |
| springboot-app | Collect application metrics |
| node-exporter | Collect EC2/Linux metrics |
| cadvisor | Collect container metrics |
| alertmanager | Forward triggered alerts |

Here, Prometheus uses Docker service names to communicate with the monitoring containers over their shared Docker network.

In production, we can also configure service discovery instead of maintaining static IP addresses.

---

# 7. Prometheus Alert Rules – alerts.yml

Now we configure alerts based on predefined thresholds.

We maintain these rules in a separate `alerts.yml` file.

## A. Application-Level Alerts

### Alert 1: High Application Error Rate

```yaml
groups:
  - name: application-alerts
    rules:

      - alert: HighApplicationErrorRate
        expr: |
          (
            sum(rate(http_server_requests_seconds_count{
              status=~"5.."
            }[5m]))
            /
            clamp_min(
              sum(rate(http_server_requests_seconds_count[5m])),
              0.001
            )
          ) * 100 > 5

        for: 5m

        labels:
          severity: critical

        annotations:
          summary: "High application error rate"
          description: "HTTP 5xx error rate is above 5%."
```

**Explanation:**

If the application's HTTP 5xx error rate exceeds 5% continuously for five minutes, Prometheus triggers an alert.

### Alert 2: High Application Response Time

```yaml
      - alert: HighApplicationLatency
        expr: |
          histogram_quantile(
            0.95,
            sum by (le) (
              rate(http_server_requests_seconds_bucket[5m])
            )
          ) > 2

        for: 5m

        labels:
          severity: warning

        annotations:
          summary: "High application latency"
          description: "P95 response time exceeds 2 seconds."
```

**Explanation:**

If 95th percentile application response time exceeds two seconds for five minutes, Prometheus triggers a warning.

This query requires HTTP request histogram buckets to be enabled and exposed.

### Alert 3: Application Down

```yaml
      - alert: ApplicationDown
        expr: up{job="springboot-app"} == 0

        for: 2m

        labels:
          severity: critical

        annotations:
          summary: "Spring Boot application is unavailable"
```

**Explanation:**

If Prometheus cannot scrape the application endpoint for two minutes, it triggers a critical alert.

## B. Infrastructure-Level Alerts

### Alert 1: High CPU Utilization

```yaml
  - name: infrastructure-alerts
    rules:

      - alert: HighCPUUsage
        expr: |
          100 * (
            1 - avg by(instance) (
              rate(node_cpu_seconds_total{
                mode="idle"
              }[5m])
            )
          ) > 85

        for: 5m

        labels:
          severity: warning

        annotations:
          summary: "High EC2 CPU usage"
          description: "CPU utilization is above 85%."
```

### Alert 2: High Memory Utilization

```yaml
      - alert: HighMemoryUsage
        expr: |
          100 * (
            1 -
            node_memory_MemAvailable_bytes /
            node_memory_MemTotal_bytes
          ) > 90

        for: 5m

        labels:
          severity: critical

        annotations:
          summary: "High EC2 memory utilization"
```

### Alert 3: Low Disk Space

```yaml
      - alert: LowDiskSpace
        expr: |
          100 * (
            node_filesystem_avail_bytes{
              mountpoint="/",
              fstype!~"tmpfs|overlay"
            }
            /
            node_filesystem_size_bytes{
              mountpoint="/",
              fstype!~"tmpfs|overlay"
            }
          ) < 10

        for: 5m

        labels:
          severity: critical

        annotations:
          summary: "Low disk space on EC2"
```

### Alert 4: EC2 Monitoring Target Down

```yaml
      - alert: EC2MonitoringTargetDown
        expr: up{job="node-exporter"} == 0

        for: 2m

        labels:
          severity: critical

        annotations:
          summary: "Node Exporter is unavailable"
```

**Explanation:**

If the Node Exporter endpoint becomes unavailable for two minutes, Prometheus triggers an alert.

Note that this indicates a failed metrics scrape, not necessarily that the EC2 instance is stopped.

---

# 8. Alertmanager Configuration – alertmanager.yml

Prometheus detects problems, but we need a notification mechanism to inform the SRE team.

For that, we use Alertmanager.

We configure notification destinations in `alertmanager.yml`.

Example Slack configuration:

```yaml
global:
  resolve_timeout: 5m

route:
  receiver: slack-alerts

  group_by:
    - alertname
    - severity

  group_wait: 30s
  group_interval: 5m
  repeat_interval: 1h

receivers:
  - name: slack-alerts
    slack_configs:
      - api_url: '<SLACK_WEBHOOK_URL>'
        channel: '#sre-alerts'
        send_resolved: true
```

Replace the webhook placeholder with the actual Slack webhook URL.

### How Does Alertmanager Work?

1. Prometheus continuously evaluates alert rules.
2. When a condition is satisfied, Prometheus generates an alert.
3. Prometheus forwards the alert to Alertmanager.
4. Alertmanager groups and routes the alerts.
5. Alertmanager sends notifications to Slack, email or PagerDuty.

For example, if CPU utilization exceeds 85% for five minutes, the SRE team receives a notification in Slack.

In production, we store webhook URLs securely using secrets management rather than committing them to Git.

---

# 9. Docker Compose – Deploy the Monitoring Stack

We can deploy all monitoring components using Docker Compose.

Create `docker-compose.yml`.

```yaml
services:

  payment-app:
    image: payment-service:latest
    container_name: payment-app
    ports:
      - "8080:8080"
    networks:
      - monitoring

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./prometheus/alerts.yml:/etc/prometheus/alerts.yml:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    pid: host
    volumes:
      - /:/host:ro,rslave
    command:
      - '--path.rootfs=/host'
    ports:
      - "9100:9100"
    networks:
      - monitoring

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    privileged: true
    ports:
      - "8081:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker:/var/lib/docker:ro
      - /dev/disk:/dev/disk:ro
    networks:
      - monitoring

  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge

volumes:
  prometheus-data:
  grafana-data:
```

Replace `payment-service:latest` with the actual application image.

Start the services:

```bash
docker compose up -d
```

Check running containers:

```bash
docker compose ps
```

Check Prometheus logs:

```bash
docker compose logs -f prometheus
```

This is a learning example. For production, pin image versions, secure monitoring endpoints, restrict host access, configure authentication and TLS, and persist Alertmanager data.

---

# 10. Grafana Configuration

Once all services are running, open Grafana.

```text
http://EC2-IP:3000
```

For a fresh installation, the initial login is generally:

```text
Username: admin
Password: admin
```

Change the initial password.

### Add Prometheus as a Data Source

1. Open Grafana.
2. Navigate to Connections → Data Sources.
3. Click Add data source.
4. Select Prometheus.
5. Enter the URL:

```text
http://prometheus:9090
```

6. Click Save & Test.

Now Grafana can query metrics from Prometheus.

### Example Grafana PromQL Queries

**CPU Utilization:**

```promql
100 * (
  1 - avg(rate(node_cpu_seconds_total{
    mode="idle"
  }[5m]))
)
```

**Memory Utilization:**

```promql
100 * (
  1 - node_memory_MemAvailable_bytes /
  node_memory_MemTotal_bytes
)
```

**Application Request Rate:**

```promql
sum(rate(http_server_requests_seconds_count[5m]))
```

**Application HTTP 5xx Errors:**

```promql
sum(rate(http_server_requests_seconds_count{
  status=~"5.."
}[5m]))
```

**Container Memory Usage:**

```promql
container_memory_usage_bytes
```

We create separate dashboards for application performance and infrastructure health.

---

# 11. AWS CloudWatch Monitoring

Since we are running our infrastructure on AWS, we also use CloudWatch.

CloudWatch collects metrics from AWS services.

| AWS Resource | Metrics |
|---|---|
| EC2 | CPU utilization |
| ALB | Request count, target 5xx errors |
| RDS | Database connections, CPU, storage |
| Auto Scaling | Instance count and scaling activities |
| EBS | Disk read/write operations |

For example, we can create a CloudWatch CPU alarm using AWS CLI.

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name High-EC2-CPU \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 85 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions <SNS_TOPIC_ARN> \
  --dimensions Name=InstanceId,Value=<INSTANCE_ID>
```

This creates an alarm when average CPU utilization exceeds 85% for two consecutive five-minute periods.

For EC2 memory monitoring, we install and configure CloudWatch Agent because memory utilization is not available as a standard EC2 metric.

We can also configure CloudWatch alarms to send notifications through Amazon SNS.

---

# 12. Real-Time Production Incident Example

Suppose we have a payment application running inside Docker containers on three EC2 instances.

Suddenly, customers start experiencing slow responses and payment failures.

### How do we troubleshoot?

**Step 1: Alert received**

Alertmanager sends a notification that the application error rate has exceeded 5%.

**Step 2: Check Grafana application dashboard**

We observe:

- Response time increased from 200 ms to 4 seconds.
- HTTP 5xx errors have increased.
- Request latency is continuously increasing.

**Step 3: Check infrastructure dashboard**

We observe:

- EC2 CPU utilization is around 40%.
- Memory utilization is around 60%.
- Disk utilization is normal.

This indicates that the issue might not be caused by EC2 resource exhaustion.

**Step 4: Investigate the database**

We check database connections and query latency.

We discover that database connections are almost exhausted because some queries are taking longer than expected.

**Step 5: Identify root cause**

We investigate application logs and database performance and identify a slow database query that is holding connections for longer periods.

**Step 6: Resolve the issue**

We coordinate with the development and database teams to optimize the query and verify connection pool configuration.

**Step 7: Validate recovery**

After the fix:

- Application response time returns to normal.
- HTTP 5xx error rate decreases.
- Database connections return to normal.
- Prometheus alerts are resolved.
- Grafana dashboards show healthy application performance.

This is why we monitor both application and infrastructure metrics. Monitoring only CPU and memory is not sufficient to identify every production issue.

---

# 13. Important Interview Concepts

| Tool | Responsibility |
|---|---|
| Spring Boot Actuator | Exposes application health and metrics |
| Micrometer | Application metrics instrumentation |
| Prometheus | Metrics collection and storage |
| Node Exporter | Linux/EC2 monitoring |
| cAdvisor | Docker container monitoring |
| CloudWatch | AWS infrastructure/service monitoring |
| Grafana | Dashboards and visualization |
| Alertmanager | Alert routing and notifications |
| Loki / ELK | Log aggregation and analysis |

## Four Golden Signals of SRE

We should also monitor the four Golden Signals:

1. **Latency:** How long requests take to complete.
2. **Traffic:** How many requests the application receives.
3. **Errors:** How many requests fail.
4. **Saturation:** How much of the available resources are being consumed.

These signals help us understand application reliability and performance.

---

# 14. Important Interview Follow-Up Questions

Prepare these questions after learning the complete monitoring implementation:

1. How does Prometheus scrape metrics from an application?
2. What is the difference between Node Exporter and cAdvisor?
3. What is PromQL? Can you write a CPU utilization query?
4. How do you configure alert rules in Prometheus?
5. What happens when Prometheus detects an alert?
6. What is the difference between metrics, logs and traces?
7. How do you troubleshoot high application latency?
8. What is the difference between Prometheus and CloudWatch?
9. What is the difference between Grafana and Prometheus?
10. How do you monitor Docker container memory utilization?

## 15. Quick Revision – Complete Monitoring Flow

```text
APPLICATION LEVEL

Spring Boot Application
        |
        v
Actuator + Micrometer
        |
        v
/actuator/prometheus
        |
        v
Prometheus


INFRASTRUCTURE LEVEL

EC2 Instance
     |
     v
Node Exporter
     |
     v
Prometheus

Docker Containers
     |
     v
cAdvisor
     |
     v
Prometheus


VISUALIZATION AND ALERTING

Prometheus
     |
     +--------------------+
     |                    |
     v                    v
  Grafana             Alertmanager
     |                    |
     v                    v
Dashboards           Slack / Email
```

**Three important configuration files to remember:**

- `prometheus.yml` – What metrics should Prometheus collect?
- `alerts.yml` – Under what conditions should alerts trigger?
- `alertmanager.yml` – Where should triggered alerts be sent?

**Final interview takeaway:** Understand the complete flow of application instrumentation → Prometheus scraping → Grafana dashboards → Prometheus alert rules → Alertmanager notifications. This is the foundation of application and infrastructure monitoring in a DevOps/SRE environment.
