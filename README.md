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

# Using an autoscaling group

If you need an auto scaling group, load balancer, etc, take a look at the examples [here](https://github.com/terraform-providers/terraform-provider-aws/tree/master/examples).

An asg will have a launch config, with the userdata to launch instances. The launch config needs to spin up new instances on the fly and there is no human around to run the remote ansible! Thus we need to create a userdata script that runs ansible locally on the ec2 instance, rather than running ansible remotely. 

We need a script to create a userdata script from our ansible playbook and template. I have created a script for this:
```
./create-userdata.sh
```

Then use `instance.tf_userdata` rather than `instance.tf` (eg rename the latter to `.tf_remote`). This uses a user data rather than waiting for the ssh port to become available; however it does not include an autoscaling group or launch configuration.

# Thoughts on mixing terraform and ansible

They do not seem to go well together, since ansible typically uses ssh, which needs to become available before we can connect to it. The answer might be to switch to an autoscaling group (asg), which will use a user data to provision the ec2 instances, and then you do not have to worry about the deploy of the ec2 instances. You could embed ansible in the user data. I prefer an asg, since it manages the additional/removal in load balancers, can be scaled up and down at will, and can be autoscaled based on some criteria (eg cpu, etc).

To keep things simple it might be best to keep the orchestration and config management seperate. Eg use terraform to create your infra and then run ansible afterwards. 
