#!/usr/bin/env bash
set -e

sc_dir="$(
  cd "$(dirname "$0")" >/dev/null 2>&1 || exit
  pwd -P
)"

rs_path=${sc_dir/kubespray*/kubespray}
source $rs_path/bin/libs/headers.sh
source $rs_path/bin/libs/others.sh

Case=${1:-"test"}

ebc_debug "解析命令参数> kubespray.sh $Case"

case "$Case" in
help)
  ebc_debug "说明: kubespray.sh 命令快捷参数"
  ebc_debug "用法: kubespray.sh <Case>"
  ebc_debug "示例: kubespray.sh issue"
  ;;
test)
  echo "nothing to do: take it easy..."
  ;;
codes)
  caller git fetch --tags origin
  caller git checkout rebuild
  caller git merge $(git describe --tags $(git rev-list --tags --max-count=1))
  # git checkout tags/v2.28.0
  ;;
pip-mirrors)
    # [PyPI 软件仓库](https://mirrors.tuna.tsinghua.edu.cn/help/pypi/)
    caller python3 -m pip install -i https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple --upgrade pip
    caller pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple
    caller pip config get global.index-url
    ;;
init)
    # caller apt install python3-pip
    # caller pip3 install -i https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple -r requirements.txt
    caller pip3 install -r requirements.txt
  ;;
reconfig)
  #caller rm -rf inventory/mycluster
  #caller cp -rfp inventory/sample inventory/mycluster
  #caller rsync -H -avP --delete --exclude=conf/{cros_headers.conf,log_format.conf,proxy_headers.conf,ssl/,luafile/} --filter='protect conf/ssl' inventory/sample inventory/mycluster
  caller rsync -H -avP --delete --filter='P hosts.yaml' inventory/sample/. inventory/mycluster
#  python3 contrib/inventory_builder/inventory.py {{ lookup('ansible.builtin.env', 'DEPLOY_SERVERS') | split(',') | join(' ') }}

#  caller sed -i "s/^minimal_node_memory_mb: 1024/minimal_node_memory_mb: 800/g" roles/kubernetes/preinstall/defaults/main.yml
#  caller sed -i "s/^minimal_master_memory_mb: 1500/minimal_master_memory_mb: 800/g" roles/kubernetes/preinstall/defaults/main.yml

#  caller sed -i "s/^kube_proxy_mode: ipvs/kube_proxy_mode: iptables/g" inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
#  caller sed -i "s/^# supplementary_addresses_in_ssl_keys:.*/supplementary_addresses_in_ssl_keys: [ 1.cos.iirii.com ]/g" inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
  caller sed -i "s/^enable_nodelocaldns: true/enable_nodelocaldns: false/g" inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
  caller sed -i "s/^# kubectl_localhost: false/kubectl_localhost: true/g" inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
  caller sed -i "s/^kube_network_plugin: calico/kube_network_plugin: cilium/g" inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml

  # MetalLB [kube-proxy in IPVS mode breaks MetalLB IPs #153](https://github.com/metallb/metallb/issues/153#issuecomment-518651132)
  caller sed -i "s/^kube_proxy_strict_arp: false/kube_proxy_strict_arp: true/g" inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml

    echo 'kube_apiserver_node_port_range: "30000-39999"' >> inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml

#  caller sed -i "s/^# dashboard_enabled: false/dashboard_enabled: true/g" inventory/mycluster/group_vars/k8s_cluster/addons.yml
  caller sed -i "s/^local_volume_provisioner_enabled: false/local_volume_provisioner_enabled: true/g" inventory/mycluster/group_vars/k8s_cluster/addons.yml
  caller sed -i "s/^cert_manager_enabled: false/cert_manager_enabled: true/g" inventory/mycluster/group_vars/k8s_cluster/addons.yml
  caller sed -i "s/^metallb_enabled: false/metallb_enabled: true/g" inventory/mycluster/group_vars/k8s_cluster/addons.yml
  caller sed -i "s/^argocd_enabled: false/argocd_enabled: true/g" inventory/mycluster/group_vars/k8s_cluster/addons.yml
  caller sed -i "s/^# argocd_admin_password: \"password\"/argocd_admin_password: \"password\"/g" inventory/mycluster/group_vars/k8s_cluster/addons.yml
  caller sed -i "s/^helm_enabled: false/helm_enabled: true/g" inventory/mycluster/group_vars/k8s_cluster/addons.yml
