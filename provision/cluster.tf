resource "aws_launch_configuration" "launch_configuration" {
  name_prefix          = "demo-app-launch-config-"
  # Amazon ECS-optimized Amazon Linux 2 AMI, for Mumbai
  image_id             = "ami-0d7805fed18723d71"
  instance_type        = "t2.medium"
  key_name             = "${aws_key_pair.demo_key.id}"
  iam_instance_profile = "ecsInstanceRole"
  security_groups      = ["${aws_security_group.private_sg.id}"]
  user_data            = <<-EOF
#!/bin/bash -ex

echo ECS_CLUSTER=demo-app-cluster >> /etc/ecs/ecs.config
echo ECS_BACKEND_HOST= >> /etc/ecs/ecs.config
                        EOF
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name                 = "demo-app-ecs-asg"
  vpc_zone_identifier  = ["${aws_subnet.private.*.id}"]
  launch_configuration = "${aws_launch_configuration.launch_configuration.id}"
  min_size             = "1"
  max_size             = "2"
  desired_capacity     = "1"

  tag {
    key                 = "Name"
    value               = "Demo: ASG"
    propagate_at_launch = true
  }

  tag {
    key                 = "provisioned_by"
    value               = "Dipanjan"
    propagate_at_launch = true
  }
}

resource "aws_ecs_cluster" "cluster" {
    name = "demo-app-cluster"
}
