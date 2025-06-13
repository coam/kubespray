#!/bin/bash

sc_dir="$(
  cd "$(dirname "$0")" >/dev/null 2>&1 || exit
  pwd -P
)"

rs_path=${sc_dir/runs*/runs}

# 张亚飞 ...
# [Tool] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

echo "🤡 验证当前目录是否一致..."

# 验证当前目录...
K8sMain="$(pwd -P)/../.."
K8sRoot="$K8sMain/kubernetes"
K8sCoam="$K8sRoot/coam"
K8sRun="$K8sRoot/run"
K8sSrc="$K8sRoot/src"
if [ ! -d $K8sRun ]; then
  echo "🤖Sorry: [K8sRun: $K8sRun] Not Exist Error!"
  echo "Please run k8s-cluster-deploy.sh under [kubernetes/run/] dir..."
  exit
fi

# [配置环境] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

# 自动获取 sudo 权限
#echo 'os-coam-000' | sudo -S hostname
echo 'aajjffkk ' | sudo -S hostname

# 服务器自动登录...
ssh-copy-id -p22312 coam@2.tcs.iirii.com
ssh-copy-id -p22312 coam@3.tcs.iirii.com

# [kubernetes] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

#K8sCoam=/data/home/coam/Run/runs/kubernetes/coam

# 配置 [Istio|Cilium] 版本...
IstioVersion="1.6.7"
CiliumVersion="1.8.2"
echo "🦆配置 Istio 版本 [IstioVersion: $IstioVersion][CiliumVersion: $CiliumVersion]"

# TODO: 首先拉取镜像...

# 清理冲突文件
sudo rm -rf /var/lib/etcd

echo "[🤖>>>]使用 kubeadm 部署集群..."
# 关闭 `Swap` 交换分区限制
sudo kubeadm init --config $K8sCoam/k8s.000.cluster.kubeadm-init.yaml --ignore-preflight-errors=Swap

echo "[🤖>>>]配置 kubernetes 集群授权文件..."
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown "$(id -u):$(id -g)" $HOME/.kube/config

echo "[🤖>>>]同步 nodes[t.cs.2] 部署清单"
ssh coam@2.tcs.iirii.com -p22312 -t "mkdir -p /data/home/coam/.kube"
sudo scp -p -P22312 /etc/kubernetes/admin.conf coam@2.tcs.iirii.com:.kube/config
ssh coam@2.tcs.iirii.com -p22312 bash -s <<EOF
echo 'aajjffkk ' | sudo -S hostname
sudo chown "$(id -u):$(id -g)" $HOME/.kube/config
EOF

echo "[🤖>>>]同步 nodes[t.cs.3] 部署清单"
ssh coam@3.tcs.iirii.com -p22312 -t "mkdir -p /data/home/coam/.kube"
sudo scp -p -P22312 /etc/kubernetes/admin.conf coam@3.tcs.iirii.com:.kube/config
ssh coam@3.tcs.iirii.com -p22312 bash -s <<EOF
echo 'aajjffkk ' | sudo -S hostname
sudo chown "$(id -u):$(id -g)" $HOME/.kube/config
EOF

# 创建加入集群的临时授权命令
#sudo kubeadm token create --print-join-command
# 获取加入集群Token
join_token=$(kubeadm token list | grep -m 1 authentication | awk '{print $1}')

echo "[🤖>>>]集群加入凭证[join_token: $join_token]"

echo "[🤖>>>]子节点加入自动集群[t.cs.2]"
ssh coam@2.tcs.iirii.com -p22312 bash -s <<EOF
echo 'aajjffkk ' | sudo -S hostname
sudo kubeadm join 172.17.0.3:6443 --token=$join_token --discovery-token-unsafe-skip-ca-verification --ignore-preflight-errors=Swap
EOF

echo "[🤖>>>]子节点加入自动集群[t.cs.3]"
ssh coam@3.tcs.iirii.com -p22312 bash -s <<EOF
echo 'aajjffkk ' | sudo -S hostname
sudo kubeadm join 172.17.0.3:6443 --token=$join_token --discovery-token-unsafe-skip-ca-verification --ignore-preflight-errors=Swap
EOF

echo "[🤖>>>]集群节点列表"
kubectl get nodes

echo "[🤖>>>]将主节点移除污点"
kubectl taint nodes --all node-role.kubernetes.io/master-

#echo "[🤖>>>]初始化 default 命名空间环境"
#kubectl apply -f $K8sCoam/k8s.001.default.init.ns.yaml

echo "[🤖>>>]准备 Cilium 网网络服务配置"

echo "[🤖>>>]安装网络插件"
# 注意: 安装 Cilium 之前不要安装其它网络插件,如 flannel,否则安装 Cilium 会报错: cilium-agent 启动失败
wget https://raw.githubusercontent.com/cilium/cilium/1.8.2/install/kubernetes/quick-install.yaml -O /tmp/quick-install.yaml
kubectl apply -f /tmp/quick-install.yaml

cd /data/home/coam/source || exit

