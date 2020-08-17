#!/usr/bin/env python3

import boto3
import json
import logging
import os

from botocore.exceptions import ClientError

from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError


LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)
logging.getLogger('boto3').setLevel(logging.CRITICAL)
logging.getLogger('botocore').setLevel(logging.CRITICAL)


def send_to_slack(slack_message, slack_webhook_url):
    status = True
    LOGGER.info("sending slack message")

    req = Request(slack_webhook_url, json.dumps(slack_message).encode('utf-8'))
    try:
        response = urlopen(req)
        response.read()
        LOGGER.info("Message posted to %s", slack_message['channel'])
    except HTTPError as e:
        LOGGER.error("Request failed: %d %s", e.code, e.reason)
    except URLError as e:
        LOGGER.error("Server connection failed: %s", e.reason)

    return status


def get_slack_webhook_url(ssm_parameter):
    ssm_client = boto3.client('ssm')
    slack_url = None

    try:
        response = ssm_client.get_parameter(
            Name=ssm_parameter,
            WithDecryption=True
        )
        slack_url = response['Parameter']['Value']
    except ClientError as e:
        LOGGER.error(
            "Unexpected error getting SSM param: {}".format(
                e.response['Error']['Code']
            )
        )
    return slack_url


def lambda_handler(event, context):
    LOGGER.info('REQUEST RECEIVED: {}'.format(json.dumps(event, default=str)))

    slack_payload = json.loads(event['Records'][0]['Sns']['Message'])
    LOGGER.info("Message: " + str(slack_payload))

    slack_channel = os.environ['SLACK_CHANNEL']
    slack_webhook_ssm_parm = os.environ['SSM_SLACK_WEBHOOK']
    slack_webhook_url = get_slack_webhook_url(slack_webhook_ssm_parm)

    icon_url = slack_payload.get(
        "icon_url",
        "https://www.shareicon.net/data/128x128/2015/08/28/92212_copy_512x512.png"
    )

    slack_body = {
        'username': slack_payload.get("username", ""),
        'icon_url': icon_url,
        'channel': slack_channel,
        'attachments': slack_payload.get("attachments"),
        'text': slack_payload.get("text")
    }

    if slack_webhook_url:
        status = send_to_slack(slack_body, slack_webhook_url)
    else:
        LOGGER.error("Unable to obtain the Slack webhook URL to post to")

    return status
