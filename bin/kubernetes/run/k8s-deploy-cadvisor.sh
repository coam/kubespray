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

# 删除旧配置文件
echo "🦀删除旧配置文件..."
echo "删除 [$K8sCoam/k8s.040.cadvisor.cadvisor.yaml] ..."
rm -rf $K8sCoam/k8s.030.cadvisor.cadvisor.yaml

# 创建新的配置文件
echo "🦆创建新配置文件..."
echo "创建 [$K8sCoam/k8s.040.cadvisor.cadvisor.yaml] ..."
kustomize build $K8sCoam/cadvisor/deploy/kubernetes/overlays/examples > $K8sCoam/k8s.030.cadvisor.cadvisor.yaml

echo "🕸配置文件更新完成..."

# [Ended] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
