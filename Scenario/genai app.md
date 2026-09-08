# LLM RAG Application – Complete Architecture and Scaling Explanation

One of the key infrastructure projects I worked on was designing and implementing the infrastructure and **auto-scaling strategy for an LLM-based RAG application running on AWS**.

The primary objective of the application was to answer user queries using **Retrieval-Augmented Generation, or RAG**.

The application was deployed on **AWS EC2**. The main application layer consisted of **Haystack application servers running on EC2 instances behind an Application Load Balancer (ALB)**. These EC2 instances were managed through an **Auto Scaling Group**.

The application also had separate downstream services:

* **Milvus** – our vector database for retrieving relevant documents.
* **Embedding Service** – used when embeddings were required for the query.
* **vLLM** – our LLM inference server running on GPU infrastructure.

The overall architecture was:

```text
                           USER
                             |
                             | HTTPS
                             v
                    +------------------+
                    |   API Gateway    |
                    | API Management   |
                    | Auth / Throttle  |
                    +--------+---------+
                             |
                             | HTTP/HTTPS
                             v
                    +------------------+
                    |       ALB        |
                    +--------+---------+
                             |
                 RequestCountPerTarget
                             |
             +---------------+---------------+
             |               |               |
             v               v               v
          EC2-1           EC2-2           EC2-3
        Haystack         Haystack         Haystack
        Application      Application      Application
             |               |               |
             +---------------+---------------+
                             |
                    Internal communication
                             |
              +--------------+--------------+
              |              |              |
              v              v              v
        Embedding        Milvus           vLLM
         Service       Vector DB       GPU Server
                                             |
                                             |
                                            GPU
                                             |
                                             v
                                            LLM
```

The key point is that the **Haystack application layer and vLLM inference layer were separate** because they had different responsibilities and different performance bottlenecks.

---

# 1. Where was the application deployed?

We deployed the application on **AWS EC2**.

The Haystack application was running on multiple EC2 instances. These instances were placed behind an **Application Load Balancer**.

The EC2 instances were managed through an **Auto Scaling Group**.

Our baseline configuration was:

```text
Minimum Capacity  = 2
Desired Capacity  = 2
Maximum Capacity  = 4
```

So, under normal conditions, we had two Haystack application servers running.

If application traffic increased beyond the capacity of those servers, the Auto Scaling Group could launch additional EC2 instances.

The ALB then automatically started distributing traffic to the new healthy instance after it passed the required health checks.

Our infrastructure therefore looked like:

```text
                   ALB
                    |
          +---------+---------+
          |                   |
          v                   v
       EC2-1               EC2-2
     Haystack             Haystack
         \                   /
          \                 /
           \               /
            +-------------+
```

The application layer was therefore horizontally scalable.

---

# 2. Why did we have API Gateway and ALB?

We had two different layers because they served different purposes.

## API Gateway

**API Gateway was the external API entry point.**

It handled the API-facing concerns such as:

* API management
* Authentication/authorization where configured
* Throttling
* Rate limiting
* Request controls

The user interacted with the API through API Gateway rather than directly accessing the EC2 instances.

Conceptually:

```text
User
 |
 | HTTPS
 v
API Gateway
```

## Application Load Balancer

The **ALB handled load balancing for the Haystack application servers**.

After API Gateway received the request, it forwarded the request to the backend integration, which ultimately reached the ALB.

The ALB then selected one of the healthy Haystack EC2 instances.

```text
API Gateway
     |
     v
    ALB
     |
     +--------+--------+
     |        |        |
     v        v        v
   EC2-1    EC2-2    EC2-3
 Haystack  Haystack  Haystack
```

So the simple distinction is:

> **API Gateway manages the API entry point, while ALB distributes application traffic across the Haystack servers.**

---

# 3. Complete request flow

Now let's take an example.

Suppose a user asks:

> "What is our company's refund policy?"

The complete request flow is:

```text
User
 ↓
API Gateway
 ↓
ALB
 ↓
Haystack EC2
 ↓
Embedding Service
 ↓
Milvus
 ↓
Haystack
 ↓
vLLM
 ↓
GPU
 ↓
LLM
 ↓
vLLM
 ↓
Haystack
 ↓
ALB
 ↓
API Gateway
 ↓
User
```

Let's understand each step.

---

# 4. Step 1 – User sends the request

