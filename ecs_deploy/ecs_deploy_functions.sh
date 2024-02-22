#!/bin/bash

set -e

#include deploy_funcs_vars.sh

ecs_deploy(){
  if [ $# -lt 2 ];then
    echo "_ecsDeploy <cluster_name> <service_name> <[optional] docker_image_version | default latest>"
    exit 1
  fi

  cluster=$1
  service=$2
  docker_image_version=$3
  if [ -z $docker_image_version ];then
    version="latest"
  fi
  docker_image=""
  if [ "$cluster" == "Staging" ];then
    docker_image="staging-docker-registry.myorg.vpc/phantom:${docker_image_version}"
  else
    docker_image="docker-registry.myorg.vpc/phantom:${docker_image_version}"
  fi

  deploy=`/usr/bin/ecs-deploy --cluster $cluster --service-name $service -i $docker_image -r "us-west-2"`

  if [ $? -ne 0 ];then
    echo "ERROR::ECS service $service deployment failed!"
    return 1
  fi
}

verifyECSServiceIsUp(){
  if [ $# -lt 2 ];then
    echo "Error:: Provide correct parameters , eg."
    echo "verifyECSServiceIsUp <cluster> <service>"
    exit 1
  fi
  cluster=$1
  service=$2
  OBSERVATION_TIMEOUT=90
  MAX_LIFE_TIME=60
  retval="false"

  NEW_TASKDEF=`$AWS_ECS describe-services --services $service --cluster $cluster \
            | jq -r .services[0].taskDefinition`
  every=10
  i=0
  while [ $i -lt $OBSERVATION_TIMEOUT ]
  do
    RUNNING_TASKS=$($AWS_ECS list-tasks --cluster "$cluster"  --service-name "$service" \
            --desired-status RUNNING | jq -r '.taskArns[]')
    STARTED_TIME=$($AWS_ECS describe-tasks --cluster "$cluster" --tasks $RUNNING_TASKS \
          | jq ".tasks[]| if .taskDefinitionArn == \"$NEW_TASKDEF\" then . else empty end|.startedAt")

    for start_time in ${STARTED_TIME[@]}
    do
      started_at=`echo $start_time | awk -F "." '{print $1}'`
      current_time=`date +%s`
      ((diff_sec=current_time-started_at))
      if test $diff_sec -gt $MAX_LIFE_TIME
      then
        retval="true"
        i=$OBSERVATION_TIMEOUT
        break
      fi
    done

    sleep $every
    i=$(( $i + $every ))
  done
  echo $retval
}
poll_ecs_deployment_complete(){
  if [ $# -lt 2 ];then
    echo "Error:: Provide correct parameters , eg."
    echo "poll_ecs_deployment_complete <cluster> <service>"
    exit 1
  fi
  cluster=$1
  service=$2

  MAX_WAIT_TIME=600
  DESIRED_COUNT=`$AWS_ECS describe-services --services $service --cluster $cluster \
              | jq -r .services[0].desiredCount`

  NEW_TASKDEF=`$AWS_ECS describe-services --services $service --cluster $cluster \
              | jq -r .services[0].taskDefinition`

  echo "Waiting for service \"$service\" to maintain Desired count..."
  echo "Desired_count=${DESIRED_COUNT}"
  every=10
  i=0
  while [ $i -lt $MAX_WAIT_TIME ]
  do
    ALL_RUNNING_TASKS=$($AWS_ECS list-tasks --cluster "$cluster"  --service-name "$service" \
              --desired-status RUNNING | jq -r '.taskArns[]')

    RUNNING_TASKS_WITH_NEW_TASK_DEF=$($AWS_ECS describe-tasks --cluster "$cluster" --tasks $ALL_RUNNING_TASKS \
              | jq ".tasks[]| select((.taskDefinitionArn == \"$NEW_TASKDEF\") and .lastStatus == \"RUNNING\") |.lastStatus" | wc -l)

    echo "Runnning_Count=$RUNNING_TASKS_WITH_NEW_TASK_DEF"
    if [ $RUNNING_TASKS_WITH_NEW_TASK_DEF -eq $DESIRED_COUNT ];then
      echo "Successful"
      return 0
    fi
    echo "Waiting for 10 seconds before next poll..."
    sleep $every
    i=$(( $i + $every ))
  done
  echo "ERROR:: Service \"$service\" is not maintaining new Running_tasks(=$RUNNING_TASKS_WITH_NEW_TASK_DEF) equal to desired_count(=$DESIRED_COUNT) , MAX_WAIT_TIME(${MAX_WAIT_TIME}mins) is over! "
  return 1
}

ecsDeployAndVerify(){
  if [ $# -lt 3 ];then
    echo "Error:: Provide correct parameters , eg."
    echo "deployAndVerify <cluster> <docker_image_version> <services>"
    exit 1
  fi

  cluster="${1}"
  shift
  docker_image_version="${1}"
  shift
  declare -a services=("${@}")

  for service in ${services[@]}
  do
    echo "Deploying service $service"
    ecs_deploy $cluster $service $docker_image_version
  done

  declare -a FAILED_SERVICES=()
  declare -a UP_SERVICES=()

  for service in ${services[@]}
  do
    echo "Confirming $service status.."
    status=$(verifyECSServiceIsUp $cluster $service)
    if [ "$status" == "true" ];then
      UP_SERVICES+=("$service")
    else
      FAILED_SERVICES+=("$service")
    fi
  done

  if [ ${#FAILED_SERVICES[@]} -ne 0 ];then
    echo "UP services are : ${UP_SERVICES[@]}"
    echo "Failed services are : ${FAILED_SERVICES[@]}"
    return 1
  else
    echo "All services: ${services[@]} are UP now"
  fi

  # Verifying whether all tasks are running for each services

  declare -a All_TASKS_RUNNING_SERVICES=()
  declare -a NOT_All_TASKS_RUNNING_SERVICES=()

  for service_s in ${services[@]}
  do
    echo "Confirming $service_s running tasks status.."
    poll_ecs_deployment_complete $cluster $service_s
    if [ $? -eq 0 ];then
      All_TASKS_RUNNING_SERVICES+=("$service_s")
    else
      NOT_All_TASKS_RUNNING_SERVICES+=("$service_s")
    fi
  done

  if [ ${#NOT_All_TASKS_RUNNING_SERVICES[@]} -ne 0 ];then
    echo "All tasks running services are : ${All_TASKS_RUNNING_SERVICES[@]}"
    echo "Not all tasks running services are : ${NOT_All_TASKS_RUNNING_SERVICES[@]}"
    return 1
  else
    echo "Successful. All services: ${services[@]} are running their desired number of tasks"
  fi
}
