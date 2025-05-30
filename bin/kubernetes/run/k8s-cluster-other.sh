#!/bin/bash

# 张亚飞 ...
# [Tool] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

echo "🤡 验证当前目录是否一致..."

# 验证当前目录...
K8sMain="$(pwd -P)/../.."
K8sRoot="$K8sMain/kubernetes"
K8sConfig="$K8sRoot/config"
K8sCoam="$K8sRoot/coam"
K8sRun="$K8sRoot/run"
K8sSrc="$K8sRoot/src"
if [ ! -d $K8sRun ]; then
  echo "🤖Sorry: [K8sRun: $K8sRun] Not Exist Error!"
  echo "Please run k8s-cluster-deploy.sh under [kubernetes/run/] dir..."
  exit
fi

# 要求 root 用户身份执行此命令...
#if [[ $EUID -ne 0 ]]; then
#   echo "Error:This script must be run as root!" 1>&2
#   exit 1
#fi

# Rust Kube Api
#[Arnavion/k8s-openapi](https://github.com/Arnavion/k8s-openapi)
#[ynqa/kubernetes-rust](https://github.com/ynqa/kubernetes-rust)
#[clux/kube-rs](https://github.com/clux/kube-rs)

# [配置环境] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

# 自动获取 sudo 权限
#echo 'os-coam-000' | sudo -S hostname
echo 'aajjffkk ' | sudo -S hostname

# 安装 helm 程序
#wget https://get.helm.sh/helm-v3.2.4-linux-amd64.tar.gz -O /tmp/helm.tar.gz && tar -zxvf /tmp/helm.tar.gz -C /tmp && sudo cp /tmp/linux-amd64/helm /usr/local/bin/
#helm version

# [kubernetes] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

## kubernetes 升级

#* 首先升级 `kubeadm` `kubectl` `kubelet`
#sudo apt update
#sudo apt install kubeadm
#sudo apt install kubectl
#sudo apt install kubelet
#kubeadm version
#kubectl version
#kubelet --version

#kubeadm upgrade plan
#kubeadm upgrade apply v1.13.0

# [kubernetes] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

#K8sSrc=/data/home/coam/Run/runs/kubernetes/src
#K8sCoam=/data/home/coam/Run/runs/kubernetes/coam

# 配置 [Istio|Cilium] 版本...
IstioVersion="1.3.3"
CiliumVersion="1.6.3"
echo "🦆配置 Istio 版本 [IstioVersion: $IstioVersion][CiliumVersion: $CiliumVersion]"

# 首先拉取镜像

# 清理冲突文件
sudo rm -rf /var/lib/etcd

echo "[🤖>>>]使用 kubeadm 部署集群..."
#echo "[sudo kubeadm init --config $K8sCoam/k8s.000.cluster.kubeadm-init.yaml]"
#sudo kubeadm init --config $K8sCoam/k8s.000.cluster.kubeadm-init.yaml

# 关闭 `Swap` 交换分区限制
#sudo sh -c "echo KUBELET_EXTRA_ARGS=--fail-swap-on=false > /etc/default/kubelet"
sudo kubeadm init --config $K8sCoam/k8s-cluster.kubeadm-init.yaml --ignore-preflight-errors=Swap

echo "[🤖>>>]配置 kubernetes 集群授权文件..."
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo $'\n'

#docker image pull quay.io/coreos/flannel:v0.12.0-amd64
#kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
#kubeadm join 172.17.0.3:6443 --token 0otg0n.svhzq2kfbdxdy216 --discovery-token-ca-cert-hash sha256:21eeb0759887174dd8bbe2aa83e5fef89e9023085dcd14912555bd7ed04b4e7c

