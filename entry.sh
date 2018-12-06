#!/bin/bash
set -e
set -x

# parse arguments
for i in "$@"
do
case $i in
    --git-version=*)
    GIT_VERSION="${i#*=}"
    shift
    ;;
    *)
    echo "unknown flag $i"
    exit 1
    ;;
esac
done

# get deps
apt-get update
apt-get --assume-yes install git make rsync
git version
make --version
ls /bin/bash
go version
rsync --version

# clone k8s
cd src
mkdir k8s.io
cd k8s.io
mkdir kubernetes
cd kubernetes
git init
git remote add origin https://github.com/kubernetes/kubernetes
# default to master
if [[ -z "${GIT_VERSION}" ]] ; then
    GIT_VERSION=master
fi
release_endpoint="https://storage.googleapis.com/kubernetes-release/release"
# a version tag is used
if [[ "${GIT_VERSION}" == "v"* ]] ; then
    echo "* using version tag: $GIT_VERSION"
    git fetch --depth=1 origin refs/tags/$GIT_VERSION:refs/tags/$GIT_VERSION
    git checkout $GIT_VERSION
    git_version=$(git describe --abbrev=0)
    git_major=$(echo $git_version | cut -d 'v' -f 2 | cut -d '.' -f 1)
    git_minor=$(echo $git_version | cut -d 'v' -f 2 | cut -d '.' -f 2)
# a branch name is used
elif [[ "${GIT_VERSION}" == "release-"* ]] || [[ "${GIT_VERSION}" == "master" ]]; then
    echo "* using branch: $GIT_VERSION"
    git fetch --depth=1 origin $GIT_VERSION
    git checkout $GIT_VERSION
    # this is done to avoid fetching tags
    if [[ "${GIT_VERSION}" == "master" ]]; then
        git_version=$(curl $release_endpoint/latest.txt)
    else
        ver=$(echo ${GIT_VERSION} | cut -d '-' -f 2)
        git_version=$(curl $release_endpoint/latest-$ver.txt)
    fi
    git_major=$(echo $git_version | cut -d 'v' -f 2 | cut -d '.' -f 1)
    git_minor=$(echo $git_version | cut -d 'v' -f 2 | cut -d '.' -f 2)
else
    echo "* unknown version or branch: $GIT_VERSION"
    exit 1
fi

# write a version file
cat <<EOF > ./kube-version
KUBE_GIT_COMMIT=$(git log | head -1 | awk '{print $2}')
KUBE_GIT_TREE_STATE='clean'
KUBE_GIT_VERSION=$git_version
KUBE_GIT_MAJOR=$git_major
KUBE_GIT_MINOR=$git_minor
EOF
cat ./kube-version
export KUBE_GIT_VERSION_FILE=$(pwd)/kube-version
OUT=_output/local/go/bin

# build kubeadm
make WHAT=cmd/kubeadm
cp $OUT/kubeadm /go/bin
/go/bin/kubeadm version -o=short

# build the kubelet
make WHAT=cmd/kubelet
cp $OUT/kubelet /go/bin
/go/bin/kubelet --version

# build kubectl
make WHAT=cmd/kubectl
cp $OUT/kubectl /go/bin
/go/bin/kubectl version --short=true 2> /dev/null
