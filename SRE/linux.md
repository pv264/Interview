# Difference Between a Daemon and a Service

Although the terms **daemon** and **service** are often used interchangeably, they are not exactly the same.

A **daemon** is a background process that runs continuously and performs a specific task without user interaction.

A **service** is the way the operating system manages that daemon—starting it, stopping it, restarting it, checking its status, and ensuring it starts automatically during system boot.

In simple terms:

* **Daemon = The actual process doing the work.**
* **Service = The management layer for that process.**

---

# What is a Daemon?

A daemon is a program that runs in the background and waits for events or requests.

It usually starts during system boot and continues running until the system shuts down.

Examples include:

* SSH Daemon (`sshd`)
* Docker Daemon (`dockerd`)
* Nginx
* Cron Daemon (`crond`)
* Kubernetes Kubelet

For example:

When you connect to a Linux server using SSH, the **sshd daemon** is always running in the background waiting for incoming SSH connections.

---

# What is a Service?

A service is the operating system's way of managing daemons.

On modern Linux distributions, services are usually managed by **systemd**.

Using `systemctl`, you can:

Start a service:

```bash
systemctl start nginx
```

Stop a service:

```bash
systemctl stop nginx
```

Restart a service:

```bash
systemctl restart nginx
```

Check its status:

```bash
systemctl status nginx
```

Enable it to start automatically on boot:

```bash
systemctl enable nginx
```

So, when we run:

```bash
systemctl start nginx
```

the service manager starts the **nginx daemon**.

---

# Real-Time Example

Suppose we have an Nginx web server.

```text
              User
                │
                ▼
      systemctl start nginx
                │
                ▼
        systemd (Service Manager)
                │
                ▼
        nginx daemon starts
                │
                ▼
      Listens on Port 80
```

Here:

* **systemd** manages the service.
* **nginx** is the daemon that actually serves web requests.

---

# Another Example – Docker

When Docker is installed:

```bash
systemctl start docker
```

starts the **Docker service**.

Internally:

```text
systemd

↓

dockerd (Docker Daemon)

↓

Manages Containers
```

The Docker daemon is responsible for:

* Creating containers
* Starting containers
* Stopping containers
* Pulling images

The Docker service simply controls that daemon.

---

# Key Differences

| Daemon                              | Service                                                  |
| ----------------------------------- | -------------------------------------------------------- |
| Background process                  | Managed unit in the operating system                     |
| Performs the actual work            | Starts, stops, and monitors the daemon                   |
| Runs continuously                   | Managed by systemd (or init systems)                     |
| Example: `sshd`, `dockerd`, `crond` | Example: `ssh.service`, `docker.service`, `cron.service` |

---

# Interview Summary

> **"A daemon is a background process that continuously performs a specific task without user interaction, such as the SSH daemon or Docker daemon. A service is the mechanism used by the operating system, typically through systemd, to manage that daemon. It allows administrators to start, stop, restart, enable, or monitor the daemon. In simple terms, the daemon does the actual work, while the service is responsible for managing its lifecycle."**

# Difference Between Soft Link and Hard Link

A **link** in Linux is simply another way to access a file.

There are two types of links:

1. **Hard Link**
2. **Soft (Symbolic) Link**

The main difference is **what they point to**.

* A **Hard Link** points directly to the file's **inode**.
* A **Soft Link (Symbolic Link)** points to the **file's path (filename)**.

---

# What is an Inode?

Before understanding links, it's important to know what an inode is.

When a file is created, Linux stores:

* The file name
* The actual file data
* File metadata (permissions, owner, timestamps, size)

The **inode** stores the metadata and points to where the file's data is stored on disk.

The filename is simply an entry that points to that inode.

---

# Hard Link

A hard link creates **another filename that points to the same inode**.

Example:

```bash
echo "Hello" > file1.txt
ln file1.txt file2.txt
```

Now:

```text
file1.txt  ─┐
            ├──► Inode 12345 ───► File Data
file2.txt  ─┘
```

Both file names point to the same inode.

