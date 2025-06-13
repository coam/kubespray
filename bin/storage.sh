#!/usr/bin/env bash
set -e

sc_dir="$(
  cd "$(dirname "$0")" >/dev/null 2>&1 || exit
  pwd -P
)"

rs_path=${sc_dir/kubespray*/kubespray}
source $rs_path/bin/libs/headers.sh

Case=${1:-"help"}
Namespace=${2:-"openebs"}

ebc_debug "解析命令参数> storage.sh $Case $Namespace"

shopt -s expand_aliases
alias kc='kubectl -n $Namespace'
export KUBECONFIG=config/kube.config
export HELM_NAMESPACE=$Namespace

export HTTPS_PROXY=http://chess:ceaqaz000@proxy.zsc.iirii.com:7890

case "$Case" in
help)
  ebc_debug "说明: storage.sh 命令快捷参数"
  ebc_debug "用法: storage.sh <Case> <Namespace>"
  ebc_debug "示例: storage.sh install openebs"
  ;;
init)
    # OpenEBS
    caller helm repo add openebs https://openebs.github.io/charts
    caller helm repo update
      ;;
install)
    caller helm install openebs --namespace $Namespace openebs/openebs --create-namespace

    # set default sc
    #kubectl patch storageclass local-storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    caller kubectl patch storageclass openebs-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    ;;
info)
  caller kubectl get sc
  ;;
*)
  echo "未知命令: action $Case [支持 init,install,uninstall,clean]..."
  exit 1
  ;;
esac


