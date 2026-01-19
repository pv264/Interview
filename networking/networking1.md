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

---


