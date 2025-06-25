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
#setup)
#    # 替换为自己的网段(IPV4或IPV6)
#    caller tailscale up --advertise-routes=20.13.3.0/24
#    ;;
mac)
    #brew install tailscale

    #login_server=http://0.gw.zsc.iirii.com:58080
    login_server=http://w.gpuez.com:58080
    server_name=mac-client

    caller tailscale login --auth-key 2e7af75a7514700fddd51b8f47bf6498190b28f786d5c31c --login-server $login_server --hostname $server_name
    ;;
server-reconfig)
    wget --output-document=bin/conf/headscale/config.yaml https://raw.githubusercontent.com/juanfont/headscale/refs/tags/v0.26.1/config-example.yaml

    # 2.cos.iirii.com
    false && {
        caller yq -i '.server_url = "http://127.0.0.1:58080"' bin/conf/headscale/config.yaml
        caller yq -i '.listen_addr = "0.0.0.0:58080"' bin/conf/headscale/config.yaml
        caller yq -i '.metrics_listen_addr = "127.0.0.1:59090"' bin/conf/headscale/config.yaml
        caller yq -i '.grpc_listen_addr = "127.0.0.1:50443"' bin/conf/headscale/config.yaml
        caller yq -i '.grpc_allow_insecure = true' bin/conf/headscale/config.yaml

        caller yq -i '.acme_email = "zyf@iirii.com"' bin/conf/headscale/config.yaml
        caller yq -i '.tls_letsencrypt_hostname = "2.cos.iirii.com"' bin/conf/headscale/config.yaml
        caller yq -i '.log.level = "debug"' bin/conf/headscale/config.yaml
    }

    # 0.gw.zsc.iirii.com
    true && {
        caller yq -i '.server_url = "http://127.0.0.1:58080"' bin/conf/headscale/config.yaml
        caller yq -i '.listen_addr = "0.0.0.0:58080"' bin/conf/headscale/config.yaml
        caller yq -i '.metrics_listen_addr = "127.0.0.1:59090"' bin/conf/headscale/config.yaml
        caller yq -i '.grpc_listen_addr = "127.0.0.1:50443"' bin/conf/headscale/config.yaml
        caller yq -i '.grpc_allow_insecure = true' bin/conf/headscale/config.yaml

        #caller yq -i '.acme_email = "zyf@iirii.com"' bin/conf/headscale/config.yaml
        #caller yq -i '.tls_letsencrypt_hostname = "2.cos.iirii.com"' bin/conf/headscale/config.yaml
        caller yq -i '.log.level = "debug"' bin/conf/headscale/config.yaml
    }
    ;;
server-deploy)
    servers=()
#    servers+=("root@2.cos.iirii.com:22")
    servers+=("root@0.gw.zsc.iirii.com:22")
    for server in "${servers[@]}"; do
        parse_iirii_server $server ssh_user server_host server_port server_target server_path

        caller ssh -T -o StrictHostKeyChecking=no $ssh_user@$server_target.iirii.com -p $server_port <<'EOF'
#!/usr/bin/env bash
set -e

echo "check headscale service config"
[ ! -f /etc/headscale/config.yaml ] && {
    echo "install headscale service"
    #HEADSCALE_VERSION="0.26.1"
    #HEADSCALE_ARCH="amd64"
    #wget --output-document=headscale.deb "https://github.com/juanfont/headscale/releases/download/v${HEADSCALE_VERSION}/headscale_${HEADSCALE_VERSION}_linux_${HEADSCALE_ARCH}.deb"
    wget --output-document=headscale.deb "https://github.com/juanfont/headscale/releases/download/v0.26.1/headscale_0.26.1_linux_amd64.deb"

    apt install ./headscale.deb
}
echo "check headscale service successful"
EOF

        caller rsync -H -avP --delete -e "ssh -o StrictHostKeyChecking=no -p $server_port" bin/conf/headscale/config.yaml $ssh_user@$server_target.iirii.com:/etc/headscale/config.yaml

        caller ssh -o StrictHostKeyChecking=no $ssh_user@$server_host -p $server_port 'systemctl enable --now headscale && systemctl status headscale'
    done
    ;;
server-logs)
    servers=()
#    servers+=("root@2.cos.iirii.com:22")
    servers+=("root@0.gw.zsc.iirii.com:22")
    for server in "${servers[@]}"; do
        parse_iirii_server $server ssh_user server_host server_port server_target server_path

        caller ssh -o StrictHostKeyChecking=no $ssh_user@$server_host -p $server_port 'journalctl -u headscale -f'
    done
    ;;
server-users)
    servers=()
