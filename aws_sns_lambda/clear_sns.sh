#!/bin/bash

containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}


a=`aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:us-west-2:12345:phantom_ecs_asg_lifecycle_target | jq .Subscriptions`

b=`aws sqs list-queues --region us-west-2 --queue-name-prefix phantom-ecs-asg-lifecycle-target | jq .QueueUrls[] | tr -d '"' | awk -F[/] '{print $NF}'`

i=0
l_inst=`aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:us-west-2:12345:phantom_ecs_asg_lifecycle_target`
while(true)
do
 inst=` echo $l_inst | jq .Subscriptions[$i].Endpoint | tr -d '"' | awk -F[:] '{print $NF}'`
 echo $inst

 containsElement $inst "${b[@]}"
 if [ $? != 0 ]
 then
    subs=`echo $l_inst | jq .Subscriptions[$i].SubscriptionArn | tr -d '"'`
    aws sns unsubscribe --region us-west-2 --subscription-arn $subs
 fi
 if [ -z $inst ]
 then
    break
 fi

 ((i=i+1))
done


# aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:us-west-2:12345:phantom_ecs_asg_lifecycle_target | jq .Subscriptions[].Endpoint | tr -d '"' | awk -F[:] '{print $NF}'