# deployment of an application with the Google Global Load Balancer 
Demonstration of the world wide deployment of the paas-monitor on Google Compute Engine.

It implements the following diagram in Terraform. 

![the HTTPS Global Load Balancer](https://cloud.google.com/load-balancing/images/basic-http-load-balancer.svg)

Read the [corresponding blog](https://binx.io/blog/2018/11/19/how-to-configure-global-load-balancing-with-google-cloud-platform/) for details


## Ziti configuration
Copy the paas monitor service identity to paas-monitor-identity.json. It is excluded from git and can safely be deleted after the initial
