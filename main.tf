#default
provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

#hostnames for ec resources
variable "app_hostnames" {
  type = "map"
  default = {
    "0" = "app-1.us-east.mydomain.com"
  }
}

variable "web_hostnames" {
  type = "map"
  default = {
    "0" = "web-1.us-east.mydomain.com"
    "1" = "web-2.us-east.mydomain.com"
  }
}

variable "proc_hostnames" {
  type = "map"
  default = {
    "0" = "proc-1.us-east.mydomain.com"
  }
}


#ami to build from
variable "aws_amis" {
  type = "map"
  default = {
    us-east-1 = "ami-0d729a60"
  }
}

resource "aws_security_group" "prod-b-elb" {
    name = "www-elb"
    description = "HTTP/HTTPS from anywhere"
    vpc_id = "${var.vpc_id}"

    ingress {
        from_port = "80"
        to_port = "80"
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }

    ingress {
        from_port = "443"
        to_port = "443"
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
  tags {
    Name = "prod-elb-sec"
  }
}

#create an elastic load balancer
resource "aws_elb" "prod-b-elb" {
  name = "prod-b-elb"
  security_groups = ["${aws_security_group.prod-b-elb.id}"]
  subnets = ["subnet-e4e40d8f"]

  #bucket to store access logs
  access_logs {
    bucket = "propdata-logs"
    bucket_prefix = "elb-access"
    interval = 60
  }

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  listener {
    instance_port = 443
    instance_protocol = "tcp"
    lb_port = 443
    lb_protocol = "tcp"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }

  #register web-* instances to ELB resource
  instances = ["${aws_instance.web.*.id}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags {
    Name = "prod-elb"
  }
}

#template files to set EC2 user data
resource "template_file" "app_server_init" {
  count = "${var.app_count}"
  template = "${file("web_init.tpl")}"
  vars {
    hostname = "${lookup(var.app_hostnames, count.index)}"
    device_name = "/dev/xvdf"
    mount_point = "/srv/data"
  }
}

resource "template_file" "web_server_init" {
  count = "${var.web_count}"
  template = "${file("web_init.tpl")}"
  vars {
    hostname = "${lookup(var.web_hostnames, count.index)}"
    device_name = "/dev/xvdf"
    mount_point = "/srv/data"
  }
}

resource "template_file" "proc_server_init" {
  count = "${var.proc_count}"
  template = "${file("web_init.tpl")}"
  vars {
    hostname = "${lookup(var.proc_hostnames, count.index)}"
    device_name = "/dev/xvdf"
    mount_point = "/srv/data"
  }
}

#app server instance
resource "aws_instance" "app" {
    count = "${var.app_count}"
    ami = "${var.aws_amis}"
    instance_type = "${var.instance_type}"
    key_name= "${var.key_name}"
    subnet_id= "${var.subnet_id}"
    security_groups = [ "${var.security_groups}" ]
    user_data = "${element(template_file.app_server_init.*.rendered, count.index)}"

  tags {
      Name = "${format("prod-app-%03d", count.index + 1)}"
    }    
}

#nginx webserver instance
resource "aws_instance" "web" {
    count = "${var.web_count}"
    ami = "${var.aws_amis}"
    instance_type = "${var.instance_type}"
    key_name= "${var.key_name}"
    subnet_id= "${var.subnet_id}"
    security_groups = [ "${var.security_groups}" ]
    user_data = "${element(template_file.web_server_init.*.rendered, count.index)}"

  tags {
      Name = "${format("prod-web-%03d", count.index + 1)}"
    }    
}

#proc server instance
resource "aws_instance" "proc" {
    count = "${var.proc_count}"
    ami = "${var.aws_amis}"
    instance_type = "${var.instance_type}"
    key_name= "${var.key_name}"
    subnet_id= "${var.subnet_id}"
    security_groups = [ "${var.security_groups}" ]
    user_data = "${element(template_file.proc_server_init.*.rendered, count.index)}"

  tags {
      Name = "${format("prod-proc-%03d", count.index + 1)}"
    }    
}

#app server ebs volume
resource "aws_ebs_volume" "app_data" {
    count = "${var.app_count}"
    availability_zone = "${var.availability_zone}"
    size = 25
    tags {
        Name = "${format("app-%03d-ebs", count.index + 1)}"
    }
}

#web server ebs volume
resource "aws_ebs_volume" "web_data" {
    count = "${var.web_count}"
    availability_zone = "${var.availability_zone}"
    size = 50
    tags {
        Name = "${format("web-%03d-ebs", count.index + 1)}"
    }
}

#proc server ebs volume
resource "aws_ebs_volume" "proc_data" {
    count = "${var.proc_count}"
    availability_zone = "${var.availability_zone}"
    size = 50
    tags {
        Name = "${format("proc-%03d-ebs", count.index + 1)}"
    }
}

#attach app ebs volume to app ec2
resource "aws_volume_attachment" "ebs_app_att" {
  count = "${var.app_count}"
  device_name = "/dev/xvdf"
  volume_id = "${element(aws_ebs_volume.app_data.*.id, count.index)}"
  instance_id = "${element(aws_instance.app.*.id, count.index)}"

}

#attach web ebs volume to web ec2
resource "aws_volume_attachment" "ebs_web_att" {
  count = "${var.web_count}"
  device_name = "/dev/xvdf"
  volume_id = "${element(aws_ebs_volume.web_data.*.id, count.index)}"
  instance_id = "${element(aws_instance.web.*.id, count.index)}"

}

#attach proc ebs volume to proc ec2
resource "aws_volume_attachment" "ebs_proc_att" {
  count = "${var.proc_count}"
  device_name = "/dev/xvdf"
  volume_id = "${element(aws_ebs_volume.proc_data.*.id, count.index)}"
  instance_id = "${element(aws_instance.proc.*.id, count.index)}"

}

resource "aws_route53_record" "app" {
  count = "${var.app_count}"
  zone_id = "${var.aws_route53_zone_id}"
  name = "${lookup(var.app_hostnames, count.index)}"
  type = "A"
  ttl = "5"
  records = ["${element(aws_instance.app.*.private_ip, count.index)}"]
}

resource "aws_route53_record" "web" {
  count = "${var.web_count}"
  zone_id = "${var.aws_route53_zone_id}"
  name = "${lookup(var.web_hostnames, count.index)}"
  type = "A"
  ttl = "5"
  records = ["${element(aws_instance.web.*.private_ip, count.index)}"]
}

resource "aws_route53_record" "proc" {
  count = "${var.proc_count}"
  zone_id = "${var.aws_route53_zone_id}"
  name = "${lookup(var.proc_hostnames, count.index)}"
  type = "A"
  ttl = "5"
  records = ["${element(aws_instance.proc.*.private_ip, count.index)}"]
}




