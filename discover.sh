#!/bin/sh

if [ -z $REGION ] ; then
  REGION=us-east-1
fi

if [ -z $SVC_ENV ]; then
  SVC_ENV=dev
fi

if [ -z $AWS_ID ] ; then
  AWS_ID=""
  printf '%s\n' "Please provide AWS_ID" >&2
  exit 1
fi

if [ -z $AWS_SECRET ]; then
  AWS_SECRET=""
  printf '%s\n' "Please provide AWS_SECRET" >&2
  exit 1
fi

## Install RabbitMQ signing key
curl -fsSL https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc | apt-key add -

## Install apt HTTPS transport
apt-get install apt-transport-https

## Add Bintray repositories that provision latest RabbitMQ and Erlang 21.x releases
tee /etc/apt/sources.list.d/bintray.rabbitmq.list <<EOF
deb https://dl.bintray.com/rabbitmq-erlang/debian bionic erlang
deb https://dl.bintray.com/rabbitmq/debian bionic main
EOF

## Update package indices
apt-get update -y

## Install rabbitmq-server and its dependencies
apt-get install rabbitmq-server -y --fix-missing


## inject rabbitmq setting
tee /etc/rabbitmq/rabbitmq.conf <<EOF
cluster_formation.peer_discovery_backend = rabbit_peer_discovery_aws

cluster_formation.aws.region = $REGION
cluster_formation.aws.access_key_id = $AWS_ID
cluster_formation.aws.secret_key = $AWS_SECRET

cluster_formation.aws.instance_tags.rabbit = 1
cluster_formation.aws.instance_tags.project = owt
cluster_formation.aws.instance_tags.environment = $SVC_ENV
EOF
