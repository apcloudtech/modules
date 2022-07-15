

data "aws_availability_zones" "all" {}

# data "terraform_remote_state" "db" {
#   backend = "s3"
#   config = {
#     # Replace this with your bucket name!
#     bucket = "terraform-state-apcloudtech"
#     key    = "stage/data-stores/mysql/terraform.tfstate"
#     region = "us-east-2"
#   }
# }


resource "aws_launch_configuration" "web_server_lconfig" {
  image_id        = "ami-02f3416038bdb17fb"
  instance_type   = var.instance_type
  security_groups = [aws_security_group.web_server_sg.id]
  user_data       = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF
  lifecycle {
    create_before_destroy = true
  }
}



resource "aws_autoscaling_group" "web_server_asg" {
  launch_configuration = aws_launch_configuration.web_server_lconfig.id
  availability_zones   = data.aws_availability_zones.all.names

  load_balancers    = [aws_elb.web_server_elb.name]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size
  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }
}

resource "aws_elb" "web_server_elb" {
  name               = "terraform-lb-example"
  security_groups    = [aws_security_group.elb_sg.id]
  availability_zones = data.aws_availability_zones.all.names

  health_check {
    target              = "HTTP:${var.server_port}/"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = var.server_port
    instance_protocol = "http"
  }
}

resource "aws_security_group" "web_server_sg" {
  name = "${var.cluster_name}-sg"

  # Inbound HTTP from anywhere
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elb_sg" {
  name = "${var.cluster_name}-elb"
  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Inbound HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

