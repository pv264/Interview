## What do you understand by Continuous Integration, Continuous Delivery, and Continuous Deployment?

**Answer:**
**Continuous Integration**, **Continuous Delivery**, and **Continuous Deployment** are practices in **DevOps** that help automate and improve the software release process.

### First, Continuous Integration (CI):
* This is the practice where developers frequently merge their code changes into a shared repository.
* Every time code is pushed, an **automated pipeline** runs **builds and tests** to ensure the new changes don’t break existing functionality.
* The goal of **CI** is to detect issues early and keep the codebase stable.



### Next, Continuous Delivery (CD):
* In **Continuous Delivery**, after the **CI** process completes successfully, the application is automatically built, tested, and prepared for release.
* However, the **deployment to production** is still a **manual approval step**.
* So, the system is always in a deployable state, but a human decides when to release.

### Finally, Continuous Deployment:
* This goes one step further.
* Here, once the code passes all stages—**build, test, and validation**—it is **automatically deployed to production** without any manual intervention.

---

### In simple terms:

* **CI** → automatically **test and integrate** code
* **Continuous Delivery** → keep code **ready for release** (manual deploy)
* **Continuous Deployment** → **automatically release** to production 

> **Senior Signal:** The choice between **Continuous Delivery** and **Continuous Deployment** is often a business decision rather than a technical one. Organizations with high-risk compliance requirements often prefer **Delivery** to maintain a "human-in-the-loop," while high-velocity teams leverage **Deployment** to achieve multiple releases per day.

# Jenkins CI/CD Pipeline Optimization

How can you optimize a Jenkins CI/CD pipeline for better performance and faster builds?

To optimize a Jenkins CI/CD pipeline for better performance and faster builds, we can implement the following strategies:

## 1️⃣ Parallel Builds & Stages
Instead of running tasks sequentially, we use the `parallel` directive in a Jenkinsfile to run jobs simultaneously.

**Example:** Running unit tests, security scans, and builds in parallel:

```groovy
stage('Parallel Verification') {
    parallel {
        stage('Unit Tests') {
            steps {
                // Run unit tests here
            }
        }
        stage('Security Scan') {
            steps {
                // Run security scanning tools here
            }
        }
        stage('Build Artifact') {
            steps {
                // Compile and build code here
            }
        }
    }
}

2️⃣ Caching & Dependency Management
Cache dependencies like Maven, NPM, or Docker layers to avoid downloading them in every build:
