module "vpc" {
  source = "./module/vpc"

  vpc_id                  = "10.0.0.0/16"
  public_subnet_id_value  = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  private_subnet_id_value = "10.0.2.0/24"
  availability_zone1      = "us-east-1b"
}

resource "aws_apprunner_vpc_connector" "connector" {
  vpc_connector_name = "vpc_connector"
  subnets            = [module.vpc.public_subnet_id, module.vpc.private_subnet_id]
  security_groups    = [module.vpc.security_group_id]
}

# resource "aws_secretsmanager_secret" "github_pat" {
#   name        = "github-pat"
#   description = "GitHub Personal Access Token for App Runner"
# }

# resource "aws_secretsmanager_secret_version" "github_pat_version" {
#   secret_id = aws_secretsmanager_secret.github_pat.id
#   secret_string = jsonencode({
#     token = ""
#   })
# }

# resource "aws_apprunner_connection" "github_connection" {
#   connection_name = "github-connection"
#   provider_type   = "GITHUB"

#   authentication_configuration {
#     connection_arn = aws_secretsmanager_secret.github_pat.arn
#   }
# }



# # To create apprunner with Source code
# resource "aws_apprunner_connection" "example" {
#   connection_name = "connection1"
#   provider_type   = "GITHUB"

#   tags = {
#     Name = "example-apprunner-connection"
#   }
# }

# To create apprunner From source code

# To get the AMI
data "aws_caller_identity" "current" {}

resource "aws_apprunner_service" "example" {
  service_name = "example"

  source_configuration {
    authentication_configuration {
      connection_arn = "arn:aws:apprunner:us-east-1:992382360976:connection/swigy/963e89506f5f486bbd0836616fadc273" # you will get from apprunner before start go to appruner click connection then you will take ARN
    }
    code_repository {
      code_configuration {
        code_configuration_values {
          build_command = "npm install"
          port          = "3000"
          runtime       = "NODEJS_16"
          start_command = "npm run start"
        }
        configuration_source = "API"
      }
      repository_url = "https://github.com/manoj7894/swiggy-nodejs-devops-project.git"
      source_code_version {
        type  = "BRANCH"
        value = "main"
      }
    }
    auto_deployments_enabled = true
  }

  instance_configuration {
    cpu    = 1024 # 1 vCPU
    memory = 2048 # 2 GB RAM
  }


  health_check_configuration {
    path                = "/"
    interval            = 5
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    protocol            = "TCP"
  }

  network_configuration {
    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.connector.arn
    }
  }

  tags = {
    Name = "example-apprunner-service"
  }
}




# To create apprunner with Private ECR image

# Define the IAM role
resource "aws_iam_role" "apprunner_service_role" {
  name = "MyAppRunnerServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "time_sleep" "waitrolecreate" {
  depends_on      = [aws_iam_role.apprunner_service_role]
  create_duration = "60s"
}

