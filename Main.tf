resource "aws_ecs_cluster" "ecs-with-terraform" {
  name = "ecs-terraform"
}
resource "aws_ecs_task_definition" "Task" {
    family = "task-terraform"
    container_definitions = <<DEFINITION
    [
        {
            "name": "app-first-task",
            "image": "chaitanyakommi/react-portfolio-gourav:latest",
            "essential": true,
            "portMappings": [
                {
                    "containerPort": 3000
                }
            ]
        }
    ]
    DEFINITION
    requires_compatibilities = ["FARGATE"]
    network_mode = "awsvpc"
    memory = "3 GB"
    cpu = "1 vCPU"
}

resource "aws_alb" "lb" {
  name = "terraform-lb"
  load_balancer_type = "application"
  subnets = [var.subnet1,var.subnet2]
  security_groups = [var.sg]
}

resource "aws_lb_target_group" "tg" {
  name = "terraform-tg"
  port = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = "var.vpc"
}

resource "aws_lb_listener" "ls" {
    load_balancer_arn = aws_alb.lb.arn
    port = "80"
    protocol = "HTTP"
    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.tg.arn
    }
}

resource "aws_ecs_service" "ecs-terraform" {
  name = "ecs-with-terraform"
  cluster = aws_ecs_cluster.ecs-with-terraform.id
  task_definition = aws_ecs_task_definition.Task.arn
  launch_type = "FARGATE"
  desired_count = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name = "app-first-task"
    container_port = 3000
  }
  network_configuration {
    subnets = [var.subnet1,var.subnet2]
    assign_public_ip = true
    security_groups = [var.sg]
  }
}

output "lb-url" {
  value = aws_alb.lb.dns_name
}