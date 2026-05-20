## 1. A Jenkins pipeline suddenly starts failing at the Docker build stage, even though the same code was working previously. How would you troubleshoot it?

**Answer:**
First, I would check the **Jenkins console logs** to identify the exact error message during the **Docker build stage**.

Then I would verify:
* Whether the **Docker service** is running on the Jenkins agent.
* **Disk space** availability.
* **Docker daemon** health.
* Permission issues, like the Jenkins user not being part of the `docker` group.

Next, I would check:
* Recent changes in the **Dockerfile**.
* Dependency/package changes.
* **Image registry** connectivity.
* Expired **credentials** if pulling private base images.

If the build works locally but fails in Jenkins, I would compare:
* **Environment variables**.
* **Docker versions**.
* **Network access**.
* **Workspace contents**.

I would also verify whether:
* The Jenkins **workspace is corrupted**.
* **Cache issues** exist.
* The agent node has enough **CPU/memory**.

> **Senior Signal:** The most common hidden culprit when a previously working Docker build suddenly fails on a Jenkins agent is running out of disk space due to a buildup of dangling images and stopped containers. Implementing a routine `docker system prune` or migrating to a rootless container lifecycle (like Podman) on your worker nodes is a proactive way to prevent this exact outage.
