REPO=public.ecr.aws
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws
npm i
eval $(node latest_versions.js "kubernetes/kubernetes")
version=$KUBERNETES_KUBERNETES_VERSION
echo "Building version:"$version
git clone -b $version --depth 1 https://github.com/kubernetes/kubernetes.git
cd kubernetes 
git clean -f
BUILD_ARCHS="linux/amd64 linux/arm64 linux/arm"
export CGO_ENABLED=0
make clean kubectl KUBE_BUILD_PLATFORMS="$BUILD_ARCHS" KUBE_GIT_VERSION=$version \
	KUBE_GIT_MAJOR=$(echo $version | sed -e 's/^[^0-9]*\([0-9][0-9]*\)\..*$/\1/') \
	KUBE_GIT_MINOR=$(echo $version | sed -e 's/^[^\.][^\.]*\.\([0-9][0-9]*\)\..*$/\1/') \
        KUBE_GIT_COMMIT="$(git rev-parse --short HEAD)"


cat > Dockerfile.ubuntu <<EOF
FROM ubuntu:jammy

COPY ./kubectl /usr/local/bin/kubectl

CMD ["/usr/local/bin/kubectl", "version", "--short"]
EOF
cat > Dockerfile.debian <<EOF
FROM debian:buster-slim

COPY ./kubectl /usr/local/bin/kubectl

CMD ["/usr/local/bin/kubectl", "version", "--short"]
EOF
for i in $BUILD_ARCHS
do
  if [ "$i" = "linux/arm/v7" ]
  then
	i=linux/arm
  fi 
  docker buildx build -t ghcr.io/mabels/kubectl:$version-$(basename $i)-ubuntu-jammy --platform $i -f ./Dockerfile.ubuntu ./_output/local/bin/$i 
  docker push ghcr.io/mabels/kubectl:$version-$(basename $i)-ubuntu-jammy
  docker buildx build -t ghcr.io/mabels/kubectl:$version-$(basename $i)-debian-buster --platform $i -f ./Dockerfile.debian ./_output/local/bin/$i 
  docker push ghcr.io/mabels/kubectl:$version-$(basename $i)-debian-buster
done

<<<<<<< HEAD
docker manifest create $REPO/mabels/kubectl:$version \
	--amend $REPO/mabels/kubectl:$version-amd64 \
	--amend $REPO/mabels/kubectl:$version-arm64 \
	--amend $REPO/mabels/kubectl:$version-arm
docker manifest push $REPO/mabels/kubectl:$version
||||||| parent of 67a3e3d (chore: ubuntu and debian build)
docker manifest create ghcr.io/mabels/kubectl:$version \
	--amend ghcr.io/mabels/kubectl:$version-amd64 \
	--amend ghcr.io/mabels/kubectl:$version-arm64 \
	--amend ghcr.io/mabels/kubectl:$version-arm
docker manifest push ghcr.io/mabels/kubectl:$version
=======
for i in ubuntu-jammy debian-buster
do
	docker manifest create ghcr.io/mabels/kubectl:$version-$i \
		--amend ghcr.io/mabels/kubectl:$version-$i-amd64 \
		--amend ghcr.io/mabels/kubectl:$version-$i-arm64 \
		--amend ghcr.io/mabels/kubectl:$version-$i-arm
	docker manifest push ghcr.io/mabels/kubectl:$version-$i

	docker manifest create ghcr.io/mabels/kubectl:latest-$i \
		--amend ghcr.io/mabels/kubectl:$version-$i-amd64 \
		--amend ghcr.io/mabels/kubectl:$version-$i-arm64 \
		--amend ghcr.io/mabels/kubectl:$version-$i-arm
	docker manifest push ghcr.io/mabels/kubectl:latest-$i
done
>>>>>>> 67a3e3d (chore: ubuntu and debian build)

<<<<<<< HEAD
docker manifest create $REPO/mabels/kubectl:latest \
	--amend $REPO/mabels/kubectl:$version-amd64 \
	--amend $REPO/mabels/kubectl:$version-arm64 \
	--amend $REPO/mabels/kubectl:$version-arm
docker manifest push $REPO/mabels/kubectl:latest
||||||| parent of 67a3e3d (chore: ubuntu and debian build)
docker manifest create ghcr.io/mabels/kubectl:latest \
	--amend ghcr.io/mabels/kubectl:$version-amd64 \
	--amend ghcr.io/mabels/kubectl:$version-arm64 \
	--amend ghcr.io/mabels/kubectl:$version-arm
docker manifest push ghcr.io/mabels/kubectl:latest
=======
docker manifest create ghcr.io/mabels/kubectl:latest \
	--amend ghcr.io/mabels/kubectl:$version-ubuntu-jammy-amd64 \
	--amend ghcr.io/mabels/kubectl:$version-ubuntu-jammy-arm64 \
	--amend ghcr.io/mabels/kubectl:$version-ubuntu-jammy-arm
docker manifest push ghcr.io/mabels/kubectl:latest
>>>>>>> 67a3e3d (chore: ubuntu and debian build)

