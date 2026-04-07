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
