#!/bin/sh

if [ ! "$1" == "cap" -o "$1" == "cap-apache" ]; then
  echo "Specify the image to push: cap or cap-apache"
  exit 1
fi

docker login docker.c7a.ca

if [ $? -ne 0 ]; then
  echo 
  echo "Error logging into the c7a Docker registry."
  exit 1
fi

TAG=`date -u +"%Y%m%d%H%M%S"`

echo
echo "Tagging $1:latest as docker.c7a.ca/$1:$TAG"

docker tag $1:latest docker.c7a.ca/$1:$TAG

if [ $? -ne 0 ]; then
  exit $?
fi

echo
echo "Pushing docker.c7a.ca/$1:$TAG"

docker push docker.c7a.ca/$1:$TAG

if [ "$?" -ne "0" ]; then
  exit $?
fi

echo
echo "Push sucessful. Create a new issue at:"
echo
echo "https://github.com/crkn-rcdr/Systems-Administration/issues/new?title=New+$1+image:+%60docker.c7a.ca/$1:$TAG%60&body=Please+describe+the+changes+in+this+update%2e"
echo
echo "to alert the systems team. Don't forget to describe what's new!"