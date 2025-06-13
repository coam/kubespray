#!/usr/bin/env bash

# [配置环境] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


# [执行安装脚本] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

# 关闭交换分区
sudo swapoff -a

# 清除防火墙设置
#sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X && sudo iptables -L

# Install Docker...

# Install Kubernetes...

#添加 `Kubernetes` 官方源
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat > /etc/apt/sources.list.d/kubernetes.list<<EOF
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

# 安装 kubernetes 服务
sudo apt update
sudo apt install kubelet kubeadm kubectl

# 初始化
echo "系统初始化:\n"
sudo kubeadm reset -f

# Init Kubernetes Cluster

### 创建初始化配置(当前发布时的最新版本)

### 初始化 Master 节点
echo "初始化 Master 节点:\n"
sudo kubeadm init --config config/k8s.cluster.kubeadm-init.yaml

# 更新用户授权配置文件
echo "更新用户授权配置文件:\n"
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 主节点去除污点
echo "主节点去除污点:\n"
kubectl taint nodes --all node-role.kubernetes.io/master-

# 安装 cilium 网络框架
echo "安装 cilium 网络框架:\n"
kubectl apply -f config/k8s.cluster.kube-system.cni.cilium.yaml

# 安装管理后台 Dashboard
echo "安装管理后台 Dashboard:\n"
kubectl apply -f config/k8s.kube-system.dashboard.init.yaml

# get token with blow account
echo "Dashboard 授权登录Token:"
kubectl describe secrets $(kubectl get secrets --namespace kube-system | grep admin-coam-serviceaccount-token | awk '{print $1}') --namespace kube-system | grep token: | awk '{print $2}'

# open access with public id

# 获取集群状态...
kubectl get nodes,ns,pods,services --all-namespaces -owide

# [启动服务] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

# [完结] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

