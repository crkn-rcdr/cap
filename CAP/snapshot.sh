#!/usr/bin/env sh

echo "Building and testing Perl libraries."
docker build -t cap:cpan -f Dockerfile.cpan .
echo "Retrieving cpanfile.snapshot."
docker run --name capcpan -d -it cap:cpan
docker cp capcpan:/opt/cap/cpanfile.snapshot cpanfile.snapshot
docker stop capcpan
docker rm capcpan
echo "Your snapshot has been updated. Rebuild your primary CAP image."