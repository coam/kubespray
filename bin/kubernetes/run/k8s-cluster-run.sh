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
    echo "Please run k8s-deploy-istio.sh under [kubernetes/run/] dir..."
    exit
fi

# 要求 root 用户身份执行此命令...
#if [[ $EUID -ne 0 ]]; then
#   echo "Error:This script must be run as root!" 1>&2
#   exit 1
#fi

# [kubernetes] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
results=`kubectl get pod --all-namespaces | grep php | wc -l`
if [ $results != 1 ]; then
    echo "结果集: $results";
    kubectl get pod --all-namespaces | grep php
fi

exit

echo "[🤖>>>]初始化 flaskapp 服务"
echo "[kubectl apply -f $K8sCoam/k8s.030.default.flaskapp.istio.yaml]"
kubectl apply -f $K8sCoam/k8s.030.default.flaskapp.istio.yaml
echo $'\n'

echo "[🤖>>>]初始化 httpbin 服务"
echo "[kubectl apply -f $K8sCoam/k8s.030.default.httpbin.yaml]"
kubectl apply -f $K8sCoam/k8s.030.default.httpbin.yaml
echo $'\n'

echo "[🤖>>>]初始化 sleep 服务"
echo "[kubectl apply -f $K8sCoam/k8s.030.default.sleep.istio.yaml]"
kubectl apply -f $K8sCoam/k8s.030.default.sleep.istio.yaml
echo $'\n'


echo "[🤖>>>]初始化 istio-bookinfo 服务"
echo "[kubectl apply -f $K8sCoam/k8s.030.default.bookinfo.istio.yaml]"
kubectl apply -f $K8sCoam/k8s.030.default.bookinfo.istio.yaml
echo $'\n'

#echo "[🤖>>>]初始化 istio 服务"
#echo "[kubectl apply -f $K8sConfig/istio/samples/bookinfo/platform/kube/bookinfo.yaml]"
#kubectl apply -f $K8sConfig/istio/samples/bookinfo/platform/kube/bookinfo.yaml
#echo $'\n'

#echo "[🤖>>>]初始化 sleep 服务"
#echo "[kubectl apply -f $K8sConfig/istio/samples/bookinfo/networking/bookinfo-gateway.yaml]"
#kubectl apply -f $K8sConfig/istio/samples/bookinfo/networking/bookinfo-gateway.yaml
#echo $'\n'

# [一些访问配置] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

source ./k8s-cluster-env.sh

# [Ended] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
