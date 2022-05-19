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
make clean kubectl KUBE_BUILD_PLATFORMS="$BUILD_ARCHS" KUBE_GIT_VERSION=$version \
	KUBE_GIT_MAJOR=$(echo $version | sed -e 's/^[^0-9]*\([0-9][0-9]*\)\..*$/\1/') \
	KUBE_GIT_MINOR=$(echo $version | sed -e 's/^[^\.][^\.]*\.\([0-9][0-9]*\)\..*$/\1/') \
        KUBE_GIT_COMMIT="$(git rev-parse --short HEAD)"


cat > Dockerfile <<EOF
FROM ubuntu:latest

COPY ./kubectl /usr/local/bin/kubectl

CMD ["/usr/local/bin/kubectl", "version", "--short"]
EOF
for i in $BUILD_ARCHS
do
  if [ "$i" = "linux/arm/v7" ]
  then
	i=linux/arm
  fi 
  docker buildx build -t $REPO/mabels/kubectl:$version-$(basename $i)  --platform $i -f ./Dockerfile ./_output/local/bin/$i 
  docker push $REPO/mabels/kubectl:$version-$(basename $i)
done

docker manifest create $REPO/mabels/kubectl:$version \
	--amend $REPO/mabels/kubectl:$version-amd64 \
	--amend $REPO/mabels/kubectl:$version-arm64 \
	--amend $REPO/mabels/kubectl:$version-arm
docker manifest push $REPO/mabels/kubectl:$version

docker manifest create $REPO/mabels/kubectl:latest \
	--amend $REPO/mabels/kubectl:$version-amd64 \
	--amend $REPO/mabels/kubectl:$version-arm64 \
	--amend $REPO/mabels/kubectl:$version-arm
docker manifest push $REPO/mabels/kubectl:latest

