#!/bin/bash

sc_dir="$(
  cd "$(dirname "$0")" >/dev/null 2>&1 || exit
  pwd -P
)"

rs_path=${sc_dir/runs*/runs}

# 张亚飞 ...
# [Tool] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

# [kubernetes] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

# 自动获取 sudo 权限
echo 'aajjffkk ' | sudo -S hostname

# [初始化] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

# nodes
echo "[🤖>>>]清除 nodes[t.cs.2] 部署清单"
ssh coam@2.tcs.iirii.com -p22312 bash -s <<EOF
echo 'aajjffkk ' | sudo -S hostname
sudo rm -rf /var/lib/rook
sudo rm -rf /etc/cni/net.d
sudo ipvsadm --clear
rm -rf $HOME/.kube
sudo kubeadm reset -f
sudo reboot
EOF

echo "[🤖>>>]清除 nodes[t.cs.3] 部署清单"
ssh coam@3.tcs.iirii.com -p22312 bash -s <<EOF
echo 'aajjffkk ' | sudo -S hostname
sudo rm -rf /var/lib/rook
sudo rm -rf /etc/cni/net.d
sudo ipvsadm --clear
rm -rf $HOME/.kube
sudo kubeadm reset -f
sudo reboot
EOF

# master
echo "[🤖>>>]清除 Rook 残留文件"
sudo rm -rf /var/lib/rook
sudo rm -rf /etc/cni/net.d
sudo ipvsadm --clear
rm -rf $HOME/.kube

echo "[🤖>>>]清除 master[t.cs.1] 部署清单"
sudo kubeadm reset -f
sudo reboot

# [Ended] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
