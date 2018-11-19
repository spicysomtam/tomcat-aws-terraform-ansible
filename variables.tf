variable "key_name" {
  default     = "myKeyPair"
}

# amazon linux 2 x86_64
variable "ami" {
  default = "ami-0a5e707736615003c"
}

variable "vpcid" {
  default = "vpc-xxx"
}

variable "subnets" {
  default = ["subnet-xxx"]
}

variable "inst_type" {
  default = "t2.micro"
}

variable "s3bucket" {
  default = "mybucket"
}

# Access the ec2 instance remotely to run ansible; user and key:
variable "ssh_user" {
  default = "ec2-user"
}
variable "ssh_key_private" {
  default = "~/.ssh/aws/mykeypair.pem"
}
