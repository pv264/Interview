## 1 What is the difference between .twb, .twbx, .tds, and .tdsx?

**Answer:**
These are the four primary file types used in **Tableau**, categorized by whether they store actual data or just metadata and layouts:

### Workbooks (Dashboards & Visuals)
* **`.twb` (Tableau Workbook):** Contains dashboards, worksheets, and calculations, but **no actual data**. It only holds the instructions for how to connect to the data and display it.
* **`.twbx` (Tableau Packaged Workbook):** A zipped file that contains the workbook (`.twb`) **plus** the local data (extracts), background images, and supporting files. 

### Data Sources (Connections & Metadata)
* **`.tds` (Tableau Data Source):** A datasource definition containing connection metadata (like server addresses, database names, and custom calculated fields) but **no data**.
* **`.tdsx` (Tableau Packaged Data Source):** A zipped file that includes both the datasource definition (`.tds`) **and** the actual data extract.

---

### CI/CD Deployment Context
In CI/CD deployments, we typically publish **`.twbx`** and **`.tdsx`** files because they are self-contained and easier to deploy across environments without risking external network connection failures during the build process.

> **Senior Signal:** While publishing `.twbx` and `.tdsx` files is convenient, storing them in a Git repository can massively bloat the repo size because they contain raw data. A strong DevOps approach involves either using **Git LFS (Large File Storage)** for packaged files, or version controlling only the lightweight `.twb`/`.tds` files and having the CI/CD pipeline trigger a "Refresh Extract" command via the Tableau REST API immediately after deployment to populate the data on the server side.


## 2 How did Jenkins determine which workbook or datasource changed?

**Answer:**
**Jenkins** did not directly determine which **Tableau workbook** or **datasource** changed. Since all Tableau artifacts were stored in **GitHub**, Jenkins first checked the changes between commits after a merge. 

It used the following Git command to identify the files that were modified in the latest commit and passed that list to the deployment script:

git diff --name-only HEAD~1 HEAD

For example, if a developer modified only sales_dashboard.twbx and merged the change, the command would return exactly that file path.

Jenkins would see that only this file was updated. The deployment script would then recognize it as a Tableau workbook and publish only that specific workbook to the Tableau Server using the Tableau REST API.

## 3 What challenges did you face during Tableau deployment?

**Answer:**
One of the main challenges we faced during **Tableau deployments** was related to **permissions and access control**.

### The Challenge: Permission Mismatch
Sometimes, a workbook deployment would fail completely even though the workbook itself was valid and worked perfectly on the developer's desktop. 

After investigating the logs, we found that the **service account** or **Personal Access Token (PAT)** used by the Jenkins CI/CD pipeline did not have sufficient permissions on the target **Tableau project** or underlying **datasource**. 

Because Tableau enforces strict multi-tenancy and permission inheritance, if the automation script attempted to publish a workbook to a project where it lacked "Write" or "Publisher" access—or if it tried to attach to a secured datasource without the proper credentials embedded—the Tableau REST API would reject the call with a `403` forbidden error, breaking the pipeline.

---

### How We Resolved It:
* We established a dedicated, non-expiry CI/CD service account with standardized **Publisher** permissions across all target environments.
* We locked down permissions at the **Project level** in Tableau Server and enabled "Locked project permissions" to ensure that child workbooks and datasources automatically inherited the correct security settings, preventing ad-hoc configuration drift.

> **Senior Signal:** Permission errors are the number one operational headache when automating BI workflows. A great way to handle this proactively is to include a pre-flight "Permission Check" stage in your Jenkinsfile. Before attempting a heavy upload of `.twbx` or `.tdsx` files, the script can hit a lightweight API endpoint to verify that the token has valid access to the target project ID. If it doesn't, the pipeline fails immediately with a clear, actionable error message before wasting time on compiling or transferring assets.
