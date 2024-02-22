#!/bin/bash

set -e

#include deploy_funcs_vars.sh

poll_opsworks_deployment_complete(){
  deployment_id=$1
  start_time=`date +%s`
  MAX_TIME=600
  while true
  do

    deployment_status=`aws opsworks --region us-east-1 describe-deployments --deployment-ids $deployment_id \
      | jq ".Deployments[]| if .DeploymentId == \"$deployment_id\" then . else empty end|.Status" | tr -d '"'`

    if [ "$deployment_status" == "successful" ];then
      echo "Deployment is successful."
      return 0
    fi
    if [ "$deployment_status" == "failed" ];then
      echo "Error::Deployment is failed!"
      return 1
    fi
    sleep 10
    echo "Polling deployment completion...state is $deployment_status"
    current_time=`date +%s`
    ((elapsed_time=current_time-start_time))
    if test $elapsed_time -gt $MAX_TIME
    then
      echo "Error::: Deployment is taking longer then MAX_TIME specified."
      return 1
    fi
  done

}

opsworksDeploy(){
  if [ $# -lt 3 ];then
    echo "Error:: Provide correct parameters , eg."
    echo "opsworksDeploy <stack_id> <layer_id> <app_id>"
    exit 1
  fi
  stack_id=$1
  layer_id=$2
  app_id=$3


  deployment_id=`aws opsworks --region us-east-1 create-deployment --stack-id $stack_id  \
      --layer-ids $layer_id --app-id $app_id --command "{\"Name\":\"deploy\"}" | jq ".DeploymentId" | tr -d '"'`

  poll_opsworks_deployment_complete "$deployment_id"
}

getOpsworksLayerInstances(){
  layer_id=$1
  hosts=`aws opsworks --region us-east-1 describe-instances --layer-id $layer_id \
    | jq ".Instances[] | if .Status == \"online\" then . else empty end | .Hostname" | tr -d '"'`

  echo "${hosts[@]}"
}