The user interacts with the application and submits a question.

For example:

```text
"What is our refund policy?"
```

The frontend sends the request to our API endpoint over HTTPS.

Conceptually:

```http
POST /chat
```

The request contains the user's query and any other required request information.

The important point is that the user does **not** directly communicate with the Haystack EC2 instance, Milvus, embedding service, or vLLM server.

---

# 5. Step 2 – Request reaches API Gateway

The request first reaches **API Gateway**.

API Gateway acts as our API management layer.

At this layer, we can handle things such as authentication, authorization, throttling, and rate limiting.

The communication is:

```text
User
 |
 | HTTPS
 v
API Gateway
```

After API Gateway accepts the request, it forwards the request to our backend integration.

---

# 6. Step 3 – API Gateway communicates with ALB

The API Gateway forwards the request toward the application backend through the configured integration.

The next major component is the **Application Load Balancer**.

Conceptually:

```text
API Gateway
     |
     | HTTP/HTTPS
     v
    ALB
```

The ALB knows about the healthy Haystack application targets.

---

# 7. Step 4 – ALB selects a Haystack server

Suppose we currently have two Haystack EC2 instances:

```text
                 ALB
                  |
           +------+------+
           |             |
           v             v
        EC2-1         EC2-2
       Haystack       Haystack
```

The ALB distributes incoming requests across the healthy targets.

For example, one request might go to EC2-1 and another request might go to EC2-2.

This is also where our scaling metric becomes important.

We monitor:

**ALB RequestCountPerTarget**

This tells us approximately how many requests each healthy Haystack target is handling.

---

# 8. Step 5 – Haystack receives the request

The selected Haystack application server receives the user's query.

Haystack is our **application orchestration layer**.

It coordinates the complete RAG workflow.

The Haystack server is responsible for:

1. Receiving the request
2. Processing the query
3. Interacting with the embedding service when required
4. Querying Milvus
5. Retrieving relevant documents
6. Constructing the final prompt
7. Calling vLLM
8. Receiving the generated response
9. Returning the response to the user

This is why Haystack is effectively the central orchestration component of our application.

---

# 9. Step 6 – Haystack communicates with the Embedding Service

For RAG, we may need to convert the user's query into an embedding/vector representation.

Haystack communicates with our **embedding service**.

The communication is internal service-to-service communication.

Conceptually:

```text
Haystack
   |
   | Internal API request
   v
Embedding Service
   |
   | Embedding/vector
   v
Haystack
```

The user does not directly call the embedding service.

The Haystack application makes this internal request.

---

# 10. Step 7 – Haystack communicates with Milvus

Once the query embedding is available, Haystack uses it to perform a vector search against **Milvus**.

Milvus is our vector database.

The purpose is to find the documents or document chunks that are semantically relevant to the user's question.

The flow becomes:

```text
User Query
     |
     v
Haystack
     |
     v
Embedding Service
     |
     v
Query Embedding
     |
     v
Milvus
     |
     v
Relevant Documents
     |
     v
Haystack
```

Haystack sends the query/vector to Milvus and waits for the results.

This is one of the important reasons the application was **latency-bound**.

The Haystack server spends part of the request lifecycle waiting for Milvus to respond rather than continuously consuming CPU.

---

# 11. Step 8 – Haystack constructs the final prompt

After Milvus returns the relevant documents, Haystack combines the information.

Conceptually:

```text
User Question
      +
Retrieved Documents
      +
System Instructions
      |
      v
Final Prompt
```

For example:

```text
User question:
"What is our refund policy?"

Retrieved context:
"Customers can request a refund within 30 days..."

System instructions:
"Answer using the provided context."

                ↓

          Final Prompt
```

Haystack now sends this final prompt to the LLM.

---

# 12. Step 9 – Haystack communicates with vLLM

Haystack communicates with the **vLLM inference server** through an internal HTTP/API request.

Conceptually:

```text
Haystack EC2
      |
      | HTTP API
      v
vLLM Inference Server
```

The vLLM server is running on GPU-backed infrastructure.

The important point is that **vLLM is an internal inference service**.

The user does not directly access vLLM.

The application controls the communication with vLLM.

---

# 13. Step 10 – What happens inside vLLM?

vLLM is responsible for serving the LLM and performing inference.