echo "[🤖>>>]子节点加入自动集群"
# 创建加入集群的临时授权命令
#sudo kubeadm token create --print-join-command
#kubeadm join 172.17.0.3:6443 --token 597ipn.g13vistjg9ef2z4p --discovery-token-ca-cert-hash sha256:afd10e02b390bda0e31c9ca04ca7cd2c6e9f2b4f0a63ddf6194aaf2d6b3d5125
join_token=$(kubeadm token list | grep -m 1 authentication | awk '{print $1}')
#echo "kubeadm join 172.17.0.3:6443 --token=$join_token --discovery-token-unsafe-skip-ca-verification --ignore-preflight-errors=Swap";
ssh coam@2.tcs.iirii.com -p22312 -t "echo 'aajjffkk ' | sudo -S kubeadm join 172.17.0.3:6443 --token=$join_token --discovery-token-unsafe-skip-ca-verification --ignore-preflight-errors=Swap; echo $'\n'"
echo $'\n'

echo "[🤖>>>]将主节点移除污点"
echo "[kubectl taint nodes --all node-role.kubernetes.io/master-]"
kubectl taint nodes --all node-role.kubernetes.io/master-
echo $'\n'

# 设置网络插件
#kubectl apply -f kube-flannel.yml

echo "[🤖>>>]初始化 default 命名空间环境"
echo "[kubectl apply -f $K8sCoam/k8s.000.default.init.namespace.yaml]"
kubectl apply -f $K8sCoam/k8s.000.default.init.namespace.yaml
echo $'\n'

#echo "[🤖>>>]安装官方 dashboard 控制台"
#echo "[kubectl apply -f $K8sCoam/k8s.251.kubernetes-dashboard.deploy.yaml]"
#kubectl apply -f $K8sCoam/k8s.251.kube-system.dashboard.o.yaml
#echo $'\n'

echo "[🤖>>>]准备 Cilium 网网络服务配置"

# 清理文件
#[ ! -f $K8sSrc/$CiliumVersion.tar.gz ] && wget https://github.com/cilium/cilium/archive/$CiliumVersion.tar.gz -P $K8sSrc
#rm -rf $K8sSrc/cilium-$CiliumVersion && tar -zxf $K8sSrc/$CiliumVersion.tar.gz && mv cilium-$CiliumVersion $K8sSrc

echo "[🤖>>>]安装网络插件"
#echo "[kubectl apply -f $K8sCoam/_.k8s.012.kube-system.cluster.cni.weave.yaml]"
#kubectl apply -f $K8sCoam/_.k8s.012.kube-system.cluster.cni.weave.yaml
#echo "[kubectl apply -f $K8sCoam/k8s.010.cluster.cni.cilium.yaml]"
#kubectl apply -f $K8sCoam/_.k8s.010.kube-system.cluster.cni.cilium.yaml
#helm template $K8sSrc/cilium-$CiliumVersion/install/kubernetes/cilium --namespace kube-system | kubectl apply -f -
#echo $'\n'

# 注意: 安装 Cilium 之前不要安装其它网络插件,如 flannel,否则安装 Cilium 会报错: cilium-agent 启动失败
curl https://raw.githubusercontent.com/cilium/cilium/1.8.2/install/kubernetes/quick-install.yaml | kubectl apply -f -

echo "[🤖>>>]准备 Istio 网格服务配置"

# [Istio](https://www.qikqiak.com/k8strain/istio/install/)
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.6.7 sh -
export PATH="$PATH:/data/home/coam/istio-1.6.7/bin"

# 安装 Istio ...
# 等待次数...
steps=1
# 默认响应码
runner_returns="111"
#runner_returns="$?" && echo $runner_returns
while [ $runner_returns != "0" ]; do
  echo "💤等待[istioctl install --set profile=demo][runner_returns: $runner_returns] [$steps]..."

  # 安装官方示例配置
  istioctl install --set profile=demo
  runner_returns="$?"

  steps=$(($steps + 1))
done

# 设置默认 default 命名空间自动注入
kubectl label namespace default istio-injection=enabled

# 查看服务
kubectl get pods -n istio-system

