## What is the difference between .twb, .twbx, .tds, and .tdsx?

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


## How did Jenkins determine which workbook or datasource changed?

**Answer:**
**Jenkins** did not directly determine which **Tableau workbook** or **datasource** changed. Since all Tableau artifacts were stored in **GitHub**, Jenkins first checked the changes between commits after a merge. 

It used the following Git command to identify the files that were modified in the latest commit and passed that list to the deployment script:

git diff --name-only HEAD~1 HEAD

For example, if a developer modified only sales_dashboard.twbx and merged the change, the command would return exactly that file path.

Jenkins would see that only this file was updated. The deployment script would then recognize it as a Tableau workbook and publish only that specific workbook to the Tableau Server using the Tableau REST API.
