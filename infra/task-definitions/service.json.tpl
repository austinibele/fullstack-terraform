{
  "family": "task-definition-node",
  "networkMode": "${network_mode}",
  "requiresCompatibilities": [
    "${launch_type}"
  ],
  "cpu": "${cpu}",
  "memory": "${memory}",
  "executionRoleArn": "${ecs_execution_role}",
  "containerDefinitions": [
    {
      "name": "${frontend_name}",
      "image": "nginx:latest",
      "memoryReservation": ${frontend_memory},
      "portMappings": [
        {
          "containerPort": ${frontend_port},
          "hostPort": ${frontend_port}
        }
      ],
      "environment": [
        {
          "name": "PORT",
          "value": "${frontend_port}"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${log_group}",
          "awslogs-region": "${aws_region}",
          "awslogs-stream-prefix": "ecs-frontend"
        }
      },
      "secrets": []
    },
    {
      "name": "${backend_name}",
      "image": "nginx:latest",
      "memoryReservation": ${backend_memory},
      "portMappings": [
        {
          "containerPort": ${backend_port},
          "hostPort": ${backend_port}
        }
      ],
      "environment": [
        {
          "name": "PORT",
          "value": "${backend_port}"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${log_group}",
          "awslogs-region": "${aws_region}",
          "awslogs-stream-prefix": "ecs-backend"
        }
      },
      "secrets": []
    }
  ]
}