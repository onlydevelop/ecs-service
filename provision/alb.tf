resource "aws_alb_target_group" "demo-target-group" {
  name     = "demo-target-group"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.main.id}"
}

resource "aws_alb" "demo-alb" {
  name            = "demo-alb-ecs"
  subnets         = ["${aws_subnet.public.*.id}"]
  security_groups = ["${aws_security_group.lb_sg.id}"]
}

resource "aws_alb_listener" "demo-alb-listner" {
  load_balancer_arn = "${aws_alb.demo-alb.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.demo-target-group.id}"
    type             = "forward"
  }
}
