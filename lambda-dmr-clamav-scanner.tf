variable dmr_clamav_scanner {
  description = "Name for the DMR ClamAV Scanner. This will be used to name the Lambda and IAM Role"
  default = "dmr-clamav-scanner"
}

resource "aws_lambda_alias" "dmr_clamav_scanner" {
  name              = "dmr-clamav-scanner"
  description       = "Handle DMR requests"
  function_name     = aws_lambda_function.dmr_clamav_scanner.function_name
  function_version  = "$LATEST"
}

resource "aws_lambda_function" "dmr_clamav_scanner" {
  filename          = "functions/dmr-clamav.zip"
  function_name     = var.dmr_clamav_scanner
  role              = aws_iam_role.dmr_clamav_scanner.arn
  handler           = "scan.lambda_handler"
  runtime           = "python3.7"
  source_code_hash  = filebase64sha256("functions/dmr-clamav.zip")
  timeout           = "600"
  memory_size       = "2048"
  environment {
    variables      = {
      AV_DEFINITION_S3_BUCKET           = aws_s3_bucket.dmr_clamav_bucket.id
      AV_STATUS_SNS_PUBLISH_CLEAN       = false
      AV_STATUS_SNS_PUBLISH_INFECTED    = false
      AV_STATUS_METADATA                = "dmr-av-status"
      AV_DELIVERY_BUCKET                = aws_s3_bucket.dmr_delivery_bucket.id
    }
  }
}

data "archive_file" "dmr_clamav-scanner" {
    type            = "zip"
    source_dir      = "dmr-clamav"
    output_path     = "functions/dmr-clamav.zip"
}

resource "aws_cloudwatch_log_group" "dmr_clamav_scanner" {
  name              = "/aws/lambda/${aws_lambda_function.dmr_clamav_scanner.function_name}"
  retention_in_days = "1"
}

resource "aws_iam_role" "dmr_clamav_scanner" {
  name              = var.dmr_clamav_scanner

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
    Name          = var.dmr_clamav_scanner
  }
}

resource "aws_iam_policy" "iam_dmr_clamav_scanner" {
  name            = "iam-${var.dmr_clamav_scanner}"
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
         "Sid":"s3AntiVirusScan",
         "Action":[
            "s3:GetObject",
            "s3:GetObjectTagging",
            "s3:GetObjectVersion",
            "s3:PutObjectTagging",
            "s3:PutObjectVersionTagging"
         ],
         "Effect":"Allow",
         "Resource": [
           "arn:aws:s3:::${aws_s3_bucket.dmr_staging_bucket.id}/*",
           "arn:aws:s3:::${aws_s3_bucket.dmr_delivery_bucket.id}/*"
         ]
      },
      {
         "Sid":"MoveToDeliveryBucket",
         "Action": "s3:PutObject",
         "Effect":"Allow",
         "Resource": "arn:aws:s3:::${aws_s3_bucket.dmr_delivery_bucket.id}/*"
      },
      {
         "Sid":"CleanupStagingBucket",
         "Action": "s3:DeleteObject",
         "Effect":"Allow",
         "Resource": "arn:aws:s3:::${aws_s3_bucket.dmr_staging_bucket.id}/*"
      },
      {
         "Sid":"s3AntiVirusDefinitions",
         "Action":[
            "s3:GetObject",
            "s3:GetObjectTagging"
         ],
         "Effect":"Allow",
         "Resource": "arn:aws:s3:::${aws_s3_bucket.dmr_clamav_bucket.id}/*"
      },
      {
         "Sid":"kmsDecrypt",
         "Action":[
            "kms:Decrypt"
         ],
         "Effect":"Allow",
         "Resource": [
           "arn:aws:s3:::${aws_s3_bucket.dmr_staging_bucket.id}/*",
           "arn:aws:s3:::${aws_s3_bucket.dmr_delivery_bucket.id}/*"
         ]
      },
      {
         "Sid":"s3HeadObject",
         "Effect":"Allow",
         "Action":"s3:ListBucket",
         "Resource":[
            "arn:aws:s3:::${aws_s3_bucket.dmr_staging_bucket.id}",
            "arn:aws:s3:::${aws_s3_bucket.dmr_delivery_bucket.id}",
            "arn:aws:s3:::${aws_s3_bucket.dmr_clamav_bucket.id}"
         ]
      }
   ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dmr_clamav_scanner" {
  role                  = aws_iam_role.dmr_clamav_scanner.name
  policy_arn            = aws_iam_policy.iam_dmr_clamav_scanner.arn
}

resource "aws_lambda_permission" "dmr_clamav_trigger_scan_event" {
    statement_id        = "AllowExecutionFromS3Bucket"
    action              = "lambda:InvokeFunction"
    function_name       = aws_lambda_function.dmr_clamav_scanner.function_name
    principal           = "s3.amazonaws.com"
    source_arn          = aws_s3_bucket.dmr_staging_bucket.arn
}