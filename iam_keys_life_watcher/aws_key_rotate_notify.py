#!/usr/bin/python

# This script checks life of AWS access keys if meeting  deadline of 180 days rotation. And if rotation is required
# It notifies users if access key is going to expire in 7 days or 15 days. in slack channel.

import os
import sys
import json
import boto3
import datetime
import dateutil.tz
import slackweb

slack_webhook_url = "https://hooks.slack.com/services/ABCD"
slack_channel = "#infrastructure"
slack_botname = "aws"

iam_client = boto3.client('iam')

users = iam_client.list_users(MaxItems=100)

list_0 = []
list_7_15 = []
list_15 = []

for user in users["Users"]:
  user_name = user["UserName"]
  access_keys_details = iam_client.list_access_keys(UserName=user_name)
  for key in access_keys_details["AccessKeyMetadata"]:
    key_status = key["Status"]
    key_create_date = key["CreateDate"]
    access_key_id = key["AccessKeyId"]
    todays_now = datetime.datetime.now(dateutil.tz.tzlocal())
    delta = todays_now - key_create_date
    life_days = delta.days

    access_keys_last_used = iam_client.get_access_key_last_used(AccessKeyId=access_key_id)
    if "LastUsedDate" in access_keys_last_used["AccessKeyLastUsed"]:
      last_used_date =  access_keys_last_used["AccessKeyLastUsed"]["LastUsedDate"]
      last_used_date_delta = todays_now - last_used_date
      last_usage_days = last_used_date_delta.days
    else:
      last_usage_days=  "N/A"

    aws_url = "https://console.aws.amazon.com/iam/home?region=us-west-2#/users/"+user_name+"?section=security_credentials"

    check_days = life_days - 180
    if check_days < 0:
      check_days = -1
    elif check_days == 0:
      attachment = {"title": "<"+aws_url+"|"+user_name+">", "pretext": ":white_medium_square: *Your AWS key is going to expire in next "+ str(21-check_days) +" Days! <"+aws_url+"|Update>*", "text": "AccessKeyId: " + access_key_id + ", Status: " + key_status + ", Key Created: " + str(life_days) + " days ago, Key Last used: " + str(last_usage_days) + " days ago.", "mrkdwn_in": ["text", "pretext"], "color": "#2C03F9"}
      list_0.append(attachment)
    elif 7 <= check_days < 15:
      attachment = {"title": "<"+aws_url+"|"+user_name+">", "pretext": ":warning: *Your AWS key is going to expire in next "+ str(21-check_days) +" Days! <"+aws_url+"|Update>*", "text": "AccessKeyId: " + access_key_id + ", Status: " + key_status + ", Key Created: " + str(life_days) + " days ago, Key Last used: " + str(last_usage_days) + " days ago.", "mrkdwn_in": ["text", "pretext"], "color": "warning"}
      list_7_15.append(attachment)
    elif 15 <= check_days:
      attachment = {"title": "<"+aws_url+"|"+user_name+">", "pretext": ":boom: *Your AWS key has expired, will be disabled in next 2 days. <"+aws_url+"|Update>*", "text": "AccessKeyId: " + access_key_id + ", Status: " + key_status + ", Key Created: " + str(life_days) + " days ago, Key Last used: " + str(last_usage_days) + " days ago.", "mrkdwn_in": ["text", "pretext"], "color": "danger"}
      list_15.append(attachment)

slack = slackweb.Slack(url=slack_webhook_url)
step = 20
if list_15:
  list_15_len =len(list_15)
  start = 0
  while(list_15_len-start >= step):
      slack.notify(channel=slack_channel, username=slack_botname, icon_emoji=":boom:", attachments=list_15[start:start+step])
      start = start + step
  if list_15_len-start < step:
    slack.notify(channel=slack_channel, username=slack_botname, icon_emoji=":boom:", attachments=list_15[start:list_15_len])

if list_7_15:
  list_7_15_len =len(list_7_15)
  start = 0
  while(list_7_15_len-start >= step):
      slack.notify(channel=slack_channel, username=slack_botname, icon_emoji=":warning:", attachments=list_7_15[start:start+step])
      start = start + step
  if list_7_15_len-start < step:
    slack.notify(channel=slack_channel, username=slack_botname, icon_emoji=":warning:", attachments=list_7_15[start:list_7_15_len])

if list_0:
  list_0_len =len(list_0)
  start = 0
  while(list_0_len-start >= step):
      slack.notify(channel=slack_channel, username=slack_botname, icon_emoji=":white_medium_square:", attachments=list_0[start:start+step])
      start = start + step
  if list_0_len-start < step:
    slack.notify(channel=slack_channel, username=slack_botname, icon_emoji=":white_medium_square:", attachments=list_0[start:list_0_len])

