## 部署 k8s 测试集群

下载部署工具

```bash
wget https://ghproxy.com/https://github.com/kubesphere/kubekey/releases/download/v3.0.13/kubekey-v3.0.13-linux-amd64.tar.gz
wget https://github.com/kubesphere/kubekey/releases/download/v3.0.13/kubekey-v3.0.13-linux-amd64.tar.gz
tar -zxvf kubekey-v3.0.13-linux-amd64.tar.gz
```

初始化集群环境

下载依赖包

* Ubuntu

```bash
sudo apt-get -y install socat conntrack ipset
```

* CentOS

```bash
sudo yum -y install socat conntrack ipset
```

或执行以下命令初始化系统

```bash
./kk init os
```

查看支持的版本

```bash
./kk version --show-supported-k8s
```

创建集群

我们这里指定了部署 `kubernetes` 和 `kubesphere` 的版本

```bash
export KKZONE=cn
./kk create cluster --with-kubernetes v1.27.2 --container-manager containerd --with-kubesphere 3.4.0
```

集群部署完后，可以执行以下命令根据集群信息生成该集群配置文件 `config-sample.yaml`

```bash
./kk create config --from-cluster -f config-sample.yaml
```

配置文件示例:

```bash
apiVersion: kubekey.kubesphere.io/v1alpha2
kind: Cluster
metadata:
  name: sample
spec:
  hosts:
  ##You should complete the ssh information of the hosts
  - {name: bjy-idc-bdata-k8s-test01, address: 10.16.30.69, internalAddress: 10.16.30.69}
  roleGroups:
    etcd:
    - SHOULD_BE_REPLACED
    master:
    - bjy-idc-bdata-k8s-test01
    worker:
    - bjy-idc-bdata-k8s-test01
  controlPlaneEndpoint:
    ##Internal loadbalancer for apiservers
    #internalLoadbalancer: haproxy

    ##If the external loadbalancer was used, 'address' should be set to loadbalancer's ip.
    domain: lb.kubesphere.local
    address: ""
    port: 6443
  kubernetes:
    version: v1.23.10
    clusterName: cluster.local
    proxyMode: ipvs
    masqueradeAll: false
    maxPods: 110
    nodeCidrMaskSize: 24
  network:
    plugin: calico
    kubePodsCIDR: 10.233.64.0/18
    kubeServiceCIDR: 10.233.0.0/18
  registry:
    privateRegistry: ""
```

需要手动配置以下信息

```bash
spec:
  roleGroups:
    etcd:
    - bjy-idc-bdata-k8s-test01
```

## 加入新节点

以加入新节点 `bjy-idc-bdata-k8s-test04` 为例，新节点配置信息为：

```bash
hostname: bjy-idc-bdata-k8s-test04
ip: 10.16.30.118
```

### 1. 授权主节点通过 `ssh` 访问登录新节点

将 `bjy-idc-bdata-k8s-test01` 主节点的 `root` 用户 `ssh` 公钥加入到新节点 `bjy-idc-bdata-k8s-test04` 的 `/root/.ssh/authorized_keys` 中。
然后在 `bjy-idc-bdata-k8s-test01` 上执行 `ssh root@10.16.30.118` 验证登录是否成功。


### 2. 在新节点安装依赖工具

```bash
sudo yum -y install socat conntrack ipset
```

### 3. 配置新节点信息

在集群配置 `config-sample.yaml` 里加上新节点的信息

```bash
apiVersion: kubekey.kubesphere.io/v1alpha2
kind: Cluster
metadata:
  name: sample
spec:
  hosts:
  ##You should complete the ssh information of the hosts
  - {name: bjy-idc-bdata-k8s-test01, address: 10.16.30.69, internalAddress: 10.16.30.69}
  - {name: bjy-idc-bdata-k8s-test04, address: 10.16.30.118, internalAddress: 10.16.30.118}
  roleGroups:
    etcd:
    - bjy-idc-bdata-k8s-test01
    master:
    - bjy-idc-bdata-k8s-test01
    worker:
    - bjy-idc-bdata-k8s-test01
    - bjy-idc-bdata-k8s-test04
```

然后执行以下命令加入节点

```bash
export KKZONE=cn
./kk add nodes -f config-sample.yaml
```

## 移除节点

```bash
./kk delete node bjy-idc-bdata-k8s-test04 -f config-sample.yaml
```

## 删除集群

```bash
./kk delete cluster
```

********************************************************************************************************************************************************************************************************

## 常见问题

