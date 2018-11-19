resource "random_id" "x" {
  byte_length = 4
}

resource "aws_iam_role" "ec2" {
  name = "S3${var.s3bucket}-${local.sk}-${random_id.x.dec}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "s3" {
  name = "S3${var.s3bucket}-${local.sk}-${random_id.x.dec}"
  role = "${aws_iam_role.ec2.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "arn:aws:s3:::${var.s3bucket}",
                "arn:aws:s3:::${var.s3bucket}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:GetObject",
                "s3:GetObjectAcl",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::${var.s3bucket}",
                "arn:aws:s3:::${var.s3bucket}/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "ec2" {
  name = "S3${var.s3bucket}-${local.sk}-${random_id.x.dec}"
  role = "${aws_iam_role.ec2.name}"
}

resource "aws_security_group" "tomcat" {
  name = "${local.sk}-${random_id.x.dec}"
  description = "http:8080 and ssh access."

  vpc_id = "${var.vpcid}"

  # HTTP:8080 access from anywhere
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ssh access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${local.sk}-${random_id.x.dec}"
  }
}

resource "aws_instance" "tomcat" {
  count = "1"
  instance_type = "${var.inst_type}"

  # Iam role allowing access to the s3 bucket to cp the java rpm
  iam_instance_profile = "${aws_iam_instance_profile.ec2.name}"

  ami = "${var.ami}"

  key_name = "${var.key_name}"

  vpc_security_group_ids = ["${aws_security_group.tomcat.id}"]
  subnet_id              = "${element(var.subnets,count.index)}"

  #Instance tags
  tags {
    Name = "${local.sk}-0"
  }

# Provisioners; run in the order below:

# This one waits until the ssh connection comes alive
  provisioner "remote-exec" {
    inline = [ "echo hello" ]

    connection {
      type = "ssh"
      user = "${var.ssh_user}"
      private_key = "${file(var.ssh_key_private)}"
    }
  }

# This one runs ansible locally to configure the remote ec2 instance
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.ssh_user} -i '${self.public_ip},' --private-key ${var.ssh_key_private} -b install-tomcat.yaml"
  }
}

output "tomcat-public-dns" {
  value = "${aws_instance.tomcat.public_dns}"
}