The model is loaded into the GPU memory of the GPU-enabled server.

The flow inside the inference layer is:

```text
Haystack
   |
   | HTTP request
   v
vLLM
   |
   | Model inference
   v
GPU
   |
   v
LLM
   |
   v
Generated Tokens
```

The important distinction is:

### Haystack → vLLM

This is **network/API communication**.

### vLLM → GPU

This is **local GPU computation through the NVIDIA/CUDA stack**.

It is not an HTTP API call.

The GPU performs the computationally intensive operations required for LLM inference.

---

# 14. Step 11 – vLLM returns the response

After inference is completed, vLLM returns the generated response to Haystack.

```text
vLLM
  |
  | HTTP response
  v
Haystack
```

Haystack can then perform any required post-processing and prepare the final application response.

---

# 15. Step 12 – Response goes back to the user

The response travels back through the application path:

```text
LLM
 ↓
vLLM
 ↓
Haystack
 ↓
ALB
 ↓
API Gateway
 ↓
User
```

So the complete request-response path is:

```text
                REQUEST
                   |
                   v
                 USER
                   |
                HTTPS
                   |
                   v
             API Gateway
                   |
              HTTP/HTTPS
                   |
                   v
                  ALB
                   |
                   v
          Haystack EC2 ASG
                   |
          +--------+--------+
          |        |        |
          v        v        v
      Embedding  Milvus   vLLM
       Service    DB       |
                          GPU
                           |
                          LLM
                           |
                           v
                       RESPONSE
                           |
                           v
                       Haystack
                           |
                           v
                          ALB
                           |
                           v
                     API Gateway
                           |
                           v
                         USER
```

---

# 16. How do the APIs communicate internally?

This is an important point if the interviewer asks:

**"How do your services communicate with each other?"**

We had different types of communication depending on the component.

### User → API Gateway

```text
HTTPS
```

The external user request enters through the API Gateway.

### API Gateway → ALB

```text
HTTP/HTTPS integration
```

API Gateway forwards the request to the backend.

### ALB → Haystack

```text
HTTP/HTTPS
```

The ALB forwards the request to a healthy Haystack EC2 target.

### Haystack → Embedding Service

```text
Internal service/API communication
```

Haystack calls the embedding service when required.

### Haystack → Milvus

```text
Internal database/service communication
```

Haystack performs vector retrieval against Milvus.

### Haystack → vLLM

```text
Internal HTTP API
```

Haystack sends the final prompt to vLLM.

### vLLM → GPU

```text
CUDA / NVIDIA GPU runtime
```

This is local GPU computation rather than network communication.

Therefore, the important concept is:

> **The user-facing request enters through API Gateway and ALB, while Haystack internally orchestrates communication with the embedding service, Milvus, and vLLM.**

---

# 17. Why did we need Auto Scaling?

Now coming to the main infrastructure challenge.

We needed the Haystack application layer to handle changing user traffic.

Initially, the obvious approach was to scale based on CPU utilization.

For example:

```text
CPU > 70%
     ↓
Scale out
```

But during load testing, we found that this didn't represent our application's actual workload.

Our application was not primarily CPU-bound.

It was **latency-bound**.

---

# 18. Why was the application latency-bound?

Consider one user request.

Haystack might perform:

```text
Receive request
      ↓
Call Milvus
      ↓
WAIT
      ↓
Call Embedding Service
      ↓
WAIT
      ↓
Call vLLM
      ↓
WAIT
      ↓
Return response
```

During all those waiting periods, the Haystack EC2 instance is not necessarily consuming significant CPU.

Our load tests demonstrated this behavior.

We observed:

```text
CPU utilization       → approximately 35–45%
Memory utilization    → relatively stable
Response time         → increasing
Active requests       → accumulating
```

So the infrastructure could appear healthy from a CPU/memory perspective while users were actually experiencing slower responses.

This was the key observation that caused us to change our scaling strategy.

---

# 19. Why did we select RequestCountPerTarget?

Since all requests were coming through the ALB, we looked at the **RequestCountPerTarget** metric.

This metric represents the average number of requests being handled by each healthy target.

That gave us a much better representation of actual application demand.

Instead of asking:

> "How busy is the CPU?"

we were asking:

> "How many requests is each Haystack server handling?"

As user traffic increases:

```text
More users
    ↓
More requests
    ↓
ALB receives more traffic
    ↓
More requests per Haystack target
    ↓
RequestCountPerTarget increases
```

This aligned much better with our application's actual workload.

---

# 20. How did we determine 180 requests per target?

We didn't simply choose 180 as an arbitrary number.

We derived it from **load testing**.

Our baseline infrastructure was:

```text
2 Haystack servers
1 vLLM GPU server
```

During testing, this configuration could consistently handle approximately:

```text
60 requests / 10 seconds
```

We converted that to requests per minute:

```text
60 × 6
=
360 requests/minute
```

We then divided the workload across our two Haystack instances:

```text
360 / 2
=
180 requests/target/minute
```

Therefore:

```text
RequestCountPerTarget threshold
≈ 180 requests/minute
```

This became our scale-out threshold.

---

# 21. How did the Auto Scaling policy work?

Our Haystack ASG was configured approximately as:

```text
Minimum Capacity  = 2
Desired Capacity  = 2
Maximum Capacity  = 4
```

CloudWatch monitored the ALB's RequestCountPerTarget metric.

When the metric crossed approximately:

```text
180 requests/target/minute
```

for the configured evaluation period, the CloudWatch alarm triggered the scaling action.

The ASG then launched another Haystack EC2 instance.

The process was:

```text
Traffic increases
      ↓
RequestCountPerTarget increases
      ↓
CloudWatch alarm
      ↓
ASG scale-out
      ↓
New EC2 instance launched
      ↓
Haystack application starts
      ↓
Health check passes
      ↓
Instance registered with ALB
      ↓
ALB sends traffic to new instance
```

Similarly, when traffic reduced and remained below the lower threshold for a sustained period, the ASG could scale in.

We used evaluation/cooldown periods to prevent short-lived traffic spikes from causing unnecessary scaling actions.

---

# 22. Example of scale-out

Suppose traffic suddenly increases to:

```text
720 requests/minute
```

With only two Haystack instances:

```text
720 / 2
=
360 requests/target/minute
```

Our threshold was approximately:

```text
180 requests/target/minute
```

Therefore:

```text
360 > 180
```

The scaling policy is triggered.

A third Haystack EC2 instance is launched.

Once it becomes healthy:

```text
                 ALB
                  |
        +---------+---------+
        |         |         |
        v         v         v
      EC2-1     EC2-2     EC2-3
```

The workload becomes:

```text
720 / 3
=
240 requests/target/minute
```

The workload per server decreases, improving the overall stability and response time.

If traffic continues to increase, another instance can be added until the ASG reaches its maximum capacity of four.

---

# 23. Why didn't we use memory utilization?

We also evaluated memory utilization.

However, during our testing, memory remained relatively stable.

The application wasn't continuously consuming significantly more memory as request volume increased.

The main problem was waiting for downstream services.

Therefore, memory was not a good indicator of increasing user demand and wasn't selected as the primary scaling metric.

---

# 24. Why did we keep Haystack and vLLM as separate scaling domains?

This is one of the most important architectural decisions.

Haystack and vLLM have completely different responsibilities.

### Haystack

Haystack is the orchestration layer.

```text
User Request
     ↓
Haystack
     ↓
Milvus
     ↓
Embedding
     ↓
Prompt Construction
     ↓
vLLM
     ↓
Response
```

The Haystack layer primarily deals with request orchestration and downstream service calls.

Therefore, request volume was a good workload indicator.

### vLLM

vLLM performs the actual LLM inference.

Its important capacity factors include:

* GPU utilization
* GPU memory
* Concurrent inference requests
* Inference latency
* Requests waiting for GPU execution

Therefore, the GPU layer has a completely different bottleneck.

For example, suppose we scale from two Haystack servers to four:

```text
Haystack-1
Haystack-2
Haystack-3
Haystack-4
      |
      v
   vLLM GPU
    100%
```

Adding more Haystack servers won't solve the problem if the GPU is already saturated.

All those additional requests will eventually wait at the vLLM inference layer.

---

# 25. Why didn't we scale GPU infrastructure aggressively?

The other reason was **cost**.

Standard EC2 compute instances for Haystack are relatively inexpensive compared with GPU-backed EC2 instances.

GPU infrastructure is significantly more expensive.

Therefore, we didn't want to launch GPU instances simply because application traffic increased.