### 部署 k8s v1.24 以上版本

使用 `kk` 执行以下命令部署 `k8s` 指定 `cri` 为 `containerd` 时出错

```bash
./kk create cluster --with-kubernetes v1.27.2 --container-manager containerd --with-kubesphere 3.4.0
```

报错信息

```bash
pull image failed: Failed to exec command: sudo -E /bin/bash -c "env PATH=$PATH crictl pull registry.cn-beijing.aliyuncs.com/kubesphereio/pause:3.8 --platform amd64"
WARN[0001] image connect using default endpoints: [unix:///var/run/dockershim.sock unix:///run/containerd/containerd.sock unix:///run/crio/crio.sock unix:///var/run/cri-dockerd.sock]. As the default settings are now deprecated, you should set the endpoint instead.
ERRO[0001] unable to determine image API version: rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing dial unix /var/run/dockershim.sock: connect: connection refused"
E1110 11:14:32.031699   27107 remote_image.go:218] "PullImage from image service failed" err="rpc error: code = Unimplemented desc = unknown service runtime.v1alpha2.ImageService" image="registry.cn-beijing.aliyuncs.com/kubesphereio/pause:3.8"
FATA[0001] pulling image: rpc error: code = Unimplemented desc = unknown service runtime.v1alpha2.ImageService: Process exited with status 1
```

看错误提示没有配置 `endpoint`

```bash
WARN[0001] image connect using default endpoints: [unix:///var/run/dockershim.sock unix:///run/containerd/containerd.sock unix:///run/crio/crio.sock unix:///var/run/cri-dockerd.sock]. As the default settings are now deprecated, you should set the endpoint instead.
```

由于新版的 `k8s` 集群使用 `crictl` 管理容器镜像。

查看配置文件 `cat /etc/crictl.yaml`

```bash
$ cat /etc/crictl.yaml
runtime-endpoint: ""
image-endpoint: ""
timeout: 0
debug: false
pull-image-on-create: false
disable-pull-on-run: false
```

发现没有配置 `runtime-endpoint` 和 `image-endpoint`。改为以下配置

```bash
$ cat /etc/crictl.yaml
runtime-endpoint: "unix:///run/containerd/containerd.sock"
image-endpoint: "unix:///run/containerd/containerd.sock"
timeout: 0
debug: false
pull-image-on-create: false
disable-pull-on-run: false
```

### unknown service runtime.v1.RuntimeService

使用 `kk` 命令

```bash
./kk create cluster --with-kubernetes v1.25.3 --container-manager containerd --with-kubesphere 3.4.0
```

或执行以下命令同样报错

```bash
# crictl info
DEBU[0000] get runtime connection
FATA[0000] validate service connection: validate CRI v1 runtime API for endpoint "unix:///run/containerd/containerd.sock": rpc error: code = Unimplemented desc = unknown service runtime.v1.RuntimeService
```

删除 `/etc/containerd/config.toml` 配置并重启 `containerd` 服务即可

```bash
rm /etc/containerd/config.toml
systemctl restart containerd
```