#    servers+=("root@2.cos.iirii.com:22")
    servers+=("root@0.gw.zsc.iirii.com:22")
    for server in "${servers[@]}"; do
        parse_iirii_server $server ssh_user server_host server_port server_target server_path

        caller ssh -T -o StrictHostKeyChecking=no $ssh_user@$server_target.iirii.com -p 22 <<'EOF'
#!/usr/bin/env bash
set -e

headscale users create zsc
headscale users list

headscale preauthkeys create --user 3 --reusable --expiration=10y
headscale preauthkeys list -u 3
EOF
    done
    ;;
server-status)
    servers=()
    #servers+=("root@2.cos.iirii.com:22")
    servers+=("root@0.gw.zsc.iirii.com:22")
    for server in "${servers[@]}"; do
        parse_iirii_server $server ssh_user server_host server_port server_target server_path

        caller ssh -T -o StrictHostKeyChecking=no $ssh_user@$server_target.iirii.com -p 22 <<'EOF'
#!/usr/bin/env bash
set -e

headscale users list
headscale nodes list

headscale preauthkeys list -u 3
EOF
    done
    ;;
server-tests)
    servers=()
    #servers+=("root@2.cos.iirii.com:22")
    servers+=("root@0.gw.zsc.iirii.com:22")
    for server in "${servers[@]}"; do
        parse_iirii_server $server ssh_user server_host server_port server_target server_path

        caller ssh -T -o StrictHostKeyChecking=no $ssh_user@$server_target.iirii.com -p 22 <<'EOF'
#!/usr/bin/env bash
set -e

headscale users list
headscale nodes list
EOF
    done
    ;;
server-clean)
    servers=()
#    servers+=("root@2.cos.iirii.com:22")
    servers+=("root@0.gw.zsc.iirii.com:22")
    for server in "${servers[@]}"; do
        parse_iirii_server $server ssh_user server_host server_port server_target server_path

        caller ssh -T -o StrictHostKeyChecking=no $ssh_user@$server_target.iirii.com -p 22 <<'EOF'
#!/usr/bin/env bash
set -e

systemctl stop headscale

rm -rf /var/lib/headscale/db.sqlite

systemctl start headscale

headscale users list
headscale nodes list
EOF
    done
    ;;
client-deploy)
    servers=()
    servers+=("root@11.zsc.iirii.com:22")
    servers+=("root@12.zsc.iirii.com:22")
    servers+=("root@13.zsc.iirii.com:22")
    servers+=("root@14.zsc.iirii.com:22")
#    servers+=("root@10.qy.zsc.iirii.com:1022")
    for server in "${servers[@]}"; do
        parse_iirii_server $server ssh_user server_host server_port server_target server_path

        server_name="${server_path//./-}"

#        login_server=https://2.cos.iirii.com:58080
        login_server=http://0.gw.zsc.iirii.com:58080

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
client-tests)
    servers=()
    servers+=("root@11.zsc.iirii.com:22")
    servers+=("root@12.zsc.iirii.com:22")
    servers+=("root@13.zsc.iirii.com:22")
    servers+=("root@14.zsc.iirii.com:22")
    servers+=("root@10.qy.zsc.iirii.com:1022")
    for server in "${servers[@]}"; do
        parse_iirii_server $server ssh_user server_host server_port server_target server_path

        server_name="${server_path//./-}"
#        login_server=https://2.cos.iirii.com:58080
        login_server=http://0.gw.zsc.iirii.com:58080

        caller ssh -T -o StrictHostKeyChecking=no $ssh_user@$server_target.iirii.com -p $server_port <<EOF
#!/usr/bin/env bash
set -e

#tailscale login --auth-key 8da5cbff1dcdacd9765464df4f6de284a4b668e7e9b865f1 --login-server $login_server --hostname $server_name
tailscale logout
#tailscale status

EOF
    done
    ;;
client-status)
    servers=()
    servers+=("root@11.zsc.iirii.com:22")
    servers+=("root@12.zsc.iirii.com:22")
    servers+=("root@13.zsc.iirii.com:22")
    servers+=("root@14.zsc.iirii.com:22")
#    servers+=("root@10.qy.zsc.iirii.com:1022")
    for server in "${servers[@]}"; do
        parse_iirii_server $server ssh_user server_host server_port server_target server_path

        caller ssh -o StrictHostKeyChecking=no $ssh_user@$server_host -p $server_port 'tailscale status'
    done
    ;;
client-logs)
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
remove)
    caller tailscale down
    caller tailscale logout

    caller ip link del tailscale0
    ;;
uninstall)
    caller apt uninstall tailscale
    caller apt-get remove tailscale
    caller apt-get purge tailscale

    #brew uninstall tailscale
    ;;
*)
    echo "[参数命令不合法]case: $Case [test]"
    exit 1
    ;;
esac