#  caller sed -i "s/^krew_enabled: false/krew_enabled: true/g" inventory/mycluster/group_vars/k8s_cluster/addons.yml

  caller sed -i "s/^# http_proxy:.*/http_proxy: \"http:\/\/zyfa:112233@0.wh.zsc.iirii.com:8810\"/g" inventory/mycluster/group_vars/all/all.yml
  caller sed -i "s/^# https_proxy:.*/https_proxy: \"http:\/\/zyfa:112233@0.wh.zsc.iirii.com:8810\"/g" inventory/mycluster/group_vars/all/all.yml
  ;;
configs)
    for server in root@15.zsc.iirii.com:22 root@16.zsc.iirii.com:22 root@17.zsc.iirii.com:22 root@18.zsc.iirii.com:22; do
        parse_iirii_server $server ssh_user server_host server_port server_target server_path
        caller ssh -o StrictHostKeyChecking=no $ssh_user@$server_host -p $server_port "sed -i '/server-[0-9]\+\.cluster\.local/d' /etc/hosts"
        caller ssh -o StrictHostKeyChecking=no $ssh_user@$server_host -p $server_port "cat >> /etc/hosts <<'EOF'
10.100.0.105 server-15.cluster.local server-15
10.100.0.106 server-16.cluster.local server-16
10.100.0.107 server-17.cluster.local server-17
10.100.0.108 server-18.cluster.local server-18
EOF"
        caller ssh -o StrictHostKeyChecking=no $ssh_user@$server_host -p $server_port "cat /etc/hosts"
    done

#    caller ssh -o StrictHostKeyChecking=no root@15.zsc.iirii.com -p 22 "echo server-15 > /etc/hostname && cat /etc/hostname && hostname server-15 && hostname"
#    caller ssh -o StrictHostKeyChecking=no root@16.zsc.iirii.com -p 22 "echo server-16 > /etc/hostname && cat /etc/hostname && hostname server-16 && hostname"
#    caller ssh -o StrictHostKeyChecking=no root@17.zsc.iirii.com -p 22 "echo server-17 > /etc/hostname && cat /etc/hostname && hostname server-17 && hostname"
#    caller ssh -o StrictHostKeyChecking=no root@18.zsc.iirii.com -p 22 "echo server-18 > /etc/hostname && cat /etc/hostname && hostname server-18 && hostname"

    for server in 15 16 17 18; do
        caller ssh -o StrictHostKeyChecking=no root@$server.zsc.iirii.com -p 22 "echo server-$server > /etc/hostname && cat /etc/hostname && hostname server-$server && hostname"
    done

    for server in 15 16 17 18; do
        caller ssh -T -o StrictHostKeyChecking=no root@$server.zsc.iirii.com -p 22 << 'EOF'
#!/usr/bin/env bash
set -e

echo "check apt mirrors"
[ ! -f /etc/apt/sources.list.bak ] && {
    echo "setup apt mirrors"
    cp /etc/apt/sources.list /etc/apt/sources.list.bak
    sed -i 's/http:\/\/archive.ubuntu.com/http:\/\/mirrors.cloud.tencent.com/g' /etc/apt/sources.list
    sed -i 's/http:\/\/security.ubuntu.com/http:\/\/mirrors.cloud.tencent.com/g' /etc/apt/sources.list
}
echo "check apt successful"
EOF

    done
  ;;
*)
  echo "[参数命令不合法]case: $Case [test,cluster,k8s,kubesphere,other]"
  exit 1
  ;;
esac

