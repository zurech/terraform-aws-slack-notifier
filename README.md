# Lambda slack notifier Terraformm module
Terraform module which creates a Lambda function that sends notifications to slack channel.
The lambda function resend notifications received by SNS to slack channel.
The message send it to the SNS topic need to have the following structure:

```json
{
    "icon_url": "URL of image to be use as avatar in hte slack message. (Optional)",
    "username": "Username used for the slack notification. (Optional)",
    "attachments": "Slack attachment structure. Reference: https://api.slack.com/reference/messaging/attachments#example (Required)",
    "text": "Slack message title (Required)"
}
```

## Requirements
A SSM parameter need to be created with the slack webhook URL. This SSM parameter will be used by the lambda function to get the webhook URL.

## Usage
```hcl
provider "aws" {
  region = "us-east-2"
}

module "slack_notifier" {
  source            = "../"
  environment       = "development"
  slack_channel     = "monitoring"
  ssm_slack_webhook = "/slack_notifier/webhook"
}

resource "aws_lambda_permission" "slack_notifier" {
  statement_id  = "AllowExecutionFromSNSAle"
  action        = "lambda:InvokeFunction"
  function_name = module.slack_notifier.lambda_arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.sns_topic.arn
}

resource "aws_sns_topic" "sns_topic" {
  name = "slack-notifications-topic"
}

resource "aws_sns_topic_subscription" "slack_notifier" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "lambda"
  endpoint  = module.slack_notifier.lambda_arn
}

```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Providers

| Name | Version |
|------|---------|
| archive | n/a |
| aws | >= 2.7.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| environment | Environment name. | `string` | n/a | yes |
| lambda\_function\_name | Lambda function name | `string` | `"slack_notifier"` | no |
| lambda\_timeout | Lambda function name | `string` | `"10"` | no |
| retention\_in\_days | Lambda function logs retention in days. | `string` | `"30"` | no |
| slack\_channel | Slack channel. | `string` | n/a | yes |
| ssm\_slack\_webhook | SSM parameter name to obtain slack webhook. | `string` | `"/slack_notifier/webhook"` | no |
| tags | A mapping of tags to assign to the resources created by the module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| lambda\_arn | The Amazon Resource Name (ARN) identifying your Lambda Function. |
| lambda\_log\_group\_arn | The Amazon Resource Name (ARN) specifying the log group. |
| lambda\_name | Lambda Function unique name. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module managed by [Santiago Zurletti](https://github.com/KiddoATOM).

## License

Apache 2 Licensed. See LICENSE for full details.
