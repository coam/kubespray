#!/bin/bash

# [Tool] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

# 自动获取 sudo 权限
#echo 'os-coam-000' | sudo -S hostname
echo 'aajjffkk ' | sudo -S hostname

# [Tool] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
K8sCoam=/data/home/coam/Run/runs/kubernetes/coam

echo "🤡 测试(start)..."

#kubectl delete -f $K8sCoam/k8s.310.coam-dev-nginx-ns.deploy.yaml
#kubectl apply -f $K8sCoam/k8s.310.coam-dev-nginx-ns.deploy.yaml

# 循环更新 Kubernetes 证书...
for loop_i in "coam.co" "coopens.com" "hhi.io" "iie.io" "iirii.com" "ioros.com" "lonal.com" "nocs.cn" "ossse.com" "osssn.com" "pyios.com" "wsw.io" "yyi.io"; do
  echo "Start Create Kubernetes Secret With SSL Cert:$loop_i"
  kubectl create secret tls coam-nginx-acme-$loop_i-tls --cert=/etc/ssl/coam/domains/$loop_i/fullchain.crt --key=/etc/ssl/coam/domains/$loop_i/private.key -n coam-dev-nginx-ns
done

echo "🤡 测试(ok)..."

# [Ended] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
