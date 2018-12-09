# Introduction

An ec2 instance deployed using terraform and ansible. This poc focuses on the ansible deploy after the instance is created.

The terraform deploy needs to wait for ssh to come live on the instance before ansible can run.

Some notes on the install:
* Uses the Amazon 2 ami; that is `systemd` based and modern.
* Installs Oracle `java` jdk from an s3 bucket using `yum localinstall`; this is because of security issues getting it from the Oracle website, url may change in the future, etc. 
* You can switch to `openjdk` in the `systemctl` unit file if you wish, and adapt the playbook to install it via `yum`.
* Installs tomcat from apache website rather than via `yum`. This installs into `/usr/local`, which is a preference for a client I am working for (as is Oracle `java`).

# Deploying to aws

Download `terraform` and install it in your path somewhere.

Decide whether you wish to use terraform workspaces (eg different environments). If not workspace `default` (the default) will be used.

Ensure your aws credentials are defined and exported using the default aws env vars; I use AWS_PROFILE since I prefer multiple profiles and the modern way to use to use credentials.

Then just run `terraform apply`.

# Destroying and updating your stack in aws

To destroy the stack, just run `terraform destroy`, and enter `yes` to confirm.

If you update the config, you can run `terraform plan` to see what will be changed, and if you are happy with that, run `terraform apply` to apply the changes in aws.

# instance.tf_userdata

Swapping `instance.tf` for this will switch setting up the instance via ssh/ansible to using an ec2 instance userdata. Userdata is what ec2 uses to customise an instance when it is deployed. This means the deploy will not wait for the ssh port to become available on the instance, and thus is less problematic and a better way to deploy.

The userdata still uses ansible.

The userdata script (`userdata.sh`) is created by running `./create_userdata.sh`. When the `userdata.sh` script is created, you should check the correct bucket name is being passed to the ansible playbook; if not edit the `userdata.sh` (or the `create_userdata.sh` script and re-run the script).

Personally, I think the userdata approach is much better than waiting for ssh to become available, and then provisioning it that way.

# instance.tf_lc_asg_alb

Swapping `instance.tf` for this will switch setting up the instance/s to using a launch config, userdata in the launch config, autoscaling group (asg) and application load balancer. This takes the deploy to the next level; service is provided via a load balancer, you can scale up and down as required, or on some criteria such as cpu load, etc.

See notes on `instance.tf_userdata`, which apply to this deploy. 

Asg min/max/desired, alb health point and status codes are set in the `variables.tf`. 

# Thoughts on mixing terraform and ansible

They do not seem to go well together, since ansible typically uses ssh, which needs to become available before we can connect to it. 

Switching to using an ec2 instance userdata is much easier to implement and manage, but even so generating the userdata with ansible is a bit messy.

Switching to an load balancer, launch config and autoscaling group (asg) is a much slicker deploy. I prefer this, since it manages the additional/removal in load balancers, can be scaled up and down at will, and can be autoscaled based on some criteria (eg cpu, etc).

You could have your own baked ami's, but then you need to manage the images (building/storage/deploying into aws. etc).

To keep things simple it might be best to keep the orchestration and config management seperate. 

Kubernetes solves alot of these issues; containerized apps (no need for userdata and config management like ansible; you create a new image/layer), rolling updates are faster and much slicker than aws alb's/ec2 instances/lc's/asg's. Technology marches on!
