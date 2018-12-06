## kubeadm-builder

experimental project for building kubeadm using Docker.

### usage

call the following commands to setup the building container:
```bash
mkdir kubeadm-builder && cd kubeadm-builder
curl https://raw.githubusercontent.com/neolit123/kubeadm-builder/master/Dockerfile > Dockerfile
curl https://raw.githubusercontent.com/neolit123/kubeadm-builder/master/entry.sh > entry.sh
docker build -t kubeadm-builder:latest .
```

then to build a certain kubeadm version call:
```bash
docker run -it -v $(pwd):/go/bin kubeadm-builder:latest --git-version=$VERSION
```

`$VERSION` can be either a branch or a tag:
- `master`
- `release-x.yy` - e.g. `release-1.12`
- or a version tag - e.g. `v1.12.0` or `v1.12.0-alpha.2`
see [this page](https://github.com/kubernetes/kubernetes/releases) for all tags.

if `--git-version` is not used it defaults to `master`.

replace `$(pwd)` with the path where you want the `kubeadm`, `kubelet` and `kubectl` binaries to be written.
by default it writes in the current directory.
