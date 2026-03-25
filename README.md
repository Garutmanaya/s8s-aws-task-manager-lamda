# s8s-aws-task-manager-lamda

Serverless task manager built on AWS with Terraform-managed infrastructure, Python Lambda handlers, DynamoDB storage, Cognito authentication, and a static frontend delivered through S3 and CloudFront.

## Architecture

- `frontend/`: Static browser app for login, task creation, and task listing.
- `lamda/`: Python Lambda handlers for create, list, update, and close task flows.
- `terrafrom/`: Root Terraform configuration plus reusable modules for `auth`, `database`, `tasks_api`, and `frontend`.

## AWS Resources

- Amazon Cognito User Pool and App Client for user authentication
- Amazon DynamoDB table for task storage
- AWS Lambda for task API execution
- Amazon API Gateway for authenticated HTTP endpoints
- Amazon S3 and CloudFront for frontend hosting

## API Routes

- `GET /tasks`: List tasks for the authenticated user
- `POST /tasks`: Create a new task
- `PUT /tasks`: Update an existing task
- `POST /tasks/close`: Mark a task as closed

## Terraform Modules

- `modules/auth`: Provisions Cognito resources
- `modules/database`: Creates the DynamoDB tasks table
- `modules/tasks_api`: Packages Lambda code and exposes API Gateway routes
- `modules/frontend`: Uploads the frontend and injects Cognito/API configuration

## Deploy

1. Update values in [terrafrom/terraform.tfvars](/home/aimlnode/Workplace/Projects/s8s-aws-task-manager-lamda/terrafrom/terraform.tfvars), especially `frontend_bucket`.
2. Initialize Terraform from [terrafrom](/home/aimlnode/Workplace/Projects/s8s-aws-task-manager-lamda/terrafrom).
3. Run `terraform plan`.
4. Run `terraform apply`.

## Notes

- The Terraform stack now packages the Lambda source directly from `lamda/`.
- The frontend HTML is rendered during deployment with the correct Cognito and API values.
