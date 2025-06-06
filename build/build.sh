#!/bin/bash

version=$1
arch=${2:-amd64}

# build go api program
cd ../api
make clean $arch

# build web app
cd ../web
npm run build

cd ../build

# remove docker image if exists
docker rmi -f registry.cn-shenzhen.aliyuncs.com/geekmaster/geekai-api:$version-$arch
# build docker image for geekai-go
docker build -t registry.cn-shenzhen.aliyuncs.com/geekmaster/geekai-api:$version-$arch -f dockerfile-api-go ../

# build docker image for geekai-web
docker rmi -f registry.cn-shenzhen.aliyuncs.com/geekmaster/geekai-web:$version-$arch
docker build -t registry.cn-shenzhen.aliyuncs.com/geekmaster/geekai-web:$version-$arch -f dockerfile-web-$arch ../

if [ "$3" = "push" ];then
  docker push registry.cn-shenzhen.aliyuncs.com/geekmaster/geekai-api:$version-$arch
  docker push registry.cn-shenzhen.aliyuncs.com/geekmaster/geekai-web:$version-$arch
fi
