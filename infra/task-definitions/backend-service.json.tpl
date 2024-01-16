{
  "family": "task-definition-backend",
  "networkMode": "${network_mode}",
  "requiresCompatibilities": [
    "${launch_type}"
  ],
  "cpu": "${cpu}",
  "memory": "${memory}",
  "executionRoleArn": "${ecs_execution_role}",
  "containerDefinitions": [
    {
      "name": "backend",
      "image": "nginx:latest",
      "memoryReservation": ${memory},
      "portMappings": [
        {
          "containerPort": 5252,
          "hostPort": 5252
        }
      ],
      "environment": [
        {
          "name": "PORT",
          "value": "5252"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${log_group}",
          "awslogs-region": "${aws_region}",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "secrets": []
    }
  ]
}