echo "[🤖>>>]准备 Istio 网格服务配置"
# [Istio](https://www.qikqiak.com/k8strain/istio/install/)
rm -rf /data/home/coam/source/istio-1.6.7
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.6.7 sh -
sudo mv /data/home/coam/source/istio-1.6.7/bin/istioctl /usr/local/bin/istioctl

# 等待次数...
steps=1
# 默认响应码
runner_returns=111
#runner_returns="$?" && echo $runner_returns
while [ $runner_returns != 0 ]; do
  echo "💤等待[istioctl install --set profile=demo][runner_returns: $runner_returns] [$steps]..."

  # 安装官方示例配置
  istioctl install --set values.global.imagePullPolicy=IfNotPresent --set profile=demo
  runner_returns=$?

  sleep 1
  steps=$(($steps + 1))
done

echo "Istio 服务已部署完成"

# 设置默认 default 命名空间自动注入
#kubectl label namespace default istio-injection=enabled

# 查看服务
kubectl get pods -n istio-system -o wide

echo "😇 防止系统OutOfCpu过载,请耐心等待 60 秒..."
sleep 60

echo "[🤖>>>]部署 Traefik 镜像服务"

kubectl apply -f $K8sCoam/k8s.230.coam-dev-traefik-ns.deploy.yaml
kubectl create secret tls coam-traefik-acme-ioros.com-tls --cert=/etc/ssl/coam/domains/ioros.com/fullchain.crt --key=/etc/ssl/coam/domains/ioros.com/private.key -n coam-dev-traefik-ns

# 等待次数...
steps=1
# 统计 Jobs 任务完成量
kube_traefik_init_crd_jobs=0
while [ $kube_traefik_init_crd_jobs != 7 ]; do
  echo "💤等待 [$kube_traefik_init_crd_jobs] Jobs,完成量: [$kube_traefik_init_crd_jobs/7] [$steps]..."
  kube_traefik_init_crd_jobs=$(kubectl get crd | grep .traefik.containo.us | awk '{print $1}' | wc -l)
  sleep 1
  steps=$(($steps + 1))
done

kubectl apply -f $K8sCoam/k8s.231.coam-dev-traefik-ns.patched.yaml

#echo "[🤖>>>]安装官方 dashboard 控制台"
kubectl apply -f $K8sCoam/k8s.251.kubernetes-dashboard.deploy.yaml
kubectl create secret tls kubernetes-dashboard-acme-ioros.com-tls --cert=/etc/ssl/coam/domains/ioros.com/fullchain.crt --key=/etc/ssl/coam/domains/ioros.com/private.key -n kubernetes-dashboard

echo "😇 防止系统OutOfCpu过载,请耐心等待 20 秒..."
sleep 20

echo "[🤖>>>]部署 coam-dev-php-ns 服务"
kubectl apply -f $K8sCoam/k8s.380.coam-dev-php-ns.ns.yaml
kubectl apply -f $K8sCoam/k8s.380.coam-dev-php-ns.us-php.yaml

#echo "更新BCP配置..."
# 手动创建 configmap: `bcp-config`
#sudo kubectl create configmap bcp-config -n coam-dev-php-ns \
#  --from-file=php_conf_php.ini=/data/home/coam/Web/Work/bc_deploy/php_conf/php.ini \
#  --from-file=php_conf_php_fpm.conf=/data/home/coam/Web/Work/bc_deploy/php_conf/php-fpm.conf \
#  --from-file=php_conf_php_fpm_d_tools.conf=/data/home/coam/Web/Work/bc_deploy/php_conf/php-fpm.d/tools.conf \
#  --from-file=php_conf_php_fpm_d_www.conf=/data/home/coam/Web/Work/bc_deploy/php_conf/php-fpm.d/www.conf
#kubectl apply -f $K8sCoam/k8s.381.coam-dev-php-ns.bc-php.yaml

#echo "😇 防止系统OutOfCpu过载,请耐心等待 20 秒..."
#sleep 20

#echo "[kubectl apply -f $K8sCoam/k8s.380.coam-dev-php-ns.us-pss.yaml]"
#kubectl apply -f $K8sCoam/k8s.380.coam-dev-php-ns.us-pss.yaml
#echo $'\n'

#echo "[kubectl apply -f $K8sCoam/k8s.380.coam-dev-php-ns.us-rpc.yaml]"
#kubectl apply -f $K8sCoam/k8s.380.coam-dev-php-ns.us-rpc.yaml
#echo $'\n'

echo "😇 防止系统OutOfCpu过载,请耐心等待 20 秒..."
sleep 20

echo "[🤖>>>]部署 coam-dev-nginx-ns 服务"
kubectl apply -f $K8sCoam/k8s.310.coam-dev-nginx-ns.deploy.yaml

echo "循环更新 Kubernetes 证书..."

# 循环更新 Kubernetes 证书...
for loop_i in "coam.co" "coopens.com" "hhi.io" "iie.io" "iirii.com" "lonal.com" "nocs.cn" "ossse.com" "osssn.com" "pyios.com" "wsw.io" "yyi.io"; do
  echo "Start Create Kubernetes Secret With SSL Cert:$loop_i"
  kubectl create secret tls coam-nginx-acme-$loop_i-tls --cert=/etc/ssl/coam/domains/$loop_i/fullchain.crt --key=/etc/ssl/coam/domains/$loop_i/private.key -n coam-dev-nginx-ns
