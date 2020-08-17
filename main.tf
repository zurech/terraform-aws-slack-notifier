locals {
  lambda_path = "slack_notifier.py"

  tags = merge(
    map("Environment", var.environment),
    map("DeployedBy", "terraform"),
    map("ModuleName", "terraform-aws-slack-notifier"),
    map("ModuleVersion", "0.1"),
    var.tags
  )
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

### IAM ###
resource "aws_iam_role" "iam_for_lambda" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
    effect    = "Allow"
  }

  statement {
    actions = [
      "ssm:GetParameter*",
    ]

    resources = ["arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.ssm_slack_webhook}"]
    effect    = "Allow"
  }

  statement {
    actions = [
      "kms:Decrypt",
    ]

    resources = ["arn:${data.aws_partition.current.partition}:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/aws/ssm"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "lambda" {
  path        = "/"
  description = "IAM policy for lambda logging to CloudWatch logs and SSM parameter get. Created by terraform-aws-slack-notifier module."
  policy      = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda.arn

  depends_on = [aws_iam_policy.lambda]
}

### CloudWatch Logs ###
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = var.retention_in_days
  tags              = local.tags
}

### Lambda ###
data "archive_file" "init" {
  type        = "zip"
  source_file = "${path.module}/${local.lambda_path}"
  output_path = "${path.module}/${local.lambda_path}.zip"
}

resource "aws_lambda_function" "slack_notifier" {
  filename         = "${path.module}/${local.lambda_path}.zip"
  function_name    = var.lambda_function_name
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "slack_notifier.lambda_handler"
  timeout          = var.lambda_timeout
  source_code_hash = data.archive_file.init.output_base64sha256

  runtime = "python3.8"

  environment {
    variables = {
      SLACK_CHANNEL     = var.slack_channel
      SSM_SLACK_WEBHOOK = var.ssm_slack_webhook
    }
  }

  tags = local.tags
}
