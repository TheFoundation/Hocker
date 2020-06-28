#!/bin/bash
set -e

docker run --rm --name apt-cacher-ng -d  sameersbn/apt-cacher-ng:latest || true 
set +e
return 0
