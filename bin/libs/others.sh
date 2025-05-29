#!/usr/bin/env bash
set -e

sc_dir=$(
  cd "$(dirname "${BASH_SOURCE[0]}")" || exit
  pwd -P
)

rs_path=${sc_dir/kubespray*/kubespray}
source $rs_path/bin/libs/headers.sh

function parse_iirii_server() {
    Server=$1

    [[ ! "$Server" =~ ^[^@]+@[^:]+:[0-9]+$ ]] && ebc_error "Server format error: $Server, 参数格式: <user>@<*>.iirii.com:<port>" && exit

    ssh_user=${Server%@*}
    ssh_server=${Server##*@}
    server_host=${ssh_server%:*}
    server_port=${ssh_server##*:}
    server_target=${server_host%".iirii.com"}

    [[ "$OSTYPE" == "linux-gnu"* ]] && server_path=$(echo "$server_target" | tr '.' '\n' | tac | paste -sd.)
    [[ "$OSTYPE" == "darwin"* ]]  && server_path=$(echo "$server_target" | tr '.' '\n' | tac | gpaste -s -d '.')

    ebc_debug "[Server: $Server] Extract ssh_user: $ssh_user, ssh_server: $ssh_server, server_host: $server_host, server_port: $server_port, server_target: $server_target, server_path: $server_path"

    local -n ref2=$2
    local -n ref3=$3
    local -n ref4=$4
    local -n ref5=$5
    local -n ref6=$6

    ref2=$ssh_user
    ref3=$server_host
    ref4=$server_port
    ref5=$server_target
    ref6=$server_path
}

# CentOS Packet Assets.
function rcs_packet_assert() {
  crs="$1" && ebc_debug "[系统安装检测($crs)]" && [ "$(yum list installed | grep -c "$crs")" != 1 ] && {
    yum list installed | grep "$crs"
    ebc_error "[软件包未安装($crs)]"
    exit 127
  }

  ebc_success "[软件包已安装($crs)]"
}

# Ubuntu Packet Assets.
function rus_packet_assert() {
  crs="$1" && ebc_debug "[系统安装检测($crs)]" && [ "$(dpkg -l | grep -c "$crs")" != 1 ] && {
    dpkg -l | grep "$crs"
    ebc_error "[软件包未安装($crs)]"
    exit 127
  }

  ebc_success "[软件包已安装($crs)]"
}

# Server Command Assets.
function rs_command_assert() {
  crs="$1" && ebc_debug "[系统安装检测($crs)]" && [ ! -x "$(command -v "$crs")" ] && {
    ebc_error "[软件包未安装($crs)]"
    exit 127
  }

  ebc_success "[软件包已安装($crs)]"
}

# [Docker-@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

# Docker System Cleaner
function docker_system_cleaner() {
  # Describe Docker System Info
  docker system df

  # Process Docker System Items
  docker system df --format '{{title .Size}}' | while read -r ds_row; do
    echo "Processing Docker System Row Size: $ds_row"

    # check row size
    [[ $ds_row != *"GB"* ]] && {
      echo "TooSmall: $ds_row,Skipping!"
      continue
    }

    # Get Docker System Size Number
    ds_size=$(echo $ds_row | grep -Eo '[+-]?[0-9]+([.][0-9]+)?')
    echo "[AssessDockerSystemSize][ds_row: $ds_row][ds_size: $ds_size]"
    if [ ${ds_size%.*} -ge 10 ]; then
      echo "[DockerSystemSizeTooLarge,Cleaning...][ds_size: $ds_size]"
      # Clearing Docker Data
      docker image prune -f -a
      break
    fi
  done
}

# [PushSvcMs-@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

# push_ms_token
push_ms_token="64e0cef81fdc027a60a34c2fc77aa774b2891f52b89f568d8fb93438f5c1061e"

# Push svc msg
function push_svc_ms() {
  # receive msg
  ns="$1"
  action="$2"
  rs_path="$3"
  branch="$4"
  env="$5"
  tag="$6"
  params="$7"

  echo "[推送参数][ns:$ns][action:$action][rs_path:$rs_path][branch:$branch][env:$env][tag:$tag][params:$params]"

  # 依赖 jq 软件
  rs_command_assert "jq" || sudo yum install -y jq

  # [Modify a key-value in a json using jq in-place](https://stackoverflow.com/questions/42716734/modify-a-key-value-in-a-json-using-jq-in-place)
  push="$(jq '.text.content = "[服务任务执行完成][ns:'$ns'][action:'$action'][rs_path:'$rs_path'][branch:'$branch'][env:'$env'][tag:'$tag'][host:'$(hostname)']"' $params)"

  # push msg
  curl 'https://oapi.dingtalk.com/robot/send?access_token='$push_ms_token -H 'Content-Type: application/json' -d "$push"
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
