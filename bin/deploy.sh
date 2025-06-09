#!/usr/bin/env bash
set -xe

sc_dir="$(
    cd "$(dirname "$0")" >/dev/null 2>&1 || exit
    pwd -P
)"

rs_path=${sc_dir/kubespray*/kubespray}
source $rs_path/bin/libs/headers.sh

Case=${1:-"test"}

ebc_debug "解析命令参数> deploy.sh $Case"

case "$Case" in
help)
    ebc_debug "说明: deploy.sh 命令快捷参数"
    ebc_debug "用法: deploy.sh <Case>"
    ebc_debug "示例: deploy.sh issue"
    ;;
test)
    echo "nothing to do: take it easy..."
    ;;
metrics)
    caller kubectl delete deployment metrics-server -n kube-system || true

    # fix: the HPA was unable to compute the replica count: failed to get cpu utilization: missing request for cpu
    caller kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    caller "kubectl -n kube-system describe deployment metrics-server | grep 'kubelet-insecure-tls' || :"
    #caller kubectl -n kube-system patch deployment metrics-server --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args", "value": ["--kubelet-insecure-tls"]}]'
    #[kubectl patch: Is it possible to add multiple values to an array within a sinlge patch execution](https://stackoverflow.com/questions/62578789/kubectl-patch-is-it-possible-to-add-multiple-values-to-an-array-within-a-sinlge)
    caller kubectl -n kube-system patch deployment metrics-server --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
    caller "kubectl -n kube-system describe deployment metrics-server | grep 'kubelet-insecure-tls' || :"

    #helm install --set 'args={--kubelet-insecure-tls}' --namespace kube-system metrics stable/metrics-server

    caller kubectl top pods -A
    ;;
*)
    echo "[参数命令不合法]case: $Case [test,cluster,k8s,kubesphere,other]"
    exit 1
    ;;
esac
