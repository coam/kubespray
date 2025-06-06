#!/usr/bin/env bash
set -e

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
reviews)
    #caller rm -rf inventory/mycluster
    caller rsync -H -avP --delete --filter='P hosts.yaml' --filter='P vars.yaml' inventory/sample/. inventory/mycluster
    #    caller ansible-playbook -i inventory/mycluster/hosts.yaml --tags debug -u root --become --become-user=root cluster.yml --extra-vars "@inventory/mycluster/vars.yaml" --check
    #    caller ansible-playbook -i inventory/mycluster/hosts.yaml -u root --become --become-user=root cluster.yml --extra-vars "@inventory/mycluster/vars.yaml" --check
    #    caller ansible-inventory -i inventory/mycluster/hosts.yaml cluster.yml --list --yaml --output _/mycluster/v0.yaml
    # caller ansible-inventory -i inventory/mycluster/hosts.yaml cluster.yml --extra-vars '@inventory/mycluster/vars.yaml' --list --yaml --output _/mycluster/v1.yaml
    caller ansible-playbook -i inventory/mycluster/hosts.yaml cluster.yml --extra-vars '@inventory/mycluster/vars.yaml' --check -v
    ;;
reset)
    caller ansible-playbook -i inventory/mycluster/hosts.yaml -u root --become --become-user=root -e reset_confirmation=yes reset.yml
    ;;
deploy)
    caller ansible-playbook -i inventory/mycluster/hosts.yaml -u root --become --become-user=root cluster.yml
    ;;
scale)
    caller ansible-playbook -i inventory/mycluster/hosts.yaml -u root --become --become-user=root scale.yml -v --flush-cache
    # resolve control-plane being Ready,SchedulingDisabled
    caller kubectl uncordon server-1
    ;;
remove)
    caller ansible-playbook -i inventory/mycluster/hosts.yaml -u root --become --become-user=root remove-node.yml -e node=server-3
    ;;
down)
    caller scp root@15.zsc.iirii.com:/etc/kubernetes/admin.conf ~/.kube/config.cluster.local
    caller sed -i "s/127.0.0.1:6443/10.100.0.105:6443/g" ~/.kube/config.cluster.local
    caller cat ~/.kube/config.cluster.local
    ;;
other)
    caller kubectl krew install ctx
    caller kubectl krew install ns
    ;;
*)
    echo "[参数命令不合法]case: $Case [test,cluster,k8s,kubesphere,other]"
    exit 1
    ;;
esac
