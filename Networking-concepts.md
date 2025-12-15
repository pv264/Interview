## 1. What will happen in the backedn when we enter amazon.com?
When I enter amazon.com in a browser, the process happens as follows:

First, the browser checks its local cache and DNS cache to see if it already has the IP address for amazon.com.
If not found, it queries the DNS resolver, which may also return a cached DNS record. If there’s no cache hit, DNS resolves the domain name to an IP address.

Once the IP is obtained, the browser establishes a TCP connection, followed by a TLS handshake because the site uses HTTPS.

The request is then routed to a CDN like Amazon CloudFront.
At the CDN edge location, CloudFront checks its edge cache:

If the requested content (HTML, images, CSS, JS) is cached and valid, it is served directly from the edge, reducing latency.

If not cached, the request is forwarded to the origin.

The request reaches a load balancer, which distributes traffic to healthy backend application servers.

At the application layer, the backend first checks application-level caches (such as Redis, Memcached, or in-memory cache):

If the data is present in cache, it is returned immediately.

If there is a cache miss, the application fetches data from the database, processes the request, and then stores the result back in cache for future requests.

The response then travels back:
Application → Load Balancer → CDN (where it may be cached) → Browser.

Finally, the browser checks its browser cache again, downloads only missing or updated resources, and renders the page using HTML, CSS, and JavaScript.

## 2. How do you troubleshoot highlatency?
4. How will you troubleshoot high latency?
"I use a 'Divide and Conquer' strategy to isolate where the time is being spent: Client, Network, Server, or Database.

Isolate the Component: I look at the Load Balancer (ALB) logs.

If TargetResponseTime is high, the slowness is in the application/backend.

If TargetResponseTime is low but the user experiences slowness, the issue is likely the network or the client's ISP.

Database Layer (The usual suspect): If the backend is slow, I check the Database (RDS/DynamoDB). Is CPU high? are there slow queries or missing indexes? Is there a lock contention?

Application Resources: I check CloudWatch for CPU/Memory spikes on the EC2 instances. If the server is swapping memory, latency spikes.

Dependencies: Is the app waiting on a 3rd party API (e.g., a payment gateway) that is timing out? Tracing tools like AWS X-Ray or Datadog APM are vital here to visualize the 'waterfall' of the request."
