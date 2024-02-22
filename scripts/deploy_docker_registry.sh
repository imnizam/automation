#!/bin/bash

# Docker registry creation
docker_image: 'registry'
docker_image_version: 'latest'
registry_storage_s3_bucket: 'phantomstaging-docker-registry'



Environment=DOCKER_REGISTRY_IMAGE={{ docker_image }}
Environment=DOCKER_REGISTRY_VERSION={{ docker_image_version }}
Environment=REGISTRY_STORAGE_S3_BUCKET={{ registry_storage_s3_bucket }}


ExecStart=/usr/bin/docker run -p 5000:5000 -p 80:8000 --restart=always --name staging-registry --env REGISTRY_VERSION='0.1' --env REGISTRY_LOG_LEVEL='debug' --env REGISTRY_STORAGE='s3' --env REGISTRY_HTTP_SECRET='123abcd' --env REGISTRY_STORAGE_S3_REGION='us-west-2' --env  REGISTRY_STORAGE_S3_BUCKET=${REGISTRY_STORAGE_S3_BUCKET} --env REGISTRY_STORAGE_S3_ENCRYPT='false' --env REGISTRY_STORAGE_S3_SECURE='true' --env REGISTRY_STORAGE_S3_ROOTDIRECTORY='/images' --env REGISTRY_HTTP_ADDR='0.0.0.0:8000' ${DOCKER_REGISTRY_IMAGE}:${DOCKER_REGISTRY_VERSION}