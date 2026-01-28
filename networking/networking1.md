# 🌐 Public vs Private IP Address Reference

This document explains how to identify whether an IPv4 address is **public** or **private**, with examples and quick checks.

---

## ✅ Private IP Address Ranges (RFC 1918)

An IP address is **PRIVATE** if it falls within **any** of the following ranges:

| Range | CIDR | Example |
|-----|-----|--------|
| 10.0.0.0 – 10.255.255.255 | 10.0.0.0/8 | 10.1.2.3 |
| 172.16.0.0 – 172.31.255.255 | 172.16.0.0/12 | 172.20.10.5 |
| 192.168.0.0 – 192.168.255.255 | 192.168.0.0/16 | 192.168.1.100 |

👉 These IPs are **not routable on the internet**  
👉 Used in VPCs, data centers, Kubernetes, and home networks

---

## 🌍 Public IP Address

Any IP address **outside** the private ranges is a **PUBLIC IP**.

### Examples
8.8.8.8
54.182.91.10
172.32.5.4
192.167.1.100

---

## 🔍 Common Confusion Examples

| IP Address | Type | Reason |
|----------|------|------|
| 172.20.5.1 | Private | Falls in 172.16–31 |
| 172.32.5.4 | Public | Outside 172.16–31 |
| 192.168.1.10 | Private | 192.168.x.x only |
| 192.167.1.100 | Public | Below 192.168 |

---

## 🧠 Easy Memory Rules

- **10.x.x.x** → Always private
- **172.16–172.31** → Private
- **192.168.x.x** → Private
- Anything else → Public

---

## ⚠️ Special IP Ranges (Not Public)

| Range | Purpose |
|-----|--------|
| 127.0.0.1 | Loopback (localhost) |
| 169.254.0.0/16 | Link-local (AWS metadata, DHCP issues) |
| 0.0.0.0 | Unspecified |
| 224.0.0.0/4 | Multicast |

# AWS Technical Task: Implementing VPC Peering

## 1. Situation & Task
In this project, I was tasked with enabling secure, private communication between two isolated AWS environments: a **Default Public VPC** and a **Custom Private VPC**. 

The primary objective was to allow a public-facing EC2 instance to communicate with a private backend EC2 instance using their **private IP addresses**. Success was validated by establishing a successful ICMP (ping) connection between the instances.

---

## 2. Action (The Implementation)
I approached the implementation by addressing three distinct technical layers: **Connectivity, Routing, and Security.**



### A. The Connectivity Layer (Handshake)
* **Initiation:** I established a **VPC Peering Connection** by sending a request from the Default VPC (Requester) to the Private VPC (Accepter).
* **Acceptance:** I manually accepted the peering request within the AWS console to finalize the logical link between the two VPC containers.

### B. The Routing Layer (Network Pathing)
A peering connection is a logical bridge, but it requires explicit routing instructions to function.
* **Outbound Route:** I updated the **Route Table** associated with the Public VPC. I added a route for the destination CIDR `10.1.0.0/16` (the Private VPC), targeting the Peering Connection ID (`pcx-xxxx`).
* **Return Route:** To ensure bi-directional communication, I updated the Private VPC’s Route Table to point traffic for the Default VPC CIDR (`172.31.0.0/16`) back through the same peering connection.



### C. The Security Layer (Traffic Filtering)
AWS Security Groups follow a "default-deny" stance for inbound traffic.
* **Rule Modification:** I modified the **Security Group** attached to the private EC2 instance.
* **Principle of Least Privilege:** I added an inbound rule specifically for **ICMP IPv4** traffic, scoped strictly to the source CIDR of the Public VPC. This allowed the "ping" request while maintaining a tight security posture.

---

## 3. Result & Validation
To verify the setup, I performed the following:
1. **Host Access:** I injected my local public key into the `~/.ssh/authorized_keys` file of the Public EC2 instance to gain shell access.
2. **Connectivity Test:** From the Public EC2 terminal, I executed a `ping` command to the Private IP of the backend instance.
3. **Outcome:** The test yielded a 0% packet loss response, confirming that the peering link was active, routing was correctly propagated, and security filters were properly configured.

---

## 💡 Interview Pro-Tips & Deep Dive
* **Non-Transitive Nature:** VPC peering is non-transitive. If VPC A is peered with VPC B, and B is peered with C, VPC A cannot communicate with VPC C through B. A direct peering link or a Transit Gateway would be required.
* **CIDR Constraints:** Peering is only possible if the VPCs have **non-overlapping CIDR blocks**.
* **AWS Backbone:** Communication via VPC Peering stays entirely within the AWS global network infrastructure. It never traverses the public internet, reducing latency and increasing security.