There is only **one copy of the data**.

### What happens if I delete file1.txt?

```bash
rm file1.txt
```

The data is **not deleted**.

Why?

Because `file2.txt` still points to the same inode.

Only when **all hard links are removed** does Linux delete the actual data.

---

# Soft Link (Symbolic Link)

A soft link is like a shortcut.

Example:

```bash
ln -s file1.txt link.txt
```

Now:

```text
link.txt
    │
    ▼
file1.txt
    │
    ▼
Inode 12345
    │
    ▼
File Data
```

Notice that the symbolic link points to the **filename**, not directly to the inode.

### What happens if I delete file1.txt?

```bash
rm file1.txt
```

Now:

```text
link.txt

↓

Broken Link
```

The symbolic link still exists, but it points to a file that no longer exists.

This is called a **dangling (broken) symbolic link**.

---

# Key Differences

| Hard Link                                             | Soft Link                              |
| ----------------------------------------------------- | -------------------------------------- |
| Points to the inode                                   | Points to the file path                |
| Cannot span different filesystems                     | Can span different filesystems         |
| Cannot link directories (normally)                    | Can link files and directories         |
| Continues to work if the original filename is deleted | Breaks if the original file is deleted |
| Shares the same inode as the original file            | Has its own inode                      |

---

# When Would I Use a Hard Link?

A hard link is useful when I want **multiple filenames to reference the same file** and ensure the data remains available even if one filename is deleted.

For example:

* Maintaining multiple references to important data.
* Backup or archival workflows where the same data should not be duplicated.

---

# When Would I Use a Soft Link?

A soft link is much more common in day-to-day Linux administration.

Examples include:

* Creating shortcuts to configuration files.
* Pointing to the latest application version.

For example:

```text
/opt/app-v1.0
/opt/app-v2.0

current → /opt/app-v2.0
```

Applications always use:

```text
/opt/current
```

When a new version is deployed, I only update the symbolic link.

No application configuration needs to change.

Another common example is:

```text
/usr/bin/python

↓

/usr/bin/python3
```

Here, `python` is often a symbolic link pointing to the actual Python executable.

---

# Commands

### Create a Hard Link

```bash
ln file1.txt file2.txt
```

### Create a Soft Link

```bash
ln -s file1.txt link.txt
```

### Check Links

```bash
ls -li
```

This displays inode numbers.

Hard-linked files will have the **same inode number**, while symbolic links have a different inode.

---

# Interview Summary

> **"The main difference is that a hard link points directly to a file's inode, while a soft link points to the file's path. Because a hard link references the same inode, deleting the original filename does not remove the data as long as another hard link exists. A soft link behaves like a shortcut, so if the original file is deleted, the symbolic link becomes broken. Hard links are limited to the same filesystem and generally cannot be created for directories, whereas soft links can point to files or directories across different filesystems."**


# How Do You Troubleshoot Disk I/O Issues?

If I receive an alert that an application is slow, I don't immediately assume it's a CPU or memory issue. Sometimes the server is slow because processes are waiting for disk operations to complete.

I follow a structured approach to identify whether disk I/O is the bottleneck.

---

# Step 1 – Understand the Symptoms

First, I understand what users are experiencing.

For example:

* Application is responding slowly.
* Database queries are taking longer than usual.
* File uploads or downloads are slow.
* Pods or applications are taking longer to start.

These symptoms often indicate a possible storage issue.

---

# Step 2 – Check Overall System Health

I first check the overall health of the server.

```bash
top
```

or

```bash
htop
```

Here I'm looking at:

* CPU utilization
* Memory usage
* **I/O wait (%wa)**

One important metric is **I/O wait**.

If CPU utilization is low but **I/O wait is high**, it means the CPU is idle because it's waiting for disk operations to complete.

For example:

```text
CPU Usage : 25%
I/O Wait  : 35%
```

This strongly suggests a disk I/O bottleneck.

---

# Step 3 – Check Disk Utilization

Next, I use:

```bash
iostat -x 1 5
```

This provides detailed disk statistics.

