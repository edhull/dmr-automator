variable dmr_clamav_updater {
  description = "Name for the DMR ClamAV Updater. This will be used to name the Lambda and IAM Role"
  default = "dmr-clamav-updater"
}

resource "aws_lambda_alias" "dmr_clamav_updater" {
  name              = var.dmr_clamav_updater
  description       = "Handle DMR requests"
  function_name     = aws_lambda_function.dmr_clamav_updater.function_name
  function_version  = "$LATEST"
}

resource "aws_lambda_function" "dmr_clamav_updater" {
  filename          = "functions/dmr-clamav.zip"
  function_name     = var.dmr_clamav_updater
  role              = aws_iam_role.dmr_clamav_updater.arn
  handler           = "update.lambda_handler"
  runtime           = "python3.7"
  source_code_hash  = filebase64sha256("functions/dmr-clamav.zip")
  timeout           = "600"
  memory_size       = "1680"
  environment {
    variables      = {
       AV_DEFINITION_S3_BUCKET           = aws_s3_bucket.dmr_clamav_bucket.id
    }
  }
}

resource "aws_cloudwatch_log_group" "dmr_clamav_updater" {
  name              = "/aws/lambda/${aws_lambda_function.dmr_clamav_updater.function_name}"
  retention_in_days = "1"
}

resource "aws_iam_role" "dmr_clamav_updater" {
  name              = var.dmr_clamav_updater
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
    Name          = var.dmr_clamav_updater
  }
}

resource "aws_iam_policy" "iam_dmr_clamav_updater" {
  name            = "iam-${var.dmr_clamav_updater}"
  path            = "/"
  description     = ""

  policy = <<EOF
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Sid":"WriteCloudWatchLogs",
         "Effect":"Allow",
         "Action":[
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
         ],
         "Resource":"*"
      },
      {
         "Sid":"s3GetAndPutWithTagging",
         "Action":[
            "s3:GetObject",
            "s3:GetObjectTagging",
            "s3:PutObject",
            "s3:PutObjectTagging",
            "s3:PutObjectVersionTagging"
         ],
         "Effect":"Allow",
         "Resource":[
            "arn:aws:s3:::${aws_s3_bucket.dmr_clamav_bucket.id}/*"
         ]
      },
      {
         "Sid": "s3HeadObject",
         "Effect": "Allow",
         "Action": "s3:ListBucket",
         "Resource": [
             "arn:aws:s3:::${aws_s3_bucket.dmr_clamav_bucket.id}/*",
             "arn:aws:s3:::${aws_s3_bucket.dmr_clamav_bucket.id}"
         ]
      }
   ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dmr_clamav_updater" {
  role                  = aws_iam_role.dmr_clamav_updater.name
  policy_arn            = aws_iam_policy.iam_dmr_clamav_updater.arn
}

resource "aws_cloudwatch_event_rule" "dmr_clamav_schedule" {
    name                = "clamav-daily"
    description         = "Fires every day"
    schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "dmr_clamav_schedule" {
    rule                = aws_cloudwatch_event_rule.dmr_clamav_schedule.name
    target_id           = aws_lambda_function.dmr_clamav_updater.function_name
    arn                 = aws_lambda_function.dmr_clamav_updater.arn
}

resource "aws_lambda_permission" "dmr_clamav_allow_scheduled_update" {
    statement_id        = "AllowExecutionFromCloudWatch"
    action              = "lambda:InvokeFunction"
    function_name       = aws_lambda_function.dmr_clamav_updater.function_name
    principal           = "events.amazonaws.com"
    source_arn          = aws_cloudwatch_event_rule.dmr_clamav_schedule.arn
}