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
