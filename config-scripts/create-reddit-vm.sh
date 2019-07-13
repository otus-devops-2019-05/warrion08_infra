#!/bin/bash

#create instance
gcloud compute instances create reddit-base\
  --boot-disk-size=10GB \
  --image-family reddit-full \
  --machine-type=f1-micro \
  --tags puma-server \
  --restart-on-failure \
  --zone europe-west1-b
