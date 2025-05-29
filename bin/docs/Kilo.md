# kilo 集群部署指南

首先下载 

```bash
git clone git@github.com:squat/kilo.git
```

修改 `manifests/kilo-kubeadm.yaml` 新增 `--mesh-granularity=full` 参数改成全互联模式

```yaml
    containers:
    - name: kilo
    image: squat/kilo:0.6.0
    args:
    - --kubeconfig=/etc/kubernetes/kubeconfig
    - --hostname=$(NODE_NAME)
    - --mesh-granularity=full
```

部署 `kilo` 资源清单:

```bash
kubectl apply -f manifests/crds.yaml
kubectl apply -f manifests/kilo-kubeadm.yaml
```

给每台节点指定公网 `endpoint`:

```bash
kubectl annotate nodes server-1 kilo.squat.ai/force-endpoint=148.135.125.157
kubectl annotate nodes server-2 kilo.squat.ai/force-endpoint=142.171.26.116
kubectl annotate nodes server-3 kilo.squat.ai/force-endpoint=34.67.36.245
```

设置 `kilo.squat.ai/persistent-keepalive`

```bash
kubectl annotate node server-1 kilo.squat.ai/persistent-keepalive=25
kubectl annotate node server-2 kilo.squat.ai/persistent-keepalive=25
kubectl annotate node server-2 kilo.squat.ai/persistent-keepalive=25
```

分别指定 `location`:

```bash
kubectl annotate node server-1 kilo.squat.ai/location="ccs"
kubectl annotate node server-2 kilo.squat.ai/location="ccs"
kubectl annotate node server-3 kilo.squat.ai/location="gcp"
```

实际部署发现 `GCP` 服务器 `server-3` 的 `kilo.squat.ai/endpoint` 配置为内网 `eth0` IP: `10.128.0.2`，重置为公网 `IP`:

```bash
kubectl annotate nodes server-3 kilo.squat.ai/endpoint=34.67.36.245:51820 --overwrite=true
```

查看节点网卡 `kilo0`

```bash
$ ip -d link show kilo0
282: kilo0: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1420 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/none  promiscuity 0 minmtu 0 maxmtu 2147483552
    wireguard addrgenmode none numtxqueues 1 numrxqueues 1 gso_max_size 65536 gso_max_segs 65535
Sun Dec 10 18:11:58 root@server-1:~# wg show kilo
```

其中 `kilo0` 是 `WireGuard` 虚拟网络接口：

```bash
$ wg show kilo0
interface: kilo0
  public key: /Ias8Ndt7vkHqA/pb+/4vwLH2Qi0qn6ssMSvBclRHQg=
  private key: (hidden)
  listening port: 51820
```

### 查看网络拓扑图

```bash
go install github.com/squat/kilo/cmd/kgctl@latest
```

查看网络拓扑图

```bash
kgctl --kubeconfig=/Users/coam/.kube/config.cluster.local graph | circo -Tsvg > cluster.svg
```

## 其它

### 部署 `busybox` 测试

```bash
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: tools
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: tools
  template:
    metadata:
      labels:
        app: tools
    spec:
      containers:
      - name: busybox
        image: busybox
```

### 给每台节点指定内网 `ip`: - 暂定

```bash
kubectl annotate nodes server-3 kilo.squat.ai/force-internal-ip=10.128.0.2
```

其它命令

```bash
kubectl annotate nodes server-1 kilo.squat.ai/force-internal-ip=10.233.110.64/24
kubectl annotate nodes server-2 kilo.squat.ai/force-internal-ip=10.233.101.64/24
kubectl annotate nodes server-3 kilo.squat.ai/force-internal-ip=10.233.78.192/24
```

```bash
kubectl annotate nodes server-1 kilo.squat.ai/allowed-location-ips=10.233.110.64/24
kubectl annotate nodes server-2 kilo.squat.ai/allowed-location-ips=10.233.101.64/24
kubectl annotate nodes server-3 kilo.squat.ai/allowed-location-ips=10.233.78.192/24
```

```bash
kubectl annotate nodes server-1 kilo.squat.ai/internal-ip=10.233.110.64/32
kubectl annotate nodes server-3 kilo.squat.ai/internal-ip=10.233.78.192 --overwrite
```

## 参考文档

[WireGuard 系列文章（九）：基于 K3S+WireGuard+Kilo 搭建跨多云的统一 K8S 集群](https://ewhisper.cn/posts/21355/)
[Kilo 使用教程](https://icloudnative.io/posts/use-wireguard-as-kubernetes-cni/)
[Wireguard：新一代魔法上网工具](https://lqingcloud.cn/post/network-01/)