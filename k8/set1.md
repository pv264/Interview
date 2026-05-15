1. explain the concept of liveness and readiness probes?
In Kubernetes, liveness and readiness probes are configured inside the container specification of a Pod or Deployment YAML. Readiness probes determine whether a pod is ready to receive traffic,
while liveness probes determine whether the container is healthy or not

For example, a Spring Boot app may take 40 seconds to connect to the database and load configurations, so readiness probe prevents users from hitting the pod too early.

Liveness probe is used to detect application hangs or deadlocks after the application is already running. If the app becomes unresponsive,
Kubernetes automatically restarts the container to recover the service.”