The main metrics I check are:

* **%util** – How busy the disk is.
* **await** – Average time for read/write operations.
* **r/s** and **w/s** – Read and write operations per second.

For example:

```text
Device    %util   await
xvda      98%     150 ms
```

If `%util` is consistently close to **100%** and `await` is high, the storage device is saturated and requests are waiting in a queue.

---

# Step 4 – Identify Which Process Is Causing Heavy I/O

Once I know the disk is busy, I identify which process is generating the I/O.

```bash
iotop
```

or

```bash
pidstat -d
```

This shows which processes are performing the most disk reads and writes.

For example, I may find:

* A database process
* A backup job
* A log rotation process
* A large file copy

Now I know where to focus my investigation.

---

# Step 5 – Check Disk Space

A filesystem that's almost full can also affect performance.

I verify:

```bash
df -h
```

If the filesystem is close to 100% utilization, applications may struggle to write logs or temporary files.

I also check which directories are consuming the most space.

```bash
du -sh /var/*
```

---

# Step 6 – Check Application Logs

After identifying the affected process, I review the application logs.

I'm looking for messages such as:

* Database timeouts
* File write failures
* Storage errors
* Slow query warnings

This helps determine whether the application is the source of the heavy I/O or simply being affected by it.

---

# Step 7 – Check Recent Changes

Next, I ask:

* Was a backup job started?
* Was a new deployment performed?
* Has traffic increased?
* Has log generation increased?
* Was a batch job scheduled?

Many disk I/O issues are caused by recent operational changes.

---

# Step 8 – Mitigation

The solution depends on the root cause.

### If a backup job is causing the issue

* Reschedule it to off-peak hours.

### If the database is generating excessive disk activity

* Optimize queries.
* Add indexes if appropriate.
* Investigate slow queries.

### If storage is saturated

* Upgrade to faster storage (for example, increase EBS IOPS on AWS).
* Move workloads to separate volumes if necessary.

### If logs are filling the disk

* Configure log rotation.
* Archive or clean old logs.

---

# Step 9 – Verify

After applying the fix, I verify:

* I/O wait has decreased.
* Disk utilization is back to normal.
* Application response time has improved.
* Users can access the application without delays.

Only after confirming normal performance do I close the incident.

---

# Real-World Example

Suppose an application suddenly becomes slow.

Initially, CPU utilization is only **20%**, so CPU doesn't appear to be the issue.

However, `iostat` shows:

```text
Disk Utilization : 99%
Average Wait     : 180 ms
```

Using `iotop`, I discover that a scheduled backup job is consuming most of the disk bandwidth.

I temporarily pause the backup job and reschedule it to run during non-business hours.

After that:

* Disk utilization drops.
* Application response times return to normal.
* Users no longer experience delays.

---

# Troubleshooting Flow

```text
Application Slow

↓

Check CPU, Memory and I/O Wait

↓

Run iostat

↓

Is disk utilization high?

↓

Identify high I/O process (iotop)

↓

Check logs and recent changes

↓

Fix the root cause

↓

Verify application performance
```

---

# Interview Summary

> **"When troubleshooting disk I/O issues, I first confirm that storage is actually the bottleneck by checking CPU, memory, and I/O wait using tools like `top` or `htop`. If I/O wait is high, I use `iostat` to analyze disk utilization and latency. Then I identify the process generating the most disk activity using `iotop` or `pidstat -d`. I also check disk space, review application logs, and look for recent changes such as backup jobs or deployments. Once I identify the root cause, I apply the appropriate fix, verify that disk performance has improved, and ensure the application is responding normally again."**


# Explain the Linux Process Lifecycle

A process is simply a **program that is currently executing**.

For example, when you run:

```bash
python app.py
```

or

```bash
nginx
```

Linux creates a **process** for that program.

Every process goes through a lifecycle from creation until termination.

---

# Step 1 – Process Creation

A process starts when a user or another process executes a program.

In Linux, a new process is typically created using the **fork()** system call.

Here's what happens:

