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
reconfig)
    #wget --output-document=bin/conf/headscale/config.yaml https://raw.githubusercontent.com/juanfont/headscale/refs/tags/v0.26.1/config-example.yaml
    #wget --output-document=bin/conf/headscale/config.yaml https://raw.staticdn.net/juanfont/headscale/refs/tags/v0.26.1/config-example.yaml
    #wget --output-document=bin/conf/headscale/config.yaml https://raw.fastgit.org/juanfont/headscale/refs/tags/v0.26.1/config-example.yaml
    wget --output-document=bin/conf/headscale/config.yaml https://raw.gitmirror.com/juanfont/headscale/refs/tags/v0.26.1/config-example.yaml

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
        caller yq -i '.server_url = "https://w.gpuez.com:58080"' bin/conf/headscale/config.yaml
        caller yq -i '.listen_addr = "0.0.0.0:58080"' bin/conf/headscale/config.yaml
        caller yq -i '.metrics_listen_addr = "127.0.0.1:59090"' bin/conf/headscale/config.yaml
        caller yq -i '.grpc_listen_addr = "127.0.0.1:50443"' bin/conf/headscale/config.yaml
        caller yq -i '.grpc_allow_insecure = true' bin/conf/headscale/config.yaml

        #caller yq -i '.acme_email = "zyf@iirii.com"' bin/conf/headscale/config.yaml
        #caller yq -i '.tls_letsencrypt_hostname = "2.cos.iirii.com"' bin/conf/headscale/config.yaml
        caller yq -i '.log.level = "debug"' bin/conf/headscale/config.yaml

        caller yq -i '.tls_cert_path = "/usr/local/openresty/nginx/conf/ssl/gpuez.com/fullchain1.pem"' bin/conf/headscale/config.yaml
        caller yq -i '.tls_key_path = "/usr/local/openresty/nginx/conf/ssl/gpuez.com/privkey1.pem"' bin/conf/headscale/config.yaml

        caller yq -i '.derp.server.enabled = true' bin/conf/headscale/config.yaml
        caller yq -i '.derp.server.ipv4 = "182.92.160.148"' bin/conf/headscale/config.yaml
        #caller yq -i '.derp.server.private_key_path = "/usr/local/openresty/nginx/conf/ssl/gpuez.com/privkey1.pem"' bin/conf/headscale/config.yaml
        #caller yq -i '.derp.server.ipv6 = ""' bin/conf/headscale/config.yaml
        caller yq -i eval 'del(.derp.server.ipv6)' bin/conf/headscale/config.yaml

        caller yq -i '.logtail.enabled = true' bin/conf/headscale/config.yaml
    }
    ;;
deploy)
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

        caller ssh -o StrictHostKeyChecking=no $ssh_user@$server_host -p $server_port 'systemctl enable --now headscale && systemctl restart headscale && systemctl status headscale'
    done
    ;;
logs)
    servers=()
#    servers+=("root@2.cos.iirii.com:22")
    servers+=("root@0.gw.zsc.iirii.com:22")
    for server in "${servers[@]}"; do
        parse_iirii_server $server ssh_user server_host server_port server_target server_path

        caller ssh -o StrictHostKeyChecking=no $ssh_user@$server_host -p $server_port 'journalctl -u headscale -f'
    done
    ;;
users)
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
status)
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
tests)
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
clean)
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
*)
    echo "[参数命令不合法]case: $Case [test]"
    exit 1
    ;;
esac