#[ ! -f $K8sSrc/istio-$IstioVersion-linux.tar.gz ] && wget https://github.com/istio/istio/releases/download/$IstioVersion/istio-$IstioVersion-linux.tar.gz -P $K8sSrc
#rm -rf $K8sSrc/istio-$IstioVersion && tar -zxf $K8sSrc/istio-$IstioVersion-linux.tar.gz && mv istio-$IstioVersion $K8sSrc

echo "🧚同步自定义配置文件..."
echo "同步 cp -rf $K8sConfig/istio/* -> $K8sSrc/istio-$IstioVersion..."
cp -rf $K8sConfig/istio/* $K8sSrc/istio-$IstioVersion

echo "[🤖>>>]创建 Istio 网格服务命名空间"
echo "[kubectl apply -f $K8sCoam/k8s.020.istio-system.namespace.yaml]"
kubectl apply -f $K8sCoam/k8s.020.istio-system.namespace.yaml
echo $'\n'

echo "[🤖>>>]初始化 Istio 网格服务插件"
echo "[kubectl apply -f $K8sCoam/k8s.021.istio-system.istio-init.yaml]"
#kubectl apply -f $K8sCoam/_.k8s.021.istio-system.istio-init.yaml
helm template $K8sSrc/istio-$IstioVersion/install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
echo $'\n'

echo "😇 创建 Istio Jobs,请耐心等待 10+ 秒..."
sleep 10

#[AWK程序设计语言](https://awk.readthedocs.io/en/latest/chapter-one.html)
#[awk一行和多行之间的转换](https://peloo.net/?p=784)
#[shell替换和去掉换行符](https://blog.51cto.com/853056088/1952430)
kube_istio_init_crd_jobs=$(kubectl get pods -n istio-system | grep istio-init-crd | awk '{print $1}' | awk '{printf"%s | ",$0}')

# 等待次数...
steps=10
# 统计 Jobs 任务完成量
kube_istio_init_crd_completes=0
while [ $kube_istio_init_crd_completes != "3" ]; do
  echo "💤等待 [$kube_istio_init_crd_jobs] Jobs,完成量: [$kube_istio_init_crd_completes/3] [$steps]..."
  kube_istio_init_crd_completes=$(kubectl get pods -n istio-system | grep istio-init-crd | awk '{print $3}' | grep "Completed" | wc -l)
  sleep 1
  steps=$(($steps + 1))
done

echo "😇 Job创建完成,已等待 $steps 秒..."

#[Bash Arrays](https://www.linuxjournal.com/content/bash-arrays)
#kube_istio_init_crd_status=(Completed Completed)

echo "[🤖>>>]初始化 Istio 网格服务插件"
echo "[kubectl apply -f $K8sCoam/k8s.021.istio-system.istio-cni.yaml]"
#kubectl apply -f $K8sCoam/_.k8s.021.istio-system.istio-cni.yaml
helm template $K8sSrc/istio-$IstioVersion/install/kubernetes/helm/istio-cni --name istio-cni --namespace istio-system | kubectl apply -f -
echo $'\n'

echo "[🤖>>>]部署 Istio 网格服务插件"
echo "[kubectl apply -f $K8sCoam/k8s.022.istio-system.istio.yaml]"
#kubectl apply -f $K8sCoam/_.k8s.022.istio-system.istio.yaml
helm template $K8sSrc/istio-$IstioVersion/install/kubernetes/helm/istio --name istio --namespace istio-system --set istio_cni.enabled=true | kubectl apply -f -
echo $'\n'

echo "[🤖>>>]配置 Istio 附加功能"
echo "[kubectl apply -f $K8sCoam/k8s.023.istio-system.addon.yaml]"
kubectl apply -f $K8sCoam/k8s.023.istio-system.addon.yaml
echo $'\n'

echo "[🤖>>>]配置 Istio Secret"
echo "[kubectl apply -f $K8sCoam/k8s.024.istio-system.secret.yaml]"
kubectl apply -f $K8sCoam/k8s.024.istio-system.secret.yaml
echo $'\n'

echo "[🤖>>>]配置 Istio Ingress"
echo "[kubectl apply -f $K8sCoam/k8s.025.istio-system.ingress.yaml]"
kubectl apply -f $K8sCoam/k8s.025.istio-system.ingress.yaml
echo $'\n'

echo "[🤖>>>]检查默认策略 - 解决 Mysql 连接问题"
steps=0
while ! (kubectl get meshpolicies.authentication.istio.io default); do
  echo "💤等待创建 [kubectl get meshpolicies.authentication.istio.io default]资源, [$steps]..."
  sleep 1
  steps=$(($steps + 1))
done

echo "[🤖>>>]删除默认策略 - 暂时解决 Mysql 连接问题"
echo "[kubectl describe meshpolicies.authentication.istio.io default]"
kubectl describe meshpolicies.authentication.istio.io default
echo $'\n'

echo "[kubectl delete meshpolicies.authentication.istio.io default]"
kubectl delete meshpolicies.authentication.istio.io default
echo $'\n'

echo "😇 防止系统OutOfCpu过载,请耐心等待 60 秒..."
sleep 60

echo "[🤖>>>]部署 Traefik 镜像服务"

kubectl apply -f $K8sCoam/k8s.030.coam-dev-traefik-ns.traefik.yaml

echo "[kubectl apply -f $K8sCoam/k8s.030.coam-dev-traefik-ns.crd.yaml]"
kubectl apply -f $K8sCoam/k8s.030.coam-dev-traefik-ns.crd.yaml
echo $'\n'

echo "[🤖>>>]关闭系统 Harbor 镜像服务"
sudo systemctl stop os-harbor

echo "[🤖>>>]部署 Harbor 镜像服务"

kubectl apply -f $K8sCoam/k8s.040.harbor.coam-dev-harbor-ns.harbor.yaml
kubectl create secret tls coam-harbor-acme-iirii.com-tls --cert=/etc/ssl/coam/domains/iirii.com/fullchain.crt --key=/etc/ssl/coam/domains/iirii.com/private.key -n coam-dev-harbor-ns
helm install corn harbor/harbor -f /data/home/coam/Run/runs/System/etc/harbor/origin.yaml --namespace coam-dev-harbor-ns

echo "😇 防止系统OutOfCpu过载,请耐心等待 20 秒..."
sleep 20

echo "[🤖>>>]部署 coam-dev-nginx-ns 服务"
echo "[kubectl apply -f $K8sCoam/k8s.090.coam-dev-nginx-ns.namespace.yaml]"
kubectl apply -f $K8sCoam/k8s.090.coam-dev-nginx-ns.namespace.yaml
echo $'\n'

echo "[kubectl apply -f $K8sCoam/k8s.091.coam-dev-nginx-ns.us-nginx.yaml]"
kubectl apply -f $K8sCoam/k8s.091.coam-dev-nginx-ns.us-nginx.yaml
echo $'\n'

echo "[kubectl apply -f $K8sCoam/k8s.092.coam-dev-nginx-ns.ingress.yaml]"
kubectl apply -f $K8sCoam/k8s.092.coam-dev-nginx-ns.ingress.yaml
echo $'\n'

echo "😇 防止系统OutOfCpu过载,请耐心等待 20 秒..."
sleep 20

echo "[🤖>>>]部署 coam-dev-mysql-ns 服务"
echo "[kubectl apply -f $K8sCoam/k8s.050.coam-dev-mysql-ns.us-mysql.yaml]"
kubectl apply -f $K8sCoam/k8s.050.coam-dev-mysql-ns.us-mysql.yaml
echo $'\n'

echo "😇 防止系统OutOfCpu过载,请耐心等待 20 秒..."
sleep 20

echo "[🤖>>>]部署 coam-dev-mongodb-ns 服务"
echo "[kubectl apply -f $K8sCoam/k8s.060.coam-dev-mongodb-ns.us-mongodb.yaml]"
kubectl apply -f $K8sCoam/k8s.060.coam-dev-mongodb-ns.us-mongodb.yaml
echo $'\n'

echo "😇 防止系统OutOfCpu过载,请耐心等待 20 秒..."
sleep 20

echo "[🤖>>>]部署 coam-dev-redis-ns 服务"
echo "[kubectl apply -f $K8sCoam/k8s.070.coam-dev-redis-ns.us-redis.yaml]"
kubectl apply -f $K8sCoam/k8s.070.coam-dev-redis-ns.us-redis.yaml

echo "😇 防止系统OutOfCpu过载,请耐心等待 20 秒..."
sleep 20

echo "[🤖>>>]部署 coam-dev-php-ns 服务"
echo "[kubectl apply -f $K8sCoam/k8s.080.coam-dev-php-ns.ns.yaml]"
kubectl apply -f $K8sCoam/k8s.080.coam-dev-php-ns.ns.yaml
echo $'\n'

echo "[kubectl apply -f $K8sCoam/k8s.080.coam-dev-php-ns.us-php.yaml]"
kubectl apply -f $K8sCoam/k8s.080.coam-dev-php-ns.us-php.yaml
echo $'\n'

echo "😇 防止系统OutOfCpu过载,请耐心等待 20 秒..."
sleep 20

#echo "[kubectl apply -f $K8sCoam/k8s.380.coam-dev-php-ns.us-pss.yaml]"
#kubectl apply -f $K8sCoam/k8s.380.coam-dev-php-ns.us-pss.yaml
#echo $'\n'

#echo "[kubectl apply -f $K8sCoam/k8s.380.coam-dev-php-ns.us-rpc.yaml]"
#kubectl apply -f $K8sCoam/k8s.380.coam-dev-php-ns.us-rpc.yaml
#echo $'\n'

echo "循环更新 Kubernetes 证书..."
#echo "[kubectl apply -f $K8sCoam/_.k8s.094.coam-dev-nginx-ns.secret.yaml]"
#kubectl apply -f $K8sCoam/_.k8s.094.coam-dev-nginx-ns.secret.yaml
#echo $'\n'

# 循环更新 Kubernetes 证书...
for loop_i in "coam.co" "coopens.com" "hhi.io" "iie.io" "iirii.com" "lonal.com" "nocs.cn" "ossse.com" "osssn.com" "pyios.com" "wsw.io" "yyi.io"; do
  echo "Start Create Kubernetes Secret With SSL Cert:$loop_i"
  kubectl create secret tls coam-nginx-acme-$loop_i-tls --cert=/etc/ssl/coam/domains/$loop_i/fullchain.crt --key=/etc/ssl/coam/domains/$loop_i/private.key -n coam-dev-nginx-ns
done

#echo "部署 coam-prod-gitlab-ns 服务"
#echo "[🤖>>>][kubectl apply -f $K8sCoam/k8s.910.coam-prod-gitlab-ns.us-gitlab.yaml]"
#kubectl apply -f $K8sCoam/k8s.910.coam-prod-gitlab-ns.us-gitlab.yaml
#echo $'\n'

#echo "部署 coam-prod-ss-proxy-ns 服务"
#echo "[🤖>>>][kubectl apply -f $K8sCoam/k8s.420.coam-prod-ss-proxy-ns.deploy.yaml]"
#kubectl apply -f $K8sCoam/k8s.420.coam-prod-ss-proxy-ns.deploy.yaml
#echo $'\n'

#echo "部署 coam-prod-sw-vpn-ns 服务"
#
#echo "[🤖>>>][kubectl apply -f $K8sCoam/k8s.430.coam-prod-sw-vpn-ns.deploy.yaml]"
#kubectl apply -f $K8sCoam/k8s.430.coam-prod-sw-vpn-ns.deploy.yaml
#
## 手动创建 configmap: `vpn-config`
#sudo kubectl create configmap vpn-config -n coam-prod-sw-vpn-ns \
#  --from-file=usr_local_etc_strongswan.d_charon-logging.conf=/usr/local/etc/strongswan.d/charon-logging.conf \
#  --from-file=usr_local_etc_ipsec.conf=/usr/local/etc/ipsec.conf \
#  --from-file=usr_local_etc_ipsec.secrets=/usr/local/etc/ipsec.secrets \
#  --from-file=usr_local_etc_strongswan.conf=/usr/local/etc/strongswan.conf
#
#echo "[🤖>>>][kubectl apply -f $K8sCoam/k8s.430.coam-prod-sw-vpn-ns.us-sw-vpn.yaml]"
#kubectl apply -f $K8sCoam/k8s.430.coam-prod-sw-vpn-ns.us-sw-vpn.yaml
#echo $'\n'

#echo "😇 防止系统OutOfCpu过载,请耐心等待 20 秒..."
#sleep 20
#
#echo "部署 coam-dev-rabbitmq-ns 服务"
#echo "[🤖>>>][kubectl apply -f $K8sCoam/k8s.540.coam-dev-rabbitmq-ns.deploy.yaml]"
#kubectl apply -f $K8sCoam/k8s.540.coam-dev-rabbitmq-ns.deploy.yaml

#echo "部署 coam-dev-lsyncd-ns 服务"
#echo "[🤖>>>][kubectl apply -f $K8sCoam/k8s.140.coam-dev-lsyncd-ns.us-lsyncd.yaml]"
#kubectl apply -f $K8sCoam/k8s.150.coam-dev-lsyncd-ns.us-lsyncd.yaml

echo "😇 防止系统OutOfCpu过载,请耐心等待 20 秒..."
sleep 20

#echo "部署 coam-dev-emqttd-ns 服务"
#echo "[🤖>>>][kubectl apply -f $K8sCoam/k8s.140.coam-dev-emqttd-ns.us-emqttd.yaml]"
#kubectl apply -f $K8sCoam/k8s.560.coam-dev-emqttd-ns.deploy.yaml
#
#echo "😇 防止系统OutOfCpu过载,请耐心等待 20 秒..."
#sleep 20

#echo "部署 coam-dev-ejabberd-ns 服务"
#echo "[🤖>>>][kubectl apply -f $K8sCoam/k8s.140.coam-dev-ejabberd-ns.us-ejabberd.yaml]"
#kubectl apply -f $K8sCoam/k8s.570.coam-dev-ejabberd-ns.deploy.yaml
#
#echo "😇 防止系统OutOfCpu过载,请耐心等待 20 秒..."
#sleep 20

# TODO: ELK...

echo "部署 coam-prod-docs-ns 服务"
echo "[🤖>>>][kubectl apply -f $K8sCoam/k8s.200.coam-prod-docs-ns.us-docs.yaml]"
kubectl apply -f $K8sCoam/k8s.200.coam-prod-docs-ns.us-docs.yaml

# 循环更新 Kubernetes 证书...
for loop_i in "iirii.com"; do
  echo "Start Create Kubernetes Secret With SSL Cert:$loop_i"
  kubectl create secret tls coam-docs-acme-$loop_i-tls --cert=/etc/ssl/coam/domains/$loop_i/fullchain.crt --key=/etc/ssl/coam/domains/$loop_i/private.key -n coam-prod-docs-ns
done

echo "部署 coam-prod-run-s-ns 服务"
echo "[🤖>>>][kubectl apply -f $K8sCoam/k8s.210.coam-prod-run-s-ns.us-run-s.yaml]"
kubectl apply -f $K8sCoam/k8s.210.coam-prod-run-s-ns.us-run-s.yaml

# 循环更新 Kubernetes 证书...
for loop_i in "iirii.com"; do
  echo "Start Create Kubernetes Secret With SSL Cert:$loop_i"
  kubectl create secret tls coam-run-s-acme-$loop_i-tls --cert=/etc/ssl/coam/domains/$loop_i/fullchain.crt --key=/etc/ssl/coam/domains/$loop_i/private.key -n coam-prod-run-s-ns
done

#echo "[🤖>>>]部署 Rook 分布式存储服务 [common+operator]"
#echo "[kubectl create -f $K8sConfig/rook/cluster/examples/kubernetes/ceph/common.yaml]"
#kubectl create -f $K8sConfig/rook/cluster/examples/kubernetes/ceph/common.yaml
#echo "[kubectl create -f $K8sConfig/rook/cluster/examples/kubernetes/ceph/operator.yaml]"
#kubectl create -f $K8sConfig/rook/cluster/examples/kubernetes/ceph/operator.yaml
#echo $'\n'
#
#echo "[🤖>>>]创建 Ceph 集群"
#echo "[kubectl create -f $K8sConfig/rook/cluster/examples/kubernetes/ceph/cluster.yaml]"
#kubectl create -f $K8sConfig/rook/cluster/examples/kubernetes/ceph/cluster.yaml
#echo $'\n'
#
#echo "[🤖>>>]开放 Ceph 后台"
#echo "[kubectl apply -f $K8sConfig/rook/cluster/examples/kubernetes/ceph/dashboard-external-https.yaml]"
#kubectl apply -f $K8sConfig/rook/cluster/examples/kubernetes/ceph/dashboard-external-https.yaml
#echo $'\n'
#
#echo "[🤖>>>]创建 PV:"
#echo "[kubectl apply -f $K8sCoam/k8s.900.rook-ceph.plugins.rook-storage.yaml]"
#kubectl apply -f $K8sCoam/k8s.900.rook-ceph.plugins.rook-storage.yaml
#echo $'\n'
#
#echo "[🤖>>>]创建 PVC(mysql + wordpress):"
#echo "[kubectl apply -f $K8sConfig/rook/cluster/examples/kubernetes/mysql.yaml]"
#kubectl apply -f $K8sConfig/rook/cluster/examples/kubernetes/mysql.yaml
#echo $'\n'
#
#echo "[kubectl apply -f $K8sConfig/rook/cluster/examples/kubernetes/wordpress.yaml]"
#kubectl apply -f $K8sConfig/rook/cluster/examples/kubernetes/wordpress.yaml
#echo $'\n'
#
#echo "[🤖>>>]查看 PV、PVC:"
#echo "[kubectl get pvc,pv]"
#kubectl get pvc,pv
#echo $'\n'
#
#echo "[🤖>>>]查看创建的 storageclass,cephblockpool"
#echo "[kubectl get storageclass,cephblockpool --all-namespaces]"
#kubectl get storageclass,cephblockpool --all-namespaces
#echo $'\n'
#
#echo "[🤖>>>]查看存储资源 svc,pods,storageclass,cephblockpool:"
#kubectl get svc,pods,storageclass,cephblockpool -n rook-ceph -owide
#echo $'\n'

#echo "[🤖>>>]部署 metrics-server 监控服务"
#echo "[kubectl apply -f $K8sCoam/metrics-server/deploy/1.8+]"
#kubectl apply -f $K8sCoam/metrics-server/deploy/1.8+
#echo $'\n'

#echo "[🤖>>>]部署 kube-prometheus 监控服务"
#echo "[kubectl apply -f $K8sCoam/kube-prometheus/manifests]"
#kubectl apply -f $K8sCoam/kube-prometheus/manifests
#echo $'\n'

#echo "[🤖>>>]部署 weaveworks/scope 监控服务"
## 手动创建命名空间,防止配置执行顺序不一致导致部署失败
#kubectl create namespace weave
#echo "[kubectl apply -f $K8sConfig/weaveworks/scope/examples/k8s]"
#kubectl apply -f $K8sConfig/weaveworks/scope/examples/k8s
#echo $'\n'

# [一些访问配置] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

source ./k8s-cluster-env.sh

# [Ended] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
