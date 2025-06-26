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
    #login_server=http://w.gpuez.com:58080
    login_server=https://w.gpuez.com:58080
    server_name=mac-client

    caller tailscale login --auth-key 2e7af75a7514700fddd51b8f47bf6498190b28f786d5c31c --login-server $login_server --hostname $server_name
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
