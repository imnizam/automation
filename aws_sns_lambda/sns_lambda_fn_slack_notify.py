# This lambda function is a receiver of SNS notification service. It checks alarm
# state and notify in slack accordingly
def lambda_handler(event, context):
    logger.info("Event: " + str(event))
    message = json.loads(event['Records'][0]['Sns']['Message'])
    logger.info("Message: " + str(message))

    if message['NewStateValue'] in 'ALARM':
        icon = ":boom:"
        color = "danger"
    else:
        icon = ":warning:"
        color = "warning"

    slack_message = {
    "channel": SLACK_CHANNEL,
    "attachments": [{ "mrkdwn_in": ["text"],"color": color, "text": "%s\n*State*: %s\n*LoadBalancerName*: %s\n*Reason*: %s\n_AlarmDescription_: %s" % (icon,message['NewStateValue'],message['Trigger']['Dimensions'][0]['value'],message['NewStateReason'], message['AlarmDescription'])}]
    }

    req = Request(SLACK_HOOK_URL, json.dumps(slack_message))
    try:
        response = urlopen(req)
        response.read()
        logger.info("Message posted to %s", slack_message['channel'])
    except HTTPError as e:
        logger.error("Request failed: %d %s", e.code, e.reason)
    except URLError as e:
        logger.error("Server connection failed: %s", e.reason)