data "aws_vpc" "default" {
  default = true
}

data "aws_ami_ids" "ubuntu" {

  filter {
    name   = "name"
    values = ["ubuntu/images/ubuntu-*-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.acc_id}"]
}

resource "aws_instance" "media-server" {
  ami                    = "${var.ami_id}"
  instance_type          = "${var.instance_type}"
  user_data              = "${data.template_file.script.rendered}"
  vpc_security_group_ids = ["${aws_security_group.media_sg.id}"]
  key_name               = "${var.ssh_key_name}"
  
  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.ebs_size}"
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/sdg"
    volume_type           = "sc1"
    volume_size           = "500"
    delete_on_termination = false
  }

  tags = {
    Name = "media-server"
  }
}

resource "aws_security_group" "media_sg" {
  name        = "media_sg"
  description = "Allow ALL inbound traffic to a single ip"
  vpc_id      = "${data.aws_vpc.default.id}"

  ingress {
    # ALL (change to whatever ports you need)
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["${var.my_ip}/${var.cidr_range}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "emby_sg_rule" {
  count = "1"
  description = "emby open access"

  security_group_id = "${aws_security_group.media_sg.id}"
  type              = "ingress"

  cidr_blocks      = ["0.0.0.0/0"]

  from_port = 8096
  to_port   = 8096
  protocol  = "tcp"
}

resource "aws_security_group_rule" "sickrage_sg_rule" {
  count = "1"
  description = "sickrage open access"

  security_group_id = "${aws_security_group.media_sg.id}"
  type              = "ingress"

  cidr_blocks      = ["0.0.0.0/0"]

  from_port = 8081
  to_port   = 8081
  protocol  = "tcp"
}