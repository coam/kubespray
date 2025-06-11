# k8s 集群部署指南

## 部署准备

### 1. 初始化配置

执行以下命令，初始化集群配置 `inventory/mycluster`

```bash
./bin/kubespray.sh reconfig
```

其它配置可根据实际情况调整

### 2. 配置部署节点

配置节点信息 `inventory/mycluster/hosts.yaml`，示例

```yaml
all:
  hosts:
    server-15:
      ansible_host: 10.100.0.105
      ip: 10.100.0.105
      access_ip: 10.100.0.105
    server-16:
      ansible_host: 10.100.0.106
      ip: 10.100.0.106
      access_ip: 10.100.0.106
    server-17:
      ansible_host: 10.100.0.107
      ip: 10.100.0.107
      access_ip: 10.100.0.107
  children:
    kube_control_plane:
      hosts:
        server-15:
        server-16:
    kube_node:
      hosts:
        server-15:
        server-16:
        server-17:
    etcd:
      hosts:
        server-16:
#    k8s_cluster:
#      children:
#        kube_control_plane:
#        kube_node:
#    calico_rr:
#      hosts: {}
```

注意: `server-*` 为对应节点的 `hostname`

各节点增加 `/etc/hosts` DNS 解析，对于上面，新增以下配置

```bash
10.100.0.105 server-15.cluster.local server-15
10.100.0.106 server-16.cluster.local server-16
10.100.0.107 server-17.cluster.local server-17
```

执行以下命令自动配置

```bash
./bin/cluster.sh config
```

* 默认覆盖配置 `inventory/mycluster/vars.yaml`，示例如下

```bash
metallb_protocol: "layer2"
```

## 部署 `k8s` 集群

### 1. 开始部署集群配置

开始部署 `k8s` 集群

```bash
./bin/cluster.sh deploy
```

### 2. 集群基础配置

* 安装 `OpenEBS` 存储，设置默认 `StorageClass` 为 `openebs-hostpath`

```bash
./bin/storage.sh init
./bin/storage.sh install
```

* 开启 `argocd` 服务为 `NodePort`

### 3. 下载 kubeconfig 集群配置文件到本机 - 本地(ansible) => [影响范围: 部署服务器]

下载到本机 `/Users/coam/.kube/config.cluster.local`,并且修改 `server` 地址，将 `127.0.0.1` 改为 `${DEPLOY_SERVER_1_IP}` 服务地址

```bash
./bin/cluster.sh down
```

本地连接集群测试

```bash
kubectl get nodes
```
