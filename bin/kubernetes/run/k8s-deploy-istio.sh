#!/bin/bash

# 张亚飞 ...
# [Tool] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

echo "🤡验证当前目录是否一致..."

# 验证当前目录...
K8sMain="$(pwd -P)/../.."
K8sRoot="$K8sMain/kubernetes"
K8sConfig="$K8sRoot/config"
K8sCoam="$K8sRoot/coam"
K8sRun="$K8sRoot/run"
K8sSrc="$K8sRoot/src"
if [ ! -d $K8sRun ]; then
    echo "🤖Sorry: [K8sRun: $K8sRun] Not Exist Error!"
    echo "Please run k8s-deploy-istio.sh under [kubernetes/run/] dir..."
    exit
fi

# [kubernetes] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

# 更新 Istio 版本...
IstioVersion="1.3.3"
echo "🦆配置 Istio 版本 [IstioVersion: $IstioVersion]"

# 删除旧配置文件
echo "🦀删除旧配置文件..."
echo "删除 [$K8sCoam/k8s.021.istio-system.istio-init.yaml] ..."
rm -rf $K8sCoam/_.k8s.021.istio-system.istio-init.yaml
echo "删除 [$K8sCoam/k8s.021.istio-system.istio-cni.yaml] ..."
rm -rf $K8sCoam/_.k8s.021.istio-system.istio-cni.yaml
echo "删除 [$K8sCoam/k8s.022.istio-system.istio.yaml] ..."
rm -rf $K8sCoam/_.k8s.022.istio-system.istio.yaml

# 拷贝自定义配置文件
echo "🧚同步自定义配置文件..."
echo "同步 cp -rf $K8sConfig/istio/* -> $K8sSrc/istio-$IstioVersion..."
cp -rf $K8sConfig/istio/* $K8sSrc/istio-$IstioVersion

# 创建新的配置文件
echo "🦆创建新配置文件..."
echo "创建 [$K8sCoam/k8s.021.istio-system.istio-init.yaml] ..."
helm template $K8sSrc/istio-$IstioVersion/install/kubernetes/helm/istio-init --name istio-init --namespace istio-system > $K8sCoam/_.k8s.021.istio-system.istio-init.yaml
echo "创建 [$K8sCoam/k8s.021.istio-system.istio-cni.yaml] ..."
helm template $K8sSrc/istio-$IstioVersion/install/kubernetes/helm/istio-cni --name istio-cni --namespace istio-system > $K8sCoam/_.k8s.021.istio-system.istio-cni.yaml
echo "创建 [$K8sCoam/k8s.022.istio-system.istio.yaml] ..."
helm template $K8sSrc/istio-$IstioVersion/install/kubernetes/helm/istio --name istio --namespace istio-system > $K8sCoam/_.k8s.022.istio-system.istio.yaml

echo "🕸配置文件更新完成..."

exit;

# [部署] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

echo "[🤖>>>]创建 Istio 网格服务命名空间"
echo "[kubectl apply -f $K8sCoam/k8s.020.istio-system.namespace.yaml]"
kubectl apply -f $K8sCoam/k8s.020.istio-system.namespace.yaml
echo $'\n'

echo "[🤖>>>]初始化 Istio 网格服务插件"
echo "[kubectl apply -f $K8sCoam/k8s.021.istio-system.istio-init.yaml]"
kubectl apply -f $K8sCoam/_.k8s.021.istio-system.istio-init.yaml
echo $'\n'

echo "[🤖>>>]创建 Istio 网格服务命名空间"
echo "[kubectl apply -f $K8sCoam/k8s.020.istio-system.namespace.yaml]"
kubectl apply -f $K8sCoam/k8s.020.istio-system.namespace.yaml
echo $'\n'

echo "[🤖>>>]初始化 Istio 网格服务插件"
echo "[kubectl apply -f $K8sCoam/k8s.021.istio-system.istio-init.yaml]"
kubectl apply -f $K8sCoam/_.k8s.021.istio-system.istio-init.yaml
echo $'\n'

echo "😇 创建 Istio Jobs,请耐心等待 10+ 秒..."
sleep 10

#[AWK程序设计语言](https://awk.readthedocs.io/en/latest/chapter-one.html)
#[awk一行和多行之间的转换](https://peloo.net/?p=784)
#[shell替换和去掉换行符](https://blog.51cto.com/853056088/1952430)
kube_istio_init_crd_jobs=`kubectl get pods -n istio-system | grep istio-init-crd | awk '{print $1}' | awk '{printf"%s-",$0}'`
kube_istio_init_crd_status=`kubectl get pods -n istio-system | grep istio-init-crd | awk '{print $3}' | awk '{printf"%s-",$0}'`

# 等待次数...
steps=10
while [ $kube_istio_init_crd_status != "Completed-Completed-" ]
do
    echo "💤等待 [$kube_istio_init_crd_jobs] Jobs,状态: [$kube_istio_init_crd_status] [$steps]..."
    kube_istio_init_crd_status=`kubectl get pods -n istio-system | grep istio-init-crd | awk '{print $3}' | awk '{printf"%s-",$0}'`
    sleep 1
    steps=$(( $steps + 1 ))
done

echo "😇 Job创建完成,已等待 $steps 秒..."

echo "[🤖>>>]部署 Istio 网格服务插件"
echo "[kubectl apply -f $K8sCoam/k8s.022.istio-system.istio.yaml]"
kubectl apply -f $K8sCoam/_.k8s.022.istio-system.istio.yaml
echo $'\n'

echo "[🤖>>>]配置 Istio 附加功能"
echo "[kubectl apply -f $K8sCoam/k8s.023.istio-system.addon.yaml]"
kubectl apply -f $K8sCoam/k8s.023.istio-system.addon.yaml
echo $'\n'

echo "[🤖>>>]检查默认策略 - 解决 Mysql 连接问题"
steps=0
while !(kubectl get meshpolicies.authentication.istio.io default)
do
    echo "💤等待创建 [kubectl get meshpolicies.authentication.istio.io default]资源, [$steps]..."
    sleep 1
    steps=$(( $steps + 1 ))
done

echo "[🤖>>>]删除默认策略 - 暂时解决 Mysql 连接问题"
echo "[kubectl describe meshpolicies.authentication.istio.io default]"
kubectl describe meshpolicies.authentication.istio.io default
echo $'\n'

echo "[kubectl delete meshpolicies.authentication.istio.io default]"
kubectl delete meshpolicies.authentication.istio.io default
echo $'\n'

# [升级] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

kubectl apply -f $K8sCoam/_.k8s.021.istio-system.istio-init.yaml

# [其它] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#[安全方面的常见问题](https://istio.io/zh/help/faq/security/#mysql-with-mtls)
#[Istio blocking connection to MySQL](https://stackoverflow.com/questions/53947015/istio-blocking-connection-to-mysql)
#kubectl describe meshpolicies.authentication.istio.io default
#kubectl delete meshpolicies.authentication.istio.io default

#[Connection Failure to a MySQL Service](https://github.com/istio/istio/issues/10062)
# [Ended] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
