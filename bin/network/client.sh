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

ebc_debug "解析命令参数> networks.sh $Case"

case "$Case" in
help)
    ebc_debug "说明: networks.sh 命令快捷参数"
    ebc_debug "用法: networks.sh <Case>"
    ebc_debug "示例: networks.sh issue"
    ;;
test)
    tailscale up --force-reauth --login-server=https://w.gpuez.com:58080 --hostname=zsc-12
    systemctl restart tailscaled
    #brew services list
    #brew services restart tailscale
    ;;
deploy)
    servers=()
    servers+=("root@1.wh.zsc.iirii.com:22")
    servers+=("root@2.wh.zsc.iirii.com:22")
    servers+=("root@11.zsc.iirii.com:22")
    servers+=("root@12.zsc.iirii.com:22")
    servers+=("root@13.zsc.iirii.com:22")
    servers+=("root@14.zsc.iirii.com:22")
    servers+=("root@10.qy.zsc.iirii.com:1022")
    for server in "${servers[@]}"; do
        parse_iirii_server $server ssh_user server_host server_port server_target server_path

        server_name="${server_path//./-}"

#        login_server=https://2.cos.iirii.com:58080
#        login_server=http://0.gw.zsc.iirii.com:58080
#        login_server=http://w.gpuez.com:58080
        login_server=https://w.gpuez.com:58080

        caller ssh -T -o StrictHostKeyChecking=no $ssh_user@$server_target.iirii.com -p $server_port <<EOF
#!/usr/bin/env bash
set -e

echo "check tailscale client config"

#[ ! -f /var/snap/tailscale/common/tailscaled.state ] && {
#    echo "install tailscale service"
#    snap install tailscale
#}

[ ! -f /var/lib/tailscale/tailscaled.state ] && {
    echo "install tailscale service"
    #curl -fsSL https://tailscale.com/install.sh | sh

    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list

    apt-get update
    apt-get install -y tailscale
}

tailscale ip >/dev/null 2>&1 || {
    echo "tailscale ip check failed，try tailscale login"
    tailscale login --auth-key 2e7af75a7514700fddd51b8f47bf6498190b28f786d5c31c --login-server $login_server --hostname $server_name
}

echo "tailscale client check successful..."
tailscale status
EOF
    done
    ;;
tests)
    servers=()
#    servers+=("root@11.zsc.iirii.com:22")
#    servers+=("root@12.zsc.iirii.com:22")
#    servers+=("root@13.zsc.iirii.com:22")
#    servers+=("root@14.zsc.iirii.com:22")
    servers+=("root@10.qy.zsc.iirii.com:1022")
    for server in "${servers[@]}"; do
        parse_iirii_server $server ssh_user server_host server_port server_target server_path

        server_name="${server_path//./-}"
#        login_server=https://2.cos.iirii.com:58080
#        login_server=http://0.gw.zsc.iirii.com:58080
#        login_server=http://w.gpuez.com:58080
        login_server=https://w.gpuez.com:58080

        caller ssh -T -o StrictHostKeyChecking=no $ssh_user@$server_target.iirii.com -p $server_port <<EOF
#!/usr/bin/env bash
set -e

tailscale login --auth-key 2e7af75a7514700fddd51b8f47bf6498190b28f786d5c31c --login-server $login_server --hostname $server_name
#tailscale login --auth-key 2e7af75a7514700fddd51b8f47bf6498190b28f786d5c31c --login-server https://w.gpuez.com:58080 --hostname zsc-qy-10
#tailscale logout
#tailscale status
EOF
    done
    ;;
checks)
    servers=()
#    servers+=("root@11.zsc.iirii.com:22")
#    servers+=("root@12.zsc.iirii.com:22")
#    servers+=("root@13.zsc.iirii.com:22")
#    servers+=("root@14.zsc.iirii.com:22")
    servers+=("root@10.qy.zsc.iirii.com:1022")
    for server in "${servers[@]}"; do
        parse_iirii_server $server ssh_user server_host server_port server_target server_path

        caller ssh -T -o StrictHostKeyChecking=no $ssh_user@$server_target.iirii.com -p $server_port 'tailscale netcheck --verbose'
    done
    ;;
ping)
    servers=()
    servers+=("root@1.wh.zsc.iirii.com:22")
    servers+=("root@2.wh.zsc.iirii.com:22")
    servers+=("root@11.zsc.iirii.com:22")
    servers+=("root@12.zsc.iirii.com:22")
    servers+=("root@13.zsc.iirii.com:22")
    servers+=("root@14.zsc.iirii.com:22")
    servers+=("root@10.qy.zsc.iirii.com:1022")
    for server in "${servers[@]}"; do
        parse_iirii_server $server ssh_user server_host server_port server_target server_path

        caller ssh -T -o StrictHostKeyChecking=no $ssh_user@$server_target.iirii.com -p $server_port 'ping 100.64.0.1 -c 5'
    done
    ;;
status)
    servers=()
    servers+=("root@1.wh.zsc.iirii.com:22")
    servers+=("root@2.wh.zsc.iirii.com:22")
    servers+=("root@11.zsc.iirii.com:22")
    servers+=("root@12.zsc.iirii.com:22")
    servers+=("root@13.zsc.iirii.com:22")
    servers+=("root@14.zsc.iirii.com:22")
    servers+=("root@10.qy.zsc.iirii.com:1022")
    for server in "${servers[@]}"; do
        parse_iirii_server $server ssh_user server_host server_port server_target server_path

        caller ssh -o StrictHostKeyChecking=no $ssh_user@$server_host -p $server_port 'tailscale status'
    done
    ;;
logs)
    servers=()
    servers+=("root@11.zsc.iirii.com:22")
    servers+=("root@12.zsc.iirii.com:22")
    servers+=("root@13.zsc.iirii.com:22")
    servers+=("root@14.zsc.iirii.com:22")
    servers+=("root@10.qy.zsc.iirii.com:1022")
    for server in "${servers[@]}"; do
        parse_iirii_server $server ssh_user server_host server_port server_target server_path

        #caller ssh -o StrictHostKeyChecking=no $ssh_user@$server_host -p $server_port 'journalctl -u snap.tailscale.tailscaled -f'
        caller ssh -o StrictHostKeyChecking=no $ssh_user@$server_host -p $server_port 'journalctl -u tailscaled -f'
    done
    ;;
*)
    echo "[参数命令不合法]case: $Case [test]"
    exit 1
    ;;
esac
