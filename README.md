# tomcat-aws-terraform-ansible

An ec2 instance deployed using terraform and ansible. I wanted to keep it simple, thus just create a security group and ec2 instance in terraform. This poc focuses on the ansible deploy after the instance is created rather than terraform, which is reasonably straight forward.

If you need an auto scaling group, load balancer, etc, take a look at the examples [here](https://github.com/terraform-providers/terraform-provider-aws/tree/master/examples).

This poc is terraform firing ansible to use a shareable playbook to deploy tomcat. When I say shareable I mean the playbook can be used outside the deploy to update the ec2 instance at a later date.

Some notes on the install:
* Uses the Amazon 2 ami; that is `systemd` based and modern.
* Installs Oracle `java` jdk from an s3 bucket using `yum localinstall`; this is because of security issues getting it from the Oracle website, url may change in the future, etc. 
* You can switch to `openjdk` in the `systemctl` unit file if you wish, and adapt the playbook to install it via `yum`.
* Installs tomcat from apache website rather than via `yum`. This installs into `/usr/local`, which is a preference for a client I am working for (as is Oracle `java`).
