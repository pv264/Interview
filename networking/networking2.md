## 1. What will happen in the backend when we enter amazon.com?

When I enter `amazon.com` in a browser, the process happens as follows:

1. **Browser & DNS Resolution**
   * First, the browser checks its **local cache** and **DNS cache** for the IP address.
   * If not found, it queries the **DNS resolver**.
   * If there is no cache hit, DNS resolves the domain name to an IP address.

2. **Connection Establishment**
   * Once the IP is obtained, the browser establishes a **TCP connection**.
   * This is followed by a **TLS handshake** because the site uses HTTPS.

3. **CDN (Content Delivery Network)**
   * The request is routed to a CDN like **Amazon CloudFront**.
   * CloudFront checks its **edge cache**:
     * **Cache Hit:** If content (HTML, images, CSS, JS) is valid, it is served directly from the edge (reducing latency).
     * **Cache Miss:** If not cached, the request is forwarded to the origin.

4. **Load Balancing**
   * The request reaches a **Load Balancer**, which distributes traffic to healthy backend application servers.

5. **Application Layer & Caching**
   * The backend first checks **application-level caches** (Redis, Memcached, or in-memory):
     * **Cache Hit:** Data is returned immediately.
     * **Cache Miss:** The application fetches data from the **Database**, processes it, and stores the result back in cache.

6. **Response Path**
   * `Application` → `Load Balancer` → `CDN` (may cache response) → `Browser`.

7. **Rendering**
   * The browser checks its cache again, downloads missing resources, and renders the page using HTML, CSS, and JavaScript.

---

## 2. How do you troubleshoot high latency?

**Strategy:** I use a **"Divide and Conquer"** strategy to isolate where the time is being spent: Client, Network, Server, or Database.

### Step 1: Isolate the Component
I look at the **Load Balancer (ALB) logs**:
* **If `TargetResponseTime` is high:** The slowness is in the application/backend.
* **If `TargetResponseTime` is low (but user sees slowness):** The issue is likely the network or the client's ISP.

### Step 2: Database Layer (The Usual Suspect)
If the backend is slow, I check the **Database (RDS/DynamoDB)**:
* Is CPU high?
* Are there slow queries or missing indexes?
* Is there lock contention?

### Step 3: Application Resources
I check **CloudWatch** for resource spikes on EC2 instances:
* **High CPU/Memory?**
* **Swapping?** If the server is swapping memory to disk, latency spikes significantly.

### Step 4: Dependencies
* Is the app waiting on a **3rd party API** (e.g., a payment gateway) that is timing out?
* **Tools:** Tracing tools like **AWS X-Ray** or **Datadog APM** are vital here to visualize the "waterfall" of the request.

# Proxy Types
## What is forward proxy and reverse proxy?

## 1. Forward Proxy
A **Forward Proxy** sits between the client and the internet, controlling and managing **outbound** requests from clients.

* **Role:** Acts on behalf of the client.
* **Function:** Hides client identity, enforces security policies, or bypasses geo-restrictions.

## 2. Reverse Proxy
A **Reverse Proxy** sits between the client and backend servers, handling **inbound** requests and forwarding them to the appropriate servers.

* **Role:** Acts on behalf of the server.
* **Function:** Load balancing, SSL termination, caching, and hiding server topology.