# Define the IAM policy
resource "aws_iam_policy" "apprunner_policy" {
  name        = "apprunner-policy"
  description = "IAM policy for AWS App Runner service with ECR, CloudWatch Logs, and Secrets Manager permissions"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:DescribeImages"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:ListSecrets",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the IAM role
resource "aws_iam_role_policy_attachment" "apprunner_service_policy_attachment" {
  role       = aws_iam_role.apprunner_service_role.name
  policy_arn = aws_iam_policy.apprunner_policy.arn
}

# resource "aws_apprunner_service" "main" {
#   service_name = "sandbox-service"

#   source_configuration {
#     image_repository {
#       image_configuration {
#         port = "3000"
#       }
#       image_identifier      = "992382360976.dkr.ecr.us-east-1.amazonaws.com/swigy:latest"
#       image_repository_type = "ECR"
#     }
#     auto_deployments_enabled = false
#     authentication_configuration {
#       access_role_arn = aws_iam_role.apprunner_service_role.arn
#     }
#   }

#   instance_configuration {
#     cpu    = 1024 # 1 vCPU
#     memory = 2048 # 2 GB RAM
#   }

#   health_check_configuration {
#     # path                = "/"
#     interval            = 5
#     timeout             = 5
#     healthy_threshold   = 3
#     unhealthy_threshold = 3
#     protocol            = "HTTP"           # Give TCP or HTTP no problem
#   }

#   network_configuration {
#     egress_configuration {
#       egress_type       = "VPC"
#       vpc_connector_arn = aws_apprunner_vpc_connector.connector.arn
#     }
#   }

#   tags = {
#     Name = "example-apprunner-service"
#   }

# }


# Create Apprunner with ECR public image
# resource "aws_apprunner_service" "main" {
#   service_name = "sandbox-service"

#   source_configuration {
#     image_repository {
#       image_identifier      = "public.ecr.aws/e4q9g7q1/swigy12:latest"
#       image_repository_type = "ECR_PUBLIC"
#       image_configuration {
#         port = 80
#       }
#     }
#     auto_deployments_enabled = false
#   }

#   instance_configuration {
#     cpu    = 1024 # 1 vCPU
#     memory = 2048 # 2 GB RAM
#   }

#   health_check_configuration {
#     path                = "/"
#     interval            = 5
#     timeout             = 5
#     healthy_threshold   = 3
#     unhealthy_threshold = 3
#     protocol            = "HTTP"           # Give TCP or HTTP no problem
#   }

#   network_configuration {
#     egress_configuration {
#       egress_type       = "VPC"
#       vpc_connector_arn = aws_apprunner_vpc_connector.connector.arn
#     }
#   }

#   tags = {
#     Name = "example-apprunner-service"
#   }

# }











# Extra data

# resource "aws_secretsmanager_secret" "github_token" {
#   name = "github_token"
# }

# resource "aws_secretsmanager_secret_version" "github_token" {
#   secret_id     = aws_secretsmanager_secret.github_token.id
#   secret_string = "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" # Replace with your GitHub token
# }


# resource "aws_apprunner_service" "main" {
#   service_name = "sandbox-service"

# source_configuration {
#   image_repository {
#     image_configuration {
#       port = "3000"
#     }
#     image_identifier      = "public.ecr.aws/e4q9g7q1/swigy:latest"
#     image_repository_type = "ECR"
#   }
#   auto_deployments_enabled = false
#   authentication_configuration {
#     access_role_arn = aws_iam_role.apprunner_service_role.arn
#   }
# }

#   # source_configuration {
#   #   code_repository {
#   #     repository_url = "https://github.com/your-repo/your-app" # Replace with your GitHub repository URL
#   #     source_code_version {
#   #       type  = "BRANCH"
#   #       value = "main" # Replace with your branch name
#   #     }
#   #     connection_arn = aws_secretsmanager_secret.github_token.arn
#   #   }

#   #   code_configuration {
#   #     configuration_source = "REPOSITORY"
#   #     code_configuration_values {
#   #       runtime = "NODEJS_16" # Use appropriate runtime
#   #       build_command = "npm install"
#   #       start_command = "npm run start"
#   #     }
#   #   }

#   #   auto_deployments_enabled = true
#   # }

#   # // Source Configuration
#   # source_configuration {
#   #   authentication_configuration {
#   #     access_role_arn = aws_iam_role.apprunner_service_role.arn
#   #   }

#   #   // Code Configuration for GitHub Repository
#   #   code_configuration {
#   #     configuration_source = "REPOSITORY"

#   #     // GitHub Repository Details
#   #     git_hub_configuration {
#   #       repository_url = "https://github.com/your-username/your-repo"
#   #       branch         = "main"  // Replace with your desired branch

#   #       // Build Configuration
#   #       build_configuration {
#   #         runtime     = "NODEJS_16"  // Replace with your runtime environment
#   #         build_command = "npm install"  // Replace with your build command
#   #         start_command = "npm run start"  // Replace with your start command
#   #       }

#   #       // Optionally, specify subdirectory if your code is not in the root of the repository
#   #       // subdirectory   = "path/to/code"

#   #       // You can also specify environment variables if needed
#   #       // environment_variables = {
#   #       //   "KEY" = "VALUE"
#   #       // }
#   #     }
#   #   }
#   # }

#   source_configuration {

#     code_repository {
#       code_configuration {
#         code_configuration_values {
#           build_command = "npm install"
#           port          = "3000"
#           runtime       = "NODEJS_16"
#           start_command = "npm run start"
#         }
#         configuration_source = "REPOSITORY"
#       }
#       repository_url = "https://github.com/manoj7894/swiggy-nodejs-devops-project.git"
#       source_code_version {
#         type  = "BRANCH"
#         value = "main"
#       }
#     }
#     auto_deployments_enabled = true
#     authentication_configuration {
#       connection_arn = aws_iam_role.apprunner_service_role.arn
#     }
#   }

#   instance_configuration {
#     cpu    = 1024 # 1 vCPU
#     memory = 2048 # 2 GB RAM
#   }


#   health_check_configuration {
#     path                = "/health"
#     interval            = 5
#     timeout             = 5
#     healthy_threshold   = 3
#     unhealthy_threshold = 3
#     protocol            = "HTTP"
#   }

#   network_configuration {
#     egress_configuration {
#       egress_type       = "VPC"
#       vpc_connector_arn = aws_apprunner_vpc_connector.connector.arn
#     }
#   }

#   tags = {
#     Name = "example-apprunner-service"
#   }

# }




# # Define the IAM role
# resource "aws_iam_role" "apprunner_service_role" {
#   name = "MyAppRunnerServiceRole"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Service = "build.apprunner.amazonaws.com"
#         },
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# # Define the IAM policy
# resource "aws_iam_policy" "apprunner_policy" {
#   name        = "apprunner-policy"
#   description = "IAM policy for AWS App Runner service with ECR, CloudWatch Logs, and Secrets Manager permissions"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:GetAuthorizationToken",
#           "ecr:BatchGetImage",
#           "ecr:DescribeImages"
#         ],
#         Resource = "*"
#       },
#       {
#         Effect = "Allow",
#         Action = [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents",
#           "logs:DescribeLogGroups",
#           "logs:DescribeLogStreams"
#         ],
#         Resource = "*"
#       },
#       {
#         Effect = "Allow",
#         Action = [
#           "secretsmanager:GetSecretValue",
#           "secretsmanager:ListSecrets",
#           "secretsmanager:DescribeSecret"
#         ],
#         Resource = "*"
#       },
#       {
#         Effect = "Allow",
#         Action = [
#           "s3:GetObject",
#           "s3:ListBucket"
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }

# # Attach the policy to the IAM role
# resource "aws_iam_role_policy_attachment" "apprunner_service_policy_attachment" {
#   role       = aws_iam_role.apprunner_service_role.name
#   policy_arn = aws_iam_policy.apprunner_policy.arn
# }

# resource "aws_iam_role_policy_attachment" "app_runner" {
#   role       = aws_iam_role.apprunner_service_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
# }
