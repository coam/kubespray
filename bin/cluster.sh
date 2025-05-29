#!/usr/bin/env bash
set -xe

sc_dir="$(
  cd "$(dirname "$0")" >/dev/null 2>&1 || exit
  pwd -P
)"

rs_path=${sc_dir/kubespray*/kubespray}
source $rs_path/bin/libs/headers.sh

Case=${1:-"test"}

ebc_debug "解析命令参数> cluster.sh $Case"

case "$Case" in
help)
  ebc_debug "说明: cluster.sh 命令快捷参数"
  ebc_debug "用法: cluster.sh <Case>"
  ebc_debug "示例: cluster.sh issue"
  ;;
test)
  echo "nothing to do: take it easy..."
  ;;
reset)
  ansible-playbook -i inventory/mycluster/hosts.yaml -u root --become --become-user=root -e reset_confirmation=yes reset.yml
  ;;
deploy)
  ansible-playbook -i inventory/mycluster/hosts.yaml -u root --become --become-user=root cluster.yml
  ;;
config)
  # OpenEBS
  helm repo add openebs https://openebs.github.io/charts
  helm repo update
  helm install openebs --namespace openebs openebs/openebs --create-namespace

  # set default sc
  #kubectl patch storageclass local-storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
  kubectl patch storageclass openebs-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

  # Open ArgoCD Service
  #[](https://medium.com/@andrea.grillo96/change-kubernetes-service-type-loadbalancer-or-nodeport-488a61ca5736)
  #kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "ClusterIP"}}'
  kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
  #kubectl create service hello-svc --tcp=80:80 --type NodePort --node-port 30088 -o yaml --dry-run > hello-svc.yaml

  kubectl get sc
  ;;
scale)
  ansible-playbook -i inventory/mycluster/hosts.yaml -u root --become --become-user=root scale.yml -v --flush-cache
  # resolve control-plane being Ready,SchedulingDisabled
  kubectl uncordon server-1
  ;;
remove)
  ansible-playbook -i inventory/mycluster/hosts.yaml -u root --become --become-user=root remove-node.yml -e node=server-3
  ;;
kubesphere)
  # KubeSphere prometheus pv
  ssh -o "StrictHostKeyChecking=no" root@1.cos.iirii.com 'mkdir -p /mnt/disks/ssd1'
  ssh -o "StrictHostKeyChecking=no" root@2.cos.iirii.com 'mkdir -p /mnt/disks/ssd1'

  kubectl apply -f manifests/prometheus-pv.yaml
  #kubectl apply -f manifests/redis-pv.yaml

  kubectl apply -f https://github.com/kubesphere/ks-installer/releases/download/v3.4.0/kubesphere-installer.yaml
  echo "等待 CRD 创建(sleep 5: ensure CRDs are installed first)..."
  sleep 5
  kubectl apply -f https://github.com/kubesphere/ks-installer/releases/download/v3.4.0/cluster-configuration.yaml
  ;;
other)
  kubectl krew install ctx
  kubectl krew install ns
  ;;
*)
  echo "[参数命令不合法]case: $Case [test,cluster,k8s,kubesphere,other]"
  exit 1
  ;;
esac