done

echo "😇 防止系统OutOfCpu过载,请耐心等待 20 秒..."
sleep 20

echo "[🤖>>>]部署 coam-dev-mysql-ns 服务"
kubectl apply -f $K8sCoam/k8s.350.coam-dev-mysql-ns.deploy.yaml
echo $'\n'

echo "😇 防止系统OutOfCpu过载,请耐心等待 20 秒..."
sleep 20

echo "[🤖>>>]部署 coam-dev-mongodb-ns 服务"
kubectl apply -f $K8sCoam/k8s.360.coam-dev-mongodb-ns.deploy.yaml
echo $'\n'

echo "😇 防止系统OutOfCpu过载,请耐心等待 20 秒..."
sleep 20

echo "[🤖>>>]部署 coam-dev-redis-ns 服务"
kubectl apply -f $K8sCoam/k8s.370.coam-dev-redis-ns.deploy.yaml

#echo "部署 coam-prod-ss-proxy-ns 服务"
#kubectl apply -f $K8sCoam/k8s.420.coam-prod-ss-proxy-ns.deploy.yaml
#echo $'\n'

#echo "部署 coam-prod-sw-vpn-ns 服务"

#kubectl apply -f $K8sCoam/k8s.430.coam-prod-sw-vpn-ns.deploy.yaml

# 手动创建 configmap: `vpn-config`
#sudo kubectl create configmap vpn-config -n coam-prod-sw-vpn-ns \
#  --from-file=etc_strongswan_strongswan.d_charon-logging.conf=/etc/strongswan/strongswan.d/charon-logging.conf \
#  --from-file=etc_strongswan_ipsec.conf=/etc/strongswan/ipsec.conf \
#  --from-file=etc_strongswan_ipsec.secrets=/etc/strongswan/ipsec.secrets \
#  --from-file=etc_strongswan_strongswan.conf=/etc/strongswan/strongswan.conf

#echo "SW-VPN 服务已部署完成"

#echo "😇 防止系统OutOfCpu过载,请耐心等待 20 秒..."
#sleep 20

#echo "部署 coam-dev-rabbitmq-ns 服务"
#kubectl apply -f $K8sCoam/k8s.540.coam-dev-rabbitmq-ns.deploy.yaml

#echo "部署 coam-dev-lsyncd-ns 服务"
#kubectl apply -f $K8sCoam/k8s.150.coam-dev-lsyncd-ns.deploy.yaml

#echo "😇 防止系统OutOfCpu过载,请耐心等待 20 秒..."
#sleep 20

#echo "部署 coam-dev-emqttd-ns 服务"
#kubectl apply -f $K8sCoam/k8s.560.coam-dev-emqttd-ns.deploy.yaml

#echo "😇 防止系统OutOfCpu过载,请耐心等待 20 秒..."
#sleep 20

#echo "部署 coam-dev-ejabberd-ns 服务"
#kubectl apply -f $K8sCoam/k8s.570.coam-dev-ejabberd-ns.deploy.yaml

#echo "😇 防止系统OutOfCpu过载,请耐心等待 20 秒..."
#sleep 20

echo "部署 coam-prod-docs-ns 服务"
kubectl apply -f $K8sCoam/k8s.600.coam-prod-docs-ns.deploy.yaml

# 循环更新 Kubernetes 证书...
for loop_i in "iirii.com"; do
  echo "Start Create Kubernetes Secret With SSL Cert:$loop_i"
  kubectl create secret tls coam-docs-acme-$loop_i-tls --cert=/etc/ssl/coam/domains/$loop_i/fullchain.crt --key=/etc/ssl/coam/domains/$loop_i/private.key -n coam-prod-docs-ns
done

echo "部署 coam-prod-run-s-ns 服务"
kubectl apply -f $K8sCoam/k8s.610.coam-prod-run-s-ns.deploy.yaml

# 循环更新 Kubernetes 证书...
for loop_i in "iirii.com"; do
  echo "Start Create Kubernetes Secret With SSL Cert:$loop_i"
  kubectl create secret tls coam-run-s-acme-$loop_i-tls --cert=/etc/ssl/coam/domains/$loop_i/fullchain.crt --key=/etc/ssl/coam/domains/$loop_i/private.key -n coam-prod-run-s-ns
done

#TODO: ELK...
#kubectl apply -f $K8sCoam/k8s.780.coam-dev-elk-ns.us-ns.yaml
#kubectl apply -f $K8sCoam/k8s.781.coam-dev-elk-ns.us-elasticsearch.yaml
#kubectl apply -f $K8sCoam/k8s.782.coam-dev-elk-ns.us-logstash.yaml
#kubectl apply -f $K8sCoam/k8s.783.coam-dev-elk-ns.us-kibana.yaml
#kubectl apply -f $K8sCoam/k8s.784.coam-dev-elk-ns.us-filebeat.yaml

# [一些访问配置] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

source $rs_path/kubernetes/run/k8s-cluster-env.sh

# [Ended] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
