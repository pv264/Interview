# Kubernetes CrashLoopBackOff Troubleshooting

If I see a pod in `CrashLoopBackOff`, I first check the pod status and describe the pod to understand why the container is restarting.

In this case, `kubectl describe pod` showed that the container was starting successfully but then terminating with **exit code 1**. It was not an `OOMKilled` issue, and the image was pulled successfully.

Next, I checked the application logs using:

`
kubectl logs <pod-name> -n <namespace>

The logs showed that the application was failing during startup because a required environment variable, PAYMENT_API_KEY, was missing.

I then checked the Deployment configuration to verify whether this environment variable was being injected into the container. I found that the Deployment had variables such as:

DATABASE_URL
LOG_LEVEL
PAYMENT_REGION

But PAYMENT_API_KEY was missing.

Since an API key is normally stored in a Kubernetes Secret, I checked the Secrets in the namespace and found:

payment-api-secret

I would then describe the Secret to verify whether the expected key, PAYMENT_API_KEY, exists..

If the key exists, I would check whether the Deployment is referencing the correct Secret and key name.

If it doesn't exist, I would work with the application/configuration owner to add the required key to the Secret and update the Deployment.

Finally, I would restart or redeploy the pod and verify that it reaches Running state and that the restart count stops increasing.


| Exit code | Remember it as                   |
| --------- | -------------------------------- |
| **1**     | Application error                |
| **126**   | Command exists but can't execute |
| **127**   | Command not found                |
| **137**   | SIGKILL — investigate OOMKilled  |



# Interview-Ready Exit Code 126 Example

> **"We had a Kubernetes deployment where one of the pods went into `CrashLoopBackOff`. I started by checking the pod using `kubectl describe pod` and noticed that the container was terminating with exit code 126.**
>
> **I know exit code 126 generally means that the command was found but could not be executed, so I checked the container logs. The logs showed `permission denied` while trying to execute the application's `entrypoint.sh` script.**
>
> **I then checked the Deployment configuration and noticed that the container was running with a non-root user through the `securityContext`. The application had previously been running as root, so I suspected a file-permission or ownership issue.**
>
> **I then checked the Dockerfile and found that the `entrypoint.sh` script was owned by root and didn't have execute permissions for the user running the container.**
>
> **I fixed the Dockerfile by ensuring the script had the correct ownership and execute permissions, for example using `chmod +x` and `chown` for the application user. I rebuilt the Docker image, pushed the new image to the registry, and redeployed the application.**
>
> **After the deployment, I verified that the pod reached `Running` state, the restart count stopped increasing, and the application logs showed successful startup."**




