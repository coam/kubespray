# 网络问题

在 `10.100.0.105` 上无法 `ping` 通 `10.100.0.106`

##

# 检查 `IP` 和掩码配置

```bash
ip addr show ens160
```

# 检查路由表

```bash
ip route show
```

# 查看 `iptables` 规则

```bash
iptables -L -n -v
```

# 查看 `nftables` 规则（如果使用）

```bash
nft list ruleset
```

# 检查 `MTU` 设置

```bash
ip link show ens160 | grep mtu
```

# 检查 `ARP` 相关内核参数

```bash
sysctl -a | grep arp
```

如果发现是内核 `ARP` 参数问题：

修改 `ARP` 相关参数

```bash
#sysctl -w net.ipv4.conf.all.arp_ignore=1
sysctl -w net.ipv4.conf.ens160.arp_filter=0
sysctl -w net.ipv4.conf.ens160.arp_ignore=0
```

## `tcpdump` 命令详解

```bash
tcpdump -i ens160 -nn 'icmp or arp'
```

```bash
tcpdump -i ens160 -w problem.pcap
```

# 检查网卡状态和错误计数

```bash
ethtool ens160
ethtool -S ens160 | grep error
```

# 设置接口为全双工

```bash
ethtool -s ens160 duplex full
```

# 检查出站ARP包是否真的发出，在105节点执行：

```bash
tcpdump -i ens160 -nn -X 'arp and src host 10.100.0.105'
```

# 检查是否收到入站 `ARP` 包，在 `106` 节点执行：

```bash
tcpdump -i ens160 -nn -X 'arp and dst host 10.100.0.106'
```

## 临时解决方案

```bash
arp -e
Address                  HWtype  HWaddress           Flags Mask            Iface
monitor.wh.aohoo.cn      ether   00:0c:29:12:be:c1   C                     ens160
cloud.wh.aohoo.cn        ether   00:0c:29:84:64:bf   C                     ens160
server-16.cluster.local          (incomplete)                              ens160
_gateway                 ether   00:e2:69:35:06:31   C                     ens160
server-17.cluster.local          (incomplete)                              ens160
proxy.zsc.iirii.com      ether   00:0c:29:cb:8f:69   C                     ens160
10.100.0.113             ether   00:0c:29:a0:7d:35   C                     ens160
server-18.cluster.local  ether   00:0c:29:31:d7:c3   C                     ens160
```

在 `105` 机器上执行

```bash
arp -s 10.100.0.106 00:0c:29:de:7a:fc
arp -s 10.100.0.107 00:0c:29:ab:6f:dd
```

强制刷新 `ARP` 缓存：

# 清除 ARP 缓存

```bash
ip neigh flush dev ens160
```

或

```bash
arp -d 10.100.0.106
arp -d 10.100.0.107
```

检查网络接口状态：

# 重启网络接口

```bash
ip link set ens160 down
ip link set ens160 up
```

或

```bash
ifdown ens160 && ifup ens160
```