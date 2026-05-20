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


## 2. How do you integrate SonarQube with Jenkins in a CI/CD pipeline?

**Answer:**
We integrate **SonarQube** with **Jenkins** to perform automated code quality and security analysis during the CI/CD pipeline. 

### Integration Workflow:

1. **Install and Configure:** First, we install the **SonarQube Scanner plugin** in Jenkins and configure the SonarQube server URL and authentication token under Jenkins global configuration.
2. **Add Pipeline Stage:** Then we configure the Sonar scanner tool and add a dedicated SonarQube analysis stage in the Jenkins pipeline using Maven, Gradle, or the `sonar-scanner` command depending on the application type.
3. **Execute Analysis:** During pipeline execution, Jenkins sends the source code to SonarQube for analysis, where it checks for bugs, vulnerabilities, code smells, duplicated code, and code coverage.
4. **Enforce Quality Gate:** We also configure a **Quality Gate** in SonarQube, and Jenkins waits for the Quality Gate result before proceeding further. 

If the **Quality Gate** fails, the pipeline automatically stops, preventing low-quality or vulnerable code from being deployed to higher environments.

> **Senior Signal:** When configuring the Quality Gate step in a Jenkinsfile, it is a best practice to use the `waitForQualityGate()` step combined with a **SonarQube webhook** pointing back to Jenkins. This allows the Jenkins pipeline to pause asynchronously without consuming an executor node thread while waiting for the SonarQube server to finish processing the analysis report.
