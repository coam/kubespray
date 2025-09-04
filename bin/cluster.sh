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
    # caller rm -rf inventory/mycluster
    caller rsync -H -avP --delete --filter='P hosts.yaml' --filter='P vars.yaml' inventory/sample/. inventory/mycluster
    # caller ansible-playbook -i inventory/mycluster/hosts.yaml --tags debug -u root --become --become-user=root cluster.yml --extra-vars "@inventory/mycluster/vars.yaml" --check
    # caller ansible-playbook -i inventory/mycluster/hosts.yaml -u root --become --become-user=root cluster.yml --extra-vars "@inventory/mycluster/vars.yaml" --check
    # caller ansible-inventory -i inventory/mycluster/hosts.yaml cluster.yml --list --yaml --output _/mycluster/v0.yaml
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
    # [Kubespray' s Cilium upgrade fails #12252](https://github.com/kubernetes-sigs/kubespray/issues/12252)
    #caller ansible-playbook -i inventory/mycluster/hosts.yaml -u root --become --become-user=root -e "cilium_remove_old_resources=true" -e "kube_owner=root" scale.yml -v --flush-cache
    caller ansible-playbook -i inventory/mycluster/hosts.yaml -u root --become --become-user=root scale.yml -v --flush-cache
    # resolve control-plane being Ready,SchedulingDisabled
    # caller kubectl uncordon server-1
    ;;
taints)
    caller "kubectl get nodes -l node-role.kubernetes.io/control-plane= -o jsonpath='{.items[*].spec.taints}' | jq"
    caller "kubectl describe node server-15 | grep Taints"
    caller "kubectl describe node server-16 | grep Taints"
    # 设置污点
    caller "kubectl taint nodes server-15 node-role.kubernetes.io/control-plane:NoSchedule || true"
    caller "kubectl taint nodes server-16 node-role.kubernetes.io/control-plane:NoSchedule || true"
    # 移除污点
    #caller kubectl taint nodes server-15 node-role.kubernetes.io/control-plane:NoSchedule-
    #caller kubectl taint nodes server-16 node-role.kubernetes.io/control-plane:NoSchedule-
    ;;
remove)
    node_name=server-18
    node_name=server-qy-10
    node_name=server-hf-18
    # caller kubectl drain $node_name --ignore-daemonsets --delete-emptydir-data
    # caller kubectl delete node $node_name

    #caller ansible-playbook -i inventory/mycluster/hosts.yaml -u root --become --become-user=root remove-node.yml -e node=$node_name
    caller ansible-playbook -i inventory/mycluster/hosts.yaml -u root --become --become-user=root remove-node.yml -v --extra-vars "node=$node_name"

    # 更新集群证书
    # caller ansible-playbook -i inventory/mycluster/hosts.yaml --become --become-user=root cluster.yml -e "reset_confirmation=yes"

    # 修改 inventory/mycluster/hosts.yaml，删除要移除节点的所有配置 $node_name
    ;;
down)
    true && {
        caller scp root@4.hf.zsc.iirii.com:/etc/kubernetes/admin.conf ~/.kube/config.zsc.hf.4.yaml
        #caller sed -i "s/127.0.0.1:6443/10.100.0.105:6443/g" ~/.kube/config.zsc.hf.4.yaml
        caller sed -i "s/127.0.0.1:6443/183.162.211.229:6443/g" ~/.kube/config.zsc.hf.4.yaml
        caller sed -i "s/cluster.local/zsc.cluster.hf.4/g" ~/.kube/config.zsc.hf.4.yaml
        caller sed -i "s/kubernetes-admin/kubernetes-admin-hf-4/g" ~/.kube/config.zsc.hf.4.yaml
        #caller cat ~/.kube/config.zsc.hf.4.yaml
    }

    false && {
        caller scp root@11.zsc.iirii.com:/etc/kubernetes/admin.conf ~/.kube/config.zsc.11.yaml
        #caller sed -i "s/127.0.0.1:6443/10.100.0.101:6443/g" ~/.kube/config.zsc.11.yaml
        caller sed -i "s/127.0.0.1:6443/127.0.0.1:16443/g" ~/.kube/config.zsc.11.yaml
        caller sed -i "s/cluster.local/zsc.cluster.11/g" ~/.kube/config.zsc.11.yaml
        caller sed -i "s/kubernetes-admin/kubernetes-admin-11/g" ~/.kube/config.zsc.11.yaml
        caller cat ~/.kube/config.zsc.11.yaml
    }

    false && {
        caller scp root@15.zsc.iirii.com:/etc/kubernetes/admin.conf ~/.kube/config.zsc.15.yaml
        #caller sed -i "s/127.0.0.1:6443/10.100.0.105:6443/g" ~/.kube/config.zsc.15.yaml
        caller sed -i "s/127.0.0.1:6443/127.0.0.1:6443/g" ~/.kube/config.zsc.15.yaml
        caller sed -i "s/cluster.local/zsc.cluster.15/g" ~/.kube/config.zsc.15.yaml
        caller sed -i "s/kubernetes-admin/kubernetes-admin-15/g" ~/.kube/config.zsc.15.yaml
        caller cat ~/.kube/config.zsc.15.yaml
    }
    ;;
info)
    caller 'kubectl describe nodes | grep -i taints'
    ;;
other)
    caller kubectl krew install ctx
    caller kubectl krew install ns
    ;;
clean)
    # 在主节点上执行
    #kubectl drain <节点名称> --delete-local-data --force --ignore-daemonsets
    #kubectl delete node <节点名称>

    #停止所有 Kubernetes 服务
    sudo systemctl stop kubelet
    sudo systemctl stop docker containerd

    #卸载 Kubernetes 相关软件包
    sudo apt-get purge -y kubelet kubeadm kubectl
    sudo apt-get purge -y docker-ce docker-ce-cli containerd.io

    #删除所有相关文件和目录
    sudo rm -rf /etc/kubernetes
    sudo rm -rf /var/lib/kubelet
    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd
    sudo rm -rf /etc/cni/net.d
    sudo rm -rf /opt/cni/bin

    #清理网络配置
    sudo iptables -F
    sudo iptables -t nat -F
    sudo iptables -t mangle -F
    sudo iptables -X

    #删除残留的 Docker 配置

    sudo rm -rf /var/run/docker.sock
    sudo rm -rf /etc/docker

    #清理系统d服务配置

    sudo systemctl daemon-reload

    #可选：删除其他可能的相关包

    sudo apt-get purge -y kubernetes-cni
    sudo apt-get autoremove -y

    # 3. 验证清理

    # 检查是否还有kubelet进程
    ps aux | grep kubelet

    # 检查是否还有docker/containerd进程
    ps aux | grep docker
    ps aux | grep containerd

    # 检查相关目录是否已删除
    ls /etc/kubernetes
    ls /var/lib/kubelet
    ;;
*)
    echo "[参数命令不合法]case: $Case [test,cluster,k8s,kubesphere,other]"
    exit 1
    ;;
esac
