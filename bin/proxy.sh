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