1. An existing process (called the **parent process**) creates a copy of itself using `fork()`.
2. The new copy is called the **child process**.
3. The child process then uses **exec()** to replace itself with the new program that needs to run.

Example:

```text
Shell (Parent)

↓

fork()

↓

Child Process

↓

exec()

↓

Runs nginx
```

Every process gets a unique **Process ID (PID)**.

---

# Step 2 – Ready State

After creation, the process enters the **Ready** state.

This means:

* The process is ready to run.
* It is waiting for CPU time.
* It is in the scheduler's queue.

It hasn't started executing yet.

---

# Step 3 – Running State

When the CPU scheduler assigns CPU time, the process enters the **Running** state.

In this state, the process is actively executing instructions.

For example:

* Running a Java application.
* Processing an HTTP request.
* Executing a Python script.

---

# Step 4 – Waiting (Sleeping) State

Many processes spend most of their time waiting rather than using the CPU.

For example, a web application may be waiting for:

* A database response.
* A network request.
* A file read operation.

While waiting, the process enters a **Sleeping** state.

There are two common types:

### Interruptible Sleep (S)

The process is waiting for an event and can be interrupted.

Example:

Waiting for user input.

### Uninterruptible Sleep (D)

The process is waiting for disk I/O or hardware operations.

It cannot be interrupted until the operation completes.

This is important because many production issues involve processes stuck in the **D state**, indicating storage or filesystem problems.

---

# Step 5 – Stopped State

A process may be temporarily paused.

For example:

```bash
kill -STOP <PID>
```

or by pressing:

```text
Ctrl + Z
```

The process remains in memory but does not execute until resumed.

To continue it:

```bash
kill -CONT <PID>
```

---

# Step 6 – Zombie State

When a process finishes execution, it exits.

However, if the parent process hasn't yet collected the child's exit status, the child becomes a **Zombie** process.

A zombie process:

* Has finished execution.
* Uses almost no system resources.
* Still has an entry in the process table.

Normally, the parent process calls `wait()` to clean it up.

If many zombie processes accumulate, it usually indicates a problem with the parent application.

---

# Step 7 – Process Termination

Finally, the process exits.

It may terminate because:

* The task completed successfully.
* The user stopped it.
* It received a signal like `SIGTERM` or `SIGKILL`.
* The kernel terminated it (for example, the OOM Killer due to low memory).

Once the parent process collects its exit status, Linux removes the process completely from the process table.

---

# Process Lifecycle Diagram

```text
            fork()
               │
               ▼
        Process Created
               │
               ▼
             Ready
               │
               ▼
            Running
           /       \
          ▼         ▼
     Sleeping     Stopped
          │
          ▼
       Running
          │
          ▼
       Terminated
          │
          ▼
        Zombie
          │
          ▼
      Process Removed
```

---

# Common Process States

When you run:

```bash
ps aux
```

or

```bash
top
```

You may see these process states:

| State | Meaning                                              |
| ----- | ---------------------------------------------------- |
| R     | Running or Ready to Run                              |
| S     | Interruptible Sleep                                  |
| D     | Uninterruptible Sleep (usually waiting for disk I/O) |
| T     | Stopped                                              |
| Z     | Zombie                                               |

---

# Real-Time Example

Suppose an Nginx server receives a client request.

1. The Nginx worker process is already running.
2. It receives the request.
3. It processes the request (Running state).
4. It waits for a database response (Sleeping state).
5. The database responds.
6. The process resumes, sends the HTTP response, and continues waiting for the next request.

This cycle repeats throughout the lifetime of the process.

---

# Interview Summary

> **"A Linux process begins when a parent process creates a child process using `fork()`, and the child loads the required program using `exec()`. The process enters the Ready state while waiting for CPU time, then moves to the Running state when scheduled by the CPU. During execution, it may enter a Sleeping state while waiting for resources such as disk I/O or network responses. A process can also be Stopped if it's paused, or become a Zombie after it exits but before the parent process collects its exit status. Finally, once the parent calls `wait()`, the operating system removes the process completely from the process table."**

