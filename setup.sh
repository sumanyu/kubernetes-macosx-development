#!/bin/bash

set -e
echo "Setting up VM..."


echo "Installing system tools and docker..."
# Source control tools are so go get works properly.
yum -y install yum-fastestmirror git mercurial subversion docker-io
# Docker setup.
systemctl start docker
systemctl enable docker
# Supposedly you don't have to do this starting docker 1.0
# (Fedora 20 is currently 1.1.2) but I found it necessary.
usermod -a -G docker vagrant
echo "Complete."


echo "Installing go 1.3.1..."
GOBINARY=go1.3.1.linux-amd64.tar.gz
wget -q https://storage.googleapis.com/golang/$GOBINARY
tar -C /usr/local/ -xzf $GOBINARY
ln -s /usr/local/go/bin/* /usr/bin/
rm $GOBINARY
echo "Complete."


echo "Creating /etc/profile.d/k8s.sh to set GOPATH, KUBERNETES_PROVIDER and other config..."
cat >/etc/profile.d/k8s.sh << 'EOL'
# Golang setup.
export GOPATH=~/go
export PATH=$PATH:~/go/bin
# So you can start using cluster/kubecfg.sh right away.
export KUBERNETES_PROVIDER=local
# So you can access apiserver from your host machine.
export API_HOST=10.245.1.2

# For convenience.
alias k="cd ~/go/src/github.com/GoogleCloudPlatform/kubernetes"
alias killcluster="ps axu|grep -e go/bin -e etcd |grep -v grep | awk '{print $2}' | xargs kill"
alias kstart="k && killcluster; hack/local-up-cluster.sh"
EOL

# For some reason /etc/hosts does not alias localhost to 127.0.0.1.
echo "127.0.0.1 localhost" >> /etc/hosts

# kubelet complains if this directory doesn't exist.
mkdir /var/lib/kubelet

# The NFS mount is initially owned by root - it should be owned by vagrant.
chown vagrant.vagrant /home/vagrant/go

echo "Complete."


echo "Installing godep and etcd..."
export GOPATH=/home/vagrant/go
# Go will compile on both Mac OS X and Linux, but it will create different
# compilation artifacts on the two platforms. By mounting only GOPATH's src
# directory into the VM, you can run `go install <package>` on the Fedora VM
# and it will correctly compile <package> and install it into
# /home/vagrant/gopath/bin.
mkdir -p $GOPATH/src/github.com/GoogleCloudPlatform/
cd $GOPATH/src/github.com/GoogleCloudPlatform/
git clone git@github.com:GoogleCloudPlatform/kubernetes.git

sudo -u vagrant go get github.com/tools/godep && sudo -u vagrant go install github.com/tools/godep

sudo -u vagrant go get github.com/coreos/etcd 
cd $GOPATH/src/github.com/coreos/etcd
git checkout tags/v0.4.6

sudo -u vagrant go install github.com/coreos/etcd
echo "Complete."

echo "Setup complete."
