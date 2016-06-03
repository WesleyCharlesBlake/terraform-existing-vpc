variable "app_count" {
  type = "string"
  description = "How many EC2 instances to deploy"

}

variable "web_count" {
  type = "string"
  description = "How many EC2 instances to deploy"

}

variable "proc_count" {
  type = "string"
  description = "How many EC2 instances to deploy"

}

variable "availability_zone" {
  type = "string"
  description = "Availability zone"

}

variable "aws_region" {
  description = "AWS region to launch servers."
  default = "us-east-1"
}

variable "instance_name" {
    type = "string"
    description = "Instance Name"
}


variable "aws_amis" {
    description = "AMI to use"
}

variable "instance_type" {
    type = "string"
    description = "EC2 instance type"
}

variable "key_name" {
    type = "string"
    description = "key-name to deploy with"
}

variable "security_groups" {
    type = "string"
    description = "Resource secutiry group/s"
}

variable "subnet_id" {
    type = "string"
    description = "Resource Subnet ID"
}

variable "aws_route53_zone_id" {
    type = "string"
    description = "Route53 Zone ID"
}

variable "aws_access_key" {
    type = "string"
    decscription = "Access key"
}

variable "aws_secret_key" {
    type = "string"
    description = "Secret Key"
}

variable "vpc_id" {
    type = "string"
    description = "VPC ID"
}
