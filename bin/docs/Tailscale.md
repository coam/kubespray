# 使用headscale + tailscale 搭建内网集群

### 节点说明：

**headscale节点(服务端)：**

    IP:  101.32.109.58  (公网)

    服务端口：8080

**tailscale节点(客户端)：**

    节点1：10.100.0.99

    节点2：10.100.0.112

    节点3：10.100.0.113


### 下载并安装并运行headscale

```bash
wget  https://dist.gpuez.com/headscale.tar.gz
tar -xvf headscale.tar.gz
mv headscale /usr/bin/
chmod 777 /usr/bin/headscale

mkdir -p /etc/headscale
mv config.yaml /etc/headscale

/usr/bin/headscale serve  #启动headscale

headscale users create lyric  #创建用户
headscale users list  # 查看用户ID
headscale preauthkeys create --user 1 -reusable  # 生成客户端认证的KEY ， 1是用户ID
```
拿到 key 后，后续客户端用它来认证


### 安装tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

### 连接headscale组网

节点1：
```bash
tailscale login --auth-key 91f34c512fc610900f3a106a544702fe2da88edd928ac177 --login-server http://101.32.109.58:8080 --hostname lyric-111
```
节点2：
```bash
tailscale login --auth-key 91f34c512fc610900f3a106a544702fe2da88edd928ac177 --login-server http://101.32.109.58:8080 --hostname lyric-112
```
节点3：
```bash
tailscale login --auth-key 91f34c512fc610900f3a106a544702fe2da88edd928ac177 --login-server http://101.32.109.58:8080 --hostname lyric-113
```

### tailscale常用命令

| 命令 | 说明                      |
|----------|-------------------------------|
|tailscale up     | 启动连接，首次会要求登录         |
|tailscale down    | 断开 Tailscale 连接   |
|tailscale ip    | 查看分配的 Tailscale IP                     |
|tailscale status   | 查看当前连接状态及其他节点         |
|systemctl status tailscaled   | 查看服务状态         |
|headscale nodes delete -i 3 --force   | 强制删除节点ID为3的节点        |
