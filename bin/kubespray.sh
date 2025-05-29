#!/usr/bin/env bash
set -xe

sc_dir="$(
  cd "$(dirname "$0")" >/dev/null 2>&1 || exit
  pwd -P
)"

rs_path=${sc_dir/kubespray*/kubespray}
source $rs_path/bin/libs/headers.sh

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
init)
  caller apt install python3-pip
  ;;
codes)
  caller git fetch --tags origin
  caller git checkout rebuild
  caller git merge $(git describe --tags $(git rev-list --tags --max-count=1))
  # git checkout tags/v2.28.0

  caller pip3 install -r requirements.txt
  ;;
reconfig)
  #caller rm -rf inventory/mycluster
  #caller cp -rfp inventory/sample inventory/mycluster
  #caller rsync -H -avP --delete --exclude=conf/{cros_headers.conf,log_format.conf,proxy_headers.conf,ssl/,luafile/} --filter='protect conf/ssl' inventory/sample inventory/mycluster
  caller rsync -H -avP --delete --filter='P hosts.yaml' inventory/sample/. inventory/mycluster
#  python3 contrib/inventory_builder/inventory.py {{ lookup('ansible.builtin.env', 'DEPLOY_SERVERS') | split(',') | join(' ') }}
  ;;
*)
  echo "[参数命令不合法]case: $Case [test,cluster,k8s,kubesphere,other]"
  exit 1
  ;;
esac

