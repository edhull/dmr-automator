variable dmr_jira {
  description = "Name for the DMR Jira Lambda. This will be used to name the Lambda and IAM Role"
  default = "dmr-jira"
}

resource "aws_lambda_alias" "dmr_jira" {
  count             = var.create_jira ? 1 : 0
  name              = var.dmr_jira
  description       = "Interface for Jira during the DMR process"
  function_name     = aws_lambda_function.dmr_jira[0].function_name
  function_version  = "$LATEST"
}

resource "aws_lambda_function" "dmr_jira" {
  count             = var.create_jira ? 1 : 0
  filename          = "functions/dmr-jira.zip"
  function_name     = var.dmr_jira
  role              = aws_iam_role.dmr_jira[0].arn
  handler           = "dmr_jira.handler"
  runtime           = "python3.7"
  source_code_hash  = filebase64sha256("functions/dmr-jira.zip")
  timeout           = "120"
  memory_size       = "256"

  vpc_config {
    subnet_ids          = []
    security_group_ids  = []
  }

  environment {
    variables      = {
      LOG_LEVEL     = var.lambda_loglevel
      SERVER        = var.jira_server
      USER          = var.jira_user
      APIKEY        = var.jira_apikey
      VERIFY        = var.jira_verify
      PYTHONWARNINGS = "ignore:Unverified HTTPS request"
    }
  }
}

resource "aws_cloudwatch_log_group" "dmr_jira" {
  count             = var.create_jira ? 1 : 0
  name              = "/aws/lambda/${aws_lambda_function.dmr_jira[0].function_name}"
  retention_in_days = "14"
}

resource "aws_iam_role" "dmr_jira" {
  count             = var.create_jira ? 1 : 0
  name              = var.dmr_jira

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": 
        ["lambda.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name          = var.dmr_jira
  }
}

resource "aws_iam_policy" "iam_dmr_jira" {
  count           = var.create_jira ? 1 : 0
  name            = "iam-${var.dmr_jira}"
  path            = "/"
  description     = ""

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dmr_jira" {
  count             = var.create_jira ? 1 : 0
  role              = aws_iam_role.dmr_jira[0].name
  policy_arn        = aws_iam_policy.iam_dmr_jira[0].arn
}