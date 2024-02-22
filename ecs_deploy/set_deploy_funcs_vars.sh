#!/bin/bash

set -e

ENV="production"
USER="deploy"
HOST="utility1"
SSH_PK="/var/lib/jenkins/.ssh/id_rsa"
SSH_CMD="ssh -i $SSH_PK ${USER}@${HOST}"
APP_DIR="/srv/www/app/current"
RAILS_CONSOLE="RAILS_ENV=$ENV bundle exec rails c"
EXEC_RAKE="RAILS_ENV=$ENV bundle exec rake"
SLACK_HOOK_URL="https://hooks.slack.com/services/abcd"
DD_API_KEY="abcd"
DD_APP_KEY="abcd"
AWS_ECS="aws ecs --region us-west-2"
