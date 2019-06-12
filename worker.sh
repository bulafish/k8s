# Add K8S repository
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Disable selinux
setenforce 0
sed -i ‘s/^SELINUX=enforcing$/SELINUX=permissive/’ /etc/selinux/config

# Install k8S
yum install kubelet kubeadm kubectl -y

# Enable K8S
systemctl enable --now kubelet

# Enable br_netfilter module
modprobe br_netfilter

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# Enable settings
sysctl --system

# Add docker-ce repository
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install docker-ce
yum install docker-ce -y

# Start and enable docker-ce and k8S
systemctl enable docker.service
systemctl restart docker
systemctl enable kubelet
systemctl start kubelet

# Install packages for docker-ce
yum install yum-utils device-mapper-persistent-data lvm2 -y

# Set docker settings and reload docker-ce
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl restart docker
