# Introduction

An ec2 instance deployed using terraform and ansible. This poc focuses on the ansible deploy after the instance is created.

The terraform deploy needs to wait for ssh to come live on the instance before ansible can run.

Some notes on the install:
* Uses the Amazon 2 ami; that is `systemd` based and modern.
* Installs Oracle `java` jdk from an s3 bucket using `yum localinstall`; this is because of security issues getting it from the Oracle website, url may change in the future, etc. 
* You can switch to `openjdk` in the `systemctl` unit file if you wish, and adapt the playbook to install it via `yum`.
* Installs tomcat from apache website rather than via `yum`. This installs into `/usr/local`, which is a preference for a client I am working for (as is Oracle `java`).

# Using an autoscaling group

If you need an auto scaling group, load balancer, etc, take a look at the examples [here](https://github.com/terraform-providers/terraform-provider-aws/tree/master/examples).

An asg will have a launch config, with the userdata to launch instances. The launch config needs to spin up new instances on the fly and there is no human around to run the remote ansible! Thus we need to create a userdata script that runs ansible locally on the ec2 instance, rather than running ansible remotely. 

We need a script to create a userdata script from our ansible playbook and template. I have created a script for this:
```
./create-userdata.sh
```

Then use `instance.tf_userdata` rather than `instance.tf` (eg rename the latter to `.tf_remote`).

# Thoughts on mixing terraform and ansible

They do not seem to go well together, since ansible typically uses ssh, which needs to become available before we can connect to it.

To keep things simple it might be best to keep the orchestration and config management seperate. Eg use terraform to create your infra and then run ansible afterwards. 
