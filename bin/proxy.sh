#!/usr/bin/env bash
set -xe

sc_dir="$(
    cd "$(dirname "$0")" >/dev/null 2>&1 || exit
    pwd -P
)"

rs_path=${sc_dir/kubespray*/kubespray}
source $rs_path/bin/libs/headers.sh

Case=${1:-"test"}

ebc_debug "解析命令参数> proxy.sh $Case"

case "$Case" in
help)
    ebc_debug "说明: proxy.sh 命令快捷参数"
    ebc_debug "用法: proxy.sh <Case>"
    ebc_debug "示例: proxy.sh issue"
    ;;
test)
    echo "nothing to do: take it easy..."
    ;;
config)
    # 使用 kubespray 安装部署了 k8s 集群后，默认会在以下地方设置代理配置
    cat /etc/apt/apt.conf
    cat /etc/systemd/system/containerd.service.d/http-proxy.conf
    ;;
reconfig)
    grep -r "chess" /etc
    grep -r "zyfa" /etc > /tmp/proxy.log
    #grep -r "zyfa" /usr/local/etc >> /tmp/proxy.log
    cat /tmp/proxy.log

    sed -i "s/http:\/\/zyfa:112233@0.wh.zsc.iirii.com:8810/http:\/\/chess:ceaqaz000@proxy.zsc.iirii.com:7890/g" /etc/systemd/system/containerd.service.d/http-proxy.conf
    sed -i "s/http:\/\/zyfa:112233@0.wh.zsc.iirii.com:8810/http:\/\/chess:ceaqaz000@proxy.zsc.iirii.com:7890/g" /etc/kubernetes/addons/cert_manager/cert-manager.yml
    sed -i "s/http:\/\/zyfa:112233@0.wh.zsc.iirii.com:8810/http:\/\/chess:ceaqaz000@proxy.zsc.iirii.com:7890/g" /etc/apt/apt.conf

    # 执行以下步骤验证是否生效
    systemctl daemon-reload

    systemctl restart kubelet
    systemctl status kubelet

    systemctl restart containerd
    systemctl status containerd

    # 检查 kubelet 服务配置
    sudo systemctl show kubelet --property Environment

    # 如果有旧代理设置，编辑 kubelet 服务文件
    sudo systemctl edit kubelet
    #[Service]
    #Environment="HTTP_PROXY=http://新代理地址:端口"
    #Environment="HTTPS_PROXY=http://新代理地址:端口"
    #Environment="NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.0.0/16,pod的CIDR,service的CIDR"

    # 检查运行时配置

    # 对于 containerd
    sudo cat /etc/containerd/config.toml | grep proxy
    # 对于 docker
    #sudo cat /etc/systemd/system/docker.service.d/http-proxy.conf

    # 验证代理配置是否生效

    # 查看 containerd 的环境变量
    sudo cat /proc/$(pidof containerd)/environ | tr '\0' '\n' | grep -i proxy
    # 查看 kubelet 的环境变量
    #sudo cat /proc/$(pidof kubelet)/environ | tr '\0' '\n' | grep -i proxy
    ;;
clear)
    # [Kubernetes(四)kubespray方式(4.4)清理代理设置](https://blog.llyweb.com/articles/2022/11/01/1667293708554.html)

    rm -f /etc/systemd/system/containerd.service.d/http-proxy.conf
    systemctl daemon-reload
    systemctl restart containerd

    # Ubuntu: apt
    # CentOS: yum
    # todo: ...
    ;;
*)
    echo "[参数命令不合法]case: $Case [test,cluster,k8s,kubesphere,other]"
    exit 1
    ;;
esac
