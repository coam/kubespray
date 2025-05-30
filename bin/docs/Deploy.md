# k8s 集群部署指南

## 部署准备

### 1. 初始化服务器环境 - 本地(ansible) => [影响范围: 所有服务器]

准备 `deploy.env` 服务器账号密码配置文件，执行以下命令初始化服务器环境，开启 `SSH` 访问配置

```bash
./bin/play.sh init
./bin/play.sh info
```

### 2. 在远程服务器初始化系统环境 - 本地(ansible) => [影响范围: 所有服务器]

* 系统设置设置时区
* 配置 `Swap` 交换分区
* 配置 `root` 和 `coam` 用户配置文件：

```bash
./bin/play.sh builder
```

### 3. 在远程服务器配置部署环境 - 远程(ansible) => [影响范围: 部署服务器]

> 可以在本地 `ansible` 项目执行，也可以同步 `deploy.env` 配置到远程服务器，在远程服务器执行 `prepare` 命令
> apt install -y sshpass

* 同步 `ansible`、`kubespray`、`runs`、`docs` 等 `git` 仓库项目
* 初始化 `kubespray` 部署的 `k8s` 集群配置

```bash
./bin/play.sh prepare
```

## 部署 `k8s` 集群

### 1. 开始部署集群配置 - 远程(ansible) => [影响范围: 所有服务器]

开始部署 `k8s` 集群

```bash
./bin/cluster.sh deploy
```

### 2. 集群基础配置 - 远程(ansible) => [影响范围: 所有服务器]

* 安装 `OpenEBS` 存储，设置默认 `StorageClass` 为 `openebs-hostpath`
* 开启 `argocd` 服务为 `NodePort`

```bash
./bin/cluster.sh config
```

### 3. 下载 kubeconfig 集群配置文件到本机 - 本地(ansible) => [影响范围: 部署服务器]

下载到本机 `/Users/coam/.kube/config.cluster.local`,并且修改 server 地址，将 `127.0.0.1` 改为 `${DEPLOY_SERVER_1_IP}` 服务地址

```bash
./bin/play.sh down
```

本地连接集群测试

```bash
kubectl get nodes
```

## 集群扩容

### 1. 更新本地加上新节点配置

在以下配置文件中加入新节点配置信息

* `deploy.env`
* `inventorys/kus.yaml`
* `plays/builder.yml`
* `plays/info.yml`
* `plays/prepare.yml`

### 2. 初始化新节点信息 - 本地(ansible) => [影响范围: 所有服务器]

```bash
./bin/play.sh init
./bin/play.sh info
./bin/play.sh builder
```

### 3. 初始化新节点配置信息 - 本地(ansible) => [影响范围: 部署服务器]

```bash
./bin/play.sh prepare
```

主要更新了部署节点配置文件 `/root/kubespray/inventory/mycluster`,以下为新增 `server-3` 节点配置

```bash
all:
  hosts:
    server-1:
      ansible_host: 148.135.125.157
      ip: 148.135.125.157
      access_ip: 148.135.125.157
    server-2:
      ansible_host: 142.171.26.116
      ip: 142.171.26.116
      access_ip: 142.171.26.116
    server-3:
      ansible_host: 34.67.36.245
      ip: 34.67.36.245
      access_ip: 34.67.36.245
  children:
    kube_control_plane:
      hosts:
        server-1:
    kube_node:
      hosts:
        server-1:
        server-2:
        server-3:
    etcd:
      hosts:
        server-1:
        server-2:
        server-3:
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
    calico_rr:
      hosts: {}
```

### 4. 执行加入新节点 - 远程(ansible) => [影响范围: 所有服务器]

执行以下命令扩容:

```bash
ansible-playbook -i inventory/mycluster/hosts.yaml -u root --become --become-user=root scale.yml --flush-cache
```

或者执行

```bash
./bin/cluster.sh scale
```

### 5. 移除节点 - 远程(ansible) => [影响范围: 所有服务器]

```bash
ansible-playbook -i inventory/mycluster/hosts.yaml -u root --become --become-user=root remove-node.yml -e node=server-3
```

或者执行

```bash
./bin/cluster.sh remove
```