[pull image failed: Failed to exec command](https://github.com/kubesphere/kubekey/issues/1876)

********************************************************************************************************************************************************************************************************

### CNI 网络插件部署失败

加入节点启动后新节点 `kubelet` 服务一直报错

```bash
Unable to create token for CNI kubeconfig error=Post "https://10.233.0.1:443/api/v1/namespaces/kube-system/serviceaccounts/calico-node/token": x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "kubernetes")
```

查看服务容器

```bash
# docker ps -a
CONTAINER ID   IMAGE                                                     COMMAND                  CREATED              STATUS                          PORTS     NAMES
d176d6b39f73   a87d3f6f1b8f                                              "/opt/cni/bin/install"   About a minute ago   Exited (1) About a minute ago             k8s_install-cni_calico-node-wxrbh_kube-system_55b60811-fc3b-496a-9903-b07e0be6341a_4
af4f5186f595   29589495df8d                                              "/usr/local/bin/kube…"   5 minutes ago        Up 5 minutes                              k8s_kube-rbac-proxy_node-exporter-mpn7z_kubesphere-monitoring-system_3b5a2997-a160-4643-8731-6e991e048a02_0
620908ecb0e0   1dbe0e931976                                              "/bin/node_exporter …"   5 minutes ago        Up 5 minutes                              k8s_node-exporter_node-exporter-mpn7z_kubesphere-monitoring-system_3b5a2997-a160-4643-8731-6e991e048a02_0
aed84906a427   ca6176be9738                                              "/home/weave/scope -…"   5 minutes ago        Up 5 minutes                              k8s_scope-agent_weave-scope-agent-pkmbg_weave_15e5e0d3-0d82-4030-a878-c67ce9479559_0
ca4f535187e0   a87d3f6f1b8f                                              "/opt/cni/bin/calico…"   5 minutes ago        Exited (0) 5 minutes ago                  k8s_upgrade-ipam_calico-node-wxrbh_kube-system_55b60811-fc3b-496a-9903-b07e0be6341a_0
9465f681315a   71b9bf9750e1                                              "/usr/local/bin/kube…"   5 minutes ago        Up 5 minutes                              k8s_kube-proxy_kube-proxy-67jhc_kube-system_03e99b5b-55f6-4106-a002-909c7c0be9bb_0
bc6cee3b766e   5340ba194ec9                                              "/node-cache -locali…"   5 minutes ago        Up 5 minutes                              k8s_node-cache_nodelocaldns-clhdf_kube-system_a6b9d561-d676-41c7-94f8-0dd04bbd33ea_0
0666bd9174be   registry.cn-beijing.aliyuncs.com/kubesphereio/pause:3.6   "/pause"                 5 minutes ago        Up 5 minutes                              k8s_POD_nodelocaldns-clhdf_kube-system_a6b9d561-d676-41c7-94f8-0dd04bbd33ea_0
d475188e020f   registry.cn-beijing.aliyuncs.com/kubesphereio/pause:3.6   "/pause"                 5 minutes ago        Up 5 minutes                              k8s_POD_kube-proxy-67jhc_kube-system_03e99b5b-55f6-4106-a002-909c7c0be9bb_0
f490b105a2ef   registry.cn-beijing.aliyuncs.com/kubesphereio/pause:3.6   "/pause"                 5 minutes ago        Up 5 minutes                              k8s_POD_calico-node-wxrbh_kube-system_55b60811-fc3b-496a-9903-b07e0be6341a_0
66cf50d42fa7   registry.cn-beijing.aliyuncs.com/kubesphereio/pause:3.6   "/pause"                 5 minutes ago        Up 5 minutes                              k8s_POD_node-exporter-mpn7z_kubesphere-monitoring-system_3b5a2997-a160-4643-8731-6e991e048a02_0
2dd813088ad0   registry.cn-beijing.aliyuncs.com/kubesphereio/pause:3.6   "/pause"                 5 minutes ago        Up 5 minutes                              k8s_POD_weave-scope-agent-pkmbg_weave_15e5e0d3-0d82-4030-a878-c67ce9479559_0
```

其中有个 `k8s_install-cni_calico-node` 的容器退出了，列出容器日志：

```bash
2023-10-31 09:54:34.339 [INFO][1] cni-installer/<nil> <nil>: CNI plugin version: v3.23.2

2023-10-31 09:54:34.339 [INFO][1] cni-installer/<nil> <nil>: /host/secondary-bin-dir is not writeable, skipping
W1031 09:54:34.339493       1 client_config.go:617] Neither --kubeconfig nor --master was specified.  Using the inClusterConfig.  This might not work.
2023-10-31 09:54:34.346 [ERROR][1] cni-installer/<nil> <nil>: Unable to create token for CNI kubeconfig error=Post "https://10.233.0.1:443/api/v1/namespaces/kube-system/serviceaccounts/calico-node/token": x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "kubernetes")
2023-10-31 09:54:34.346 [FATAL][1] cni-installer/<nil> <nil>: Unable to create token for CNI kubeconfig error=Post "https://10.233.0.1:443/api/v1/namespaces/kube-system/serviceaccounts/calico-node/token": x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "kubernetes")
```

搜索大量文章大部分都说是 `.kube/config` 证书问题，检查了没看出证书有啥问题

```bash
certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "kubernetes")
```

其中 `10.233.0.1` 是 k8s api 服务地址,查看 `kube-proxy` 容器日志

```bash
# docker logs -f 9465f681315a
E1101 07:47:21.369213       1 reflector.go:138] k8s.io/client-go/informers/factory.go:134: Failed to watch *v1.EndpointSlice: failed to list *v1.EndpointSlice: Get "https://127.0.0.1:6443/apis/discovery.k8s.io/v1/endpointslices?labelSelector=%21service.kubernetes.io%2Fheadless%2C%21service.kubernetes.io%2Fservice-proxy-name&limit=500&resourceVersion=0": dial tcp 127.0.0.1:6443: connect: connection refused
W1101 07:47:54.277921       1 reflector.go:324] k8s.io/client-go/informers/factory.go:134: failed to list *v1.Service: Get "https://127.0.0.1:6443/api/v1/services?labelSelector=%21service.kubernetes.io%2Fheadless%2C%21service.kubernetes.io%2Fservice-proxy-name&limit=500&resourceVersion=0": dial tcp 127.0.0.1:6443: connect: connection refused
```

发现大量报错日志

```bash
E1101 07:44:36.677293       1 node.go:152] Failed to retrieve node info: Get "https://127.0.0.1:6443/api/v1/nodes/bjy-idc-bdata-k8s-test04": dial tcp 127.0.0.1:6443: connect: connection refused
E1101 07:44:37.769562       1 node.go:152] Failed to retrieve node info: Get "https://127.0.0.1:6443/api/v1/nodes/bjy-idc-bdata-k8s-test04": dial tcp 127.0.0.1:6443: connect: connection refused
E1101 07:44:39.817638       1 node.go:152] Failed to retrieve node info: Get "https://127.0.0.1:6443/api/v1/nodes/bjy-idc-bdata-k8s-test04": dial tcp 127.0.0.1:6443: connect: connection refused
E1101 07:44:44.084105       1 node.go:152] Failed to retrieve node info: Get "https://127.0.0.1:6443/api/v1/nodes/bjy-idc-bdata-k8s-test04": dial tcp 127.0.0.1:6443: connect: connection refused
E1101 07:44:52.909097       1 node.go:152] Failed to retrieve node info: Get "https://127.0.0.1:6443/api/v1/nodes/bjy-idc-bdata-k8s-test04": dial tcp 127.0.0.1:6443: connect: connection refused
E1101 07:45:11.124028       1 node.go:152] Failed to retrieve node info: Get "https://127.0.0.1:6443/api/v1/nodes/bjy-idc-bdata-k8s-test04": dial tcp 127.0.0.1:6443: connect: connection refused
I1101 07:45:11.124136       1 server.go:843] "Can't determine this node's IP, assuming 127.0.0.1; if this is incorrect, please set the --bind-address flag"
I1101 07:45:11.124159       1 server_others.go:138] "Detected node IP" address="127.0.0.1"
I1101 07:45:11.447948       1 server_others.go:269] "Using ipvs Proxier"
```

其中 `127.0.0.1:6443` 连接失败，查询已部署的 `bjy-idc-bdata-k8s-test03` 节点监听的 `6443` 端口

```bash
# netstat -antup | grep 6443
tcp        0      0 127.0.0.1:6443          0.0.0.0:*               LISTEN      23931/haproxy
tcp        0      0 10.16.16.49:34526       10.16.30.69:6443        ESTABLISHED 23931/haproxy
tcp        0      0 127.0.0.1:25578         127.0.0.1:6443          ESTABLISHED 866/kubelet
tcp        0      0 127.0.0.1:6443          127.0.0.1:4468          ESTABLISHED 23931/haproxy
tcp        0      0 127.0.0.1:4468          127.0.0.1:6443          ESTABLISHED 4357/kube-proxy
tcp        0      0 127.0.0.1:6443          127.0.0.1:25578         ESTABLISHED 23931/haproxy
tcp        0      0 10.16.16.49:13418       10.16.30.69:6443        ESTABLISHED 23931/haproxy
```

发现是由一个 `haproxy` 的进程监听的，检索 `bjy-idc-bdata-k8s-test03` 节点 `docker` 容器发现都运行着一个 `k8s_haproxy_haproxy` 容器。

```bash
# docker ps -a | grep haproxy
880e7327cd76   registry.cn-beijing.aliyuncs.com/kubesphereio/haproxy               "docker-entrypoint.s…"    23 minutes ago   Up 23 minutes                         k8s_haproxy_haproxy-bjy-idc-bdata-k8s-test03_kube-system_64151c744b532c59ccdd36cd9ff55f3d_0
18d330d14b38   registry.cn-beijing.aliyuncs.com/kubesphereio/pause:3.6             "/pause"                  23 minutes ago   Up 23 minutes                         k8s_POD_haproxy-bjy-idc-bdata-k8s-test03_kube-system_64151c744b532c59ccdd36cd9ff55f3d_0
```

在部署节点 `bjy-idc-bdata-k8s-test03` `kk` 命令所在目录(`/root/kubekey/`)下有各节点的部署配置，对比发现  `bjy-idc-bdata-k8s-test04` 少了两个 `haproxy.cfg` 和 `haproxy.yaml` 配置文件

*  `bjy-idc-bdata-k8s-test03`

```bash
10-kubeadm.conf  haproxy.cfg  haproxy.yaml  initOS.sh  kubeadm-config.yaml  kubelet.service
```

*  `bjy-idc-bdata-k8s-test04`

```bash
10-kubeadm.conf  initOS.sh  kubeadm-config.yaml  kubelet.service
```

原因找到了,是由于 `bjy-idc-bdata-k8s-test04` 没有开启 `haproxy` 配置

查看我们上一步生成的集群配置文件 `config-sample.yaml` 发现有一行 `haproxy` 配置被注释了。

```bash
spec:
  hosts:
  ##You should complete the ssh information of the hosts
  - {name: bjy-idc-bdata-k8s-test01, address: 10.16.30.69, internalAddress: 10.16.30.69}
  - {name: bjy-idc-bdata-k8s-test02, address: 10.16.30.68, internalAddress: 10.16.30.68}
  - {name: bjy-idc-bdata-k8s-test03, address: 10.16.16.49, internalAddress: 10.16.16.49}
  - {name: bjy-idc-bdata-k8s-test04, address: 10.16.30.118, internalAddress: 10.16.30.118}
  roleGroups:
    etcd:
    - bjy-idc-bdata-k8s-test01
    master:
    - bjy-idc-bdata-k8s-test01
    worker:
    - bjy-idc-bdata-k8s-test01
    - bjy-idc-bdata-k8s-test02
    - bjy-idc-bdata-k8s-test03
    - bjy-idc-bdata-k8s-test04
  controlPlaneEndpoint:
    ##Internal loadbalancer for apiservers
    #internalLoadbalancer: haproxy
```

我们取消注释后重新加入节点成功。

### sanbox DNS 解析配置文件

节点加入后刚启动后报错

```bash
Jan 06 10:47:59 worker1 kubelet[25457]: E0106 10:47:59.156740 25457 pod_workers.go:190] “Error syncing pod, skipping” err="failed to \“CreatePodSandbox\” for \“cilium-9wdrw_kube-system(b30c66a8-2b55-4eae-b46f-7d3ca1c0fae1)\” with CreateJan 06 10:47:59 worker1 kubelet[25457]: E0106 10:47:59.156492 25457 kuberuntime_manager.go:790] “CreatePodSandbox for pod failed” err=“open /run/systemd/resolve/resolv.conf: no such file or directory” pod=“kube-system/cilium-9wdrw”
```

在 `kubelet` 启动一个 `pod` 前，需要为该 `pod` 创建一个合适的运行环境，该运行环境被称为 `sanbox`。 在 `sandbox` 的多项配置中，包含了需要从宿主机节点继承的一部分 `dns` 配置。
此时，`kubelet`需要读取宿主机的`DNS`配置文件，将其中的配置写入`pod sandbox`中。

至于宿主机的`DNS`配置文件是由`kubelet`的配置文件声明的，该文件默认位于`/var/lib/kubelet/config.yaml`下，配置项名为`resolvConf`，可通过

```bash
cat /var/lib/kubelet/config.yaml | grep resolvConf
```

执行以下命令启动 `systemd-resolved` 服务会自动创建 `/run/systemd/resolve/resolv.conf` 解析配置

```bash
apt install -y systemd-resolved
systemctl status systemd-resolved
systemctl start systemd-resolved
```

* [v3.2.1安装不了，需要手工拷贝master的/run/systemd/resolv.conf到worker节点，才可以安装成功](https://ask.kubesphere.io/forum/d/6474-v321masterrunsystemdresolvconfworker)

********************************************************************************************************************************************************************************************************

## 总结

本文档介绍了 `kubekey` 部署工具的使用方式，演示了如何从0开始部署一个 `k8s` 集群，并记录了常见的扩缩容问题，对以后更好的管理和维护 `k8s` 集群提供帮助。

## 参考

* [Known errors and solutions](https://www.devops.buzz/public/kubeadm/known-errors-and-solutions)
* [Unable to connect to the server: x509: certificate signed by unknown authority0.0](https://github.com/kubesphere/kubekey/issues/1349)
* [certificate signed by unknown authority](https://www.cnblogs.com/lfl17718347843/p/14122407.html)
* [Calico: networkPlugin cni failed to set up pod, i/o timeout](https://stackoverflow.com/questions/59936706/calico-networkplugin-cni-failed-to-set-up-pod-i-o-timeout)