We treated the GPU layer as a separate scaling domain and evaluated its actual inference capacity independently.

This prevented unnecessary GPU provisioning and helped control infrastructure costs.

---

# 26. What was my responsibility?

My responsibility was primarily on the infrastructure and SRE side.

I worked on:

* Designing the AWS infrastructure
* Deploying the application on EC2
* Configuring the ALB
* Configuring Auto Scaling Groups
* Creating CloudWatch alarms
* Selecting the scaling metric
* Performing load testing
* Analyzing CPU and memory behavior
* Analyzing request volume and response latency
* Determining the RequestCountPerTarget threshold
* Validating scale-out behavior
* Validating scale-in behavior
* Monitoring application performance

The key part of my contribution was not simply configuring an ASG.

It was **identifying the correct scaling signal based on the application's actual behavior**.

---

# 27. How I would explain the complete project in an interview

If an interviewer asks:

**"Can you explain the architecture and scaling strategy of your LLM application?"**

I would give this answer:

> "I worked on an LLM-based RAG application running on AWS. We deployed the application layer on EC2, with multiple Haystack application servers behind an Application Load Balancer. These EC2 instances were managed through an Auto Scaling Group. We also had an embedding service, Milvus as our vector database, and a vLLM inference server running on GPU infrastructure.
>
> From the request flow perspective, the user sends the request to our API endpoint over HTTPS. The request first reaches API Gateway, which acts as our API management layer where we can handle authentication, authorization, throttling and rate limiting. API Gateway then forwards the request to the backend through the configured integration, and the request reaches our Application Load Balancer.
>
> The ALB distributes the request to one of the healthy Haystack EC2 instances. Haystack acts as the orchestration layer. It receives the user query and, as part of the RAG workflow, communicates with the embedding service when required and queries Milvus to retrieve relevant documents. Haystack then combines the user's question, the retrieved context and the required instructions to construct the final prompt.
>
> Haystack then sends that prompt to our internal vLLM inference server using an HTTP API. vLLM is deployed on GPU-backed infrastructure and performs the actual LLM inference using the GPU. The communication between Haystack and vLLM is an internal API call, whereas vLLM communicates with the GPU through the NVIDIA/CUDA stack for local computation.
>
> Once vLLM generates the response, it returns it to Haystack. Haystack prepares the final response and sends it back through the ALB and API Gateway to the user.
>
> For scaling, initially we considered CPU and memory utilization. However, during load testing we found that our application was not CPU-bound; it was more latency-bound. The Haystack servers spent significant time waiting for downstream services such as Milvus and vLLM. We observed CPU utilization around 35 to 45 percent while response times were increasing and active requests were accumulating. So CPU and memory weren't good indicators of actual workload.
>
> Since every request passed through the ALB, we selected the ALB RequestCountPerTarget metric. This metric represented the average number of requests handled by each Haystack target and therefore gave us a better indication of actual application demand.
>
> We derived the threshold from load testing. Our baseline of two Haystack servers and one vLLM GPU server handled approximately 60 requests every 10 seconds while maintaining acceptable response times. That translated to 360 requests per minute. Dividing that across two Haystack targets gave us approximately 180 requests per target per minute. We therefore used approximately 180 requests per target per minute as our scale-out threshold.
>
> Our Haystack Auto Scaling Group had a minimum capacity of two, desired capacity of two, and maximum capacity of four. When RequestCountPerTarget crossed the configured threshold for the required evaluation period, CloudWatch triggered the scaling policy and the ASG launched another EC2 instance. Once the new instance passed its health check, the ALB started distributing traffic to it. Similarly, when traffic decreased and remained below the scale-in threshold for a sustained period, instances could be removed.
>
> We kept Haystack and vLLM as separate scaling domains because their bottlenecks were different. Haystack was primarily responsible for orchestration and downstream communication, while vLLM was responsible for GPU-intensive LLM inference. Adding more Haystack servers would not solve a GPU bottleneck if the vLLM server was already saturated. Also, GPU instances were significantly more expensive, so we wanted to avoid unnecessary GPU provisioning.
>
> Overall, the main learning from this project was that the scaling metric should represent the application's actual bottleneck. Instead of blindly using CPU utilization, we used load testing to understand the application behavior and selected RequestCountPerTarget because it more accurately represented the workload handled by each Haystack server."
