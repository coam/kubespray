# Kubernetes 容器编排管理平台

[Kubernetes指南](https://kubernetes.feisky.xyz/)
[Kubernetes中文文档](http://hardocs.com/d/kubernetes/index.html)

* 参考博客文章

[Kubernetes 学习笔记](https://wdxtub.com/2017/06/05/k8s-note/)
[Kubernetes 问题定位技巧：分析 ExitCode](https://imroc.io/posts/kubernetes/analysis-exitcode/)
[Docker 和 Kubernetes 从听过到略懂：给程序员的旋风教程](https://1byte.io/developer-guide-to-docker-and-kubernetes/)
[Kubernetes 的最佳实践](https://kuops.com/2018/09/12/Kubernetes-%E6%9C%80%E4%BD%B3%E5%AE%9E%E8%B7%B5/#%E4%BF%9D%E6%8C%81%E5%9F%BA%E7%A1%80%E9%95%9C%E5%83%8F%E6%9C%80%E5%B0%8F%E5%8C%96)
[深入理解K8s资源限制](https://qingwave.github.io/2019/01/09/深入理解K8s资源限制)

* Kubernetes 国内镜像翻墙解决方案

[基于Docker的Kubernetes-1.12集群搭建](https://bluesmilery.github.io/blogs/243abda1/)

********************************************************************************************************************************************************************************************************

# Kubernetes 管理

[kubernetes - 中文文档](http://docs.kubernetes.org.cn/)
[kubernetes从入门到放弃](https://jiayi.space/?status=loaded)
[kubernetes 学习笔记](https://www.pyfdtic.com/2018/07/15/k8s-kubernetes-learn-note/)

* 参考博客文章

[Docker 和 Kubernetes 从听过到略懂:给程序员的旋风教程](https://1byte.io/developer-guide-to-docker-and-kubernetes/)

********************************************************************************************************************************************************************************************************

# 基础软件

```bash
sudo apt install kubelet kubectl kubeadm
```

********************************************************************************************************************************************************************************************************

# 交换分区支持

> kubernetes 高版本不支持 `swap` 交换分区,需要配置 `--fail-swap-on=false`

[k8s-cluster.kubeadm-init.yaml]
```bash
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
failSwapOn: false
```

[[ERROR Swap]: running with swap on is not supported. Please disable swap](https://github.com/kubernetes/kubeadm/issues/610)
[kubeadm部署k8s1.9高可用集群--4部署master节点](https://segmentfault.com/a/1190000012559479)

********************************************************************************************************************************************************************************************************

# Kubernetes 集群安装

* 重新安装部署:

```bash
sudo kubeadm reset
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X && sudo iptables -L
sudo rm -rf /var/lib/rook
sudo rm -rf /etc/cni/net.d/*
```

* 将 `docker` 配置从  成 `systemd` -- 不推荐,存在已知问题

[CRI installation](https://kubernetes.io/docs/setup/cri/)
> 解决节点初始化警告: `[WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". Please follow the guide at https://kubernetes.io/docs/setup/cri/`

```bash
# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
```

重启并验证配置是否生效

```bash
$ docker info | grep Cgroup
Cgroup Driver: cgroupfs

$ systemctl restart docker

$ docker info | grep Cgroup
Cgroup Driver: systemd
```

* 查看需要安装的镜像

```bash
kubeadm config images list
```

* 使用 `kubeadm` 命令初始化 `master` 节点

```bash
sudo kubeadm init --kubernetes-version=v1.13.3 --pod-network-cidr=10.244.0.0/16 --service-cidr=10.96.0.0/12 --apiserver-advertise-address=172.31.141.97
```

* 使用配置文件初始化:

```bash
sudo kubeadm init --config k8s.cluster.kubeadm-init.yml
sudo kubeadm init --config k8s.cluster.kubeadm-init.yml --ignore-preflight-errors=NumCPU
```

查看 `kubelet` 启动日志

```bash
sudo journalctl -u kubelet -f
```

查看 `kubelet` 启动配置

```bash
sudo systemctl status kubelet --no-pager --full
sudo cat /etc/kubernetes/kubelet.conf
sudo cat /var/lib/kubelet/config.yaml
sudo cat /var/lib/kubelet/kubeadm-flags.env
```

* 拷贝用户配置文件

```bash
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

* 查看其它默认配置

```bash
kubeadm config print init-defaults
kubeadm config print join-defaults
```

* 查看运行配置:

```bash
kubeadm config view
```

* 查看 `kubelet` 启动参数:

```bash
$ ps -ef | grep kubelet
 /usr/bin/kubelet 
 --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf 
 --kubeconfig=/etc/kubernetes/kubelet.conf 
 --config=/var/lib/kubelet/config.yaml 
 --cgroup-driver=cgroupfs 
 --network-plugin=cni 
 --pod-infra-container-image=k8s.gcr.io/pause:3.1 
 --resolv-conf=/run/systemd/resolve/resolv.conf
```

* 从节点加入 `k8s` 集群

```bash
kubeadm reset -f
kubeadm join 172.31.141.97:6443 --token 597ipn.g13vistjg9ef2z4p --discovery-token-ca-cert-hash sha256:afd10e02b390bda0e31c9ca04ca7cd2c6e9f2b4f0a63ddf6194aaf2d6b3d5125
```

特别注意: 从节点如果之前已加入过节点, `join` 前也需要执行 `kubeadm reset -f` 否则加入新集群的时候节点日志会报如下错误:

```bash
$ journalctl -f
k8s.io/client-go/informers/factory.go:133: Failed to list *v1beta1.RuntimeClass: Unauthorized
```

* 创建新的 `token`

```bash
kubeadm token create --print-join-command
```

* 列出 `token`

```bash
$ kubeadm token list
TOKEN                     TTL       EXPIRES                     USAGES                   DESCRIPTION   EXTRA GROUPS
5w0v4s.c1u3dvz362fvgz9i   23h       2019-04-24T21:19:16+08:00   authentication,signing   <none>        system:bootstrappers:kubeadm:default-node-token
```

********************************************************************************************************************************************************************************************************

### 安装 `CNI` 网络插件

* 安装 `Weave` 网络插件 - 不推荐

```bash
wget -O k8s-plugins-weave-daemonset-k8s-1.8.yaml https://github.com/weaveworks/weave/releases/download/v2.5.1/weave-daemonset-k8s-1.8.yaml
$ kubectl apply -f k8s.kube-system.plugins.weave-daemonset-k8s-1.8.yaml
```

* 安装 `flannel` 网络插件 - 不推荐

```bash
wget -O k8s-plugins-kube-flannel.yml https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
sudo kubectl apply -f k8s-plugins-kube-flannel.yml
```

* 安装 `cilium` 网络插件 - 推荐

[Standard Installation](https://cilium.readthedocs.io/en/stable/gettingstarted/k8s-install-etcd-operator/)

# mount BPF filesystem on all nodes

```bash
# mount bpffs /sys/fs/bpf -t bpf
```

* 查看挂载状态

```bash
$ mount | grep /sys/fs/bpf
bpffs on /sys/fs/bpf type bpf (rw,relatime)
```

* 删除挂载

```bash
# umount bpffs /sys/fs/bpf -t bpf
```

[Requirements](https://docs.cilium.io/en/latest/concepts/kubernetes/requirements/#k8s-requirements)

* 部署

```bash
wget -O k8s.010.cluster.cni.cilium.yaml https://raw.githubusercontent.com/cilium/cilium/1.5.3/examples/kubernetes/1.15/cilium.yaml
kubectl create -f k8s.010.cluster.cni.cilium.yaml
```

手动编译 `cilium` 配置

```bash
curl -LO https://github.com/cilium/cilium/archive/1.6.3.tar.gz
tar xzvf 1.6.3.tar.gz
cd cilium-1.6.3/install/kubernetes 
helm template cilium --namespace kube-system  > cilium.yaml
mv cilium.yaml k8s.010.cluster.cni.cilium.yaml
kubectl apply -f cilium.yaml
```

[cilium kubernetes Configuration](https://cilium.readthedocs.io/en/stable/kubernetes/configuration/)

请注意,在初始化仅有一个主节点的条件下,一定要将主节点去除污点:

```bash
$ kubectl taint nodes --all node-role.kubernetes.io/master-
```

否则 `Cilium` 启动不了:

> [pod/cilium-operator-*]`Pending`
> [pod/etcd-operator-*]`Pending`

```bash
$ kubectl get pods --all-namespaces -owide
NAMESPACE     NAME                                        READY   STATUS    RESTARTS   AGE   IP              NODE     NOMINATED NODE   READINESS GATES
kube-system   pod/cilium-etcd-operator-7646c97877-lbwp8   1/1     Running   0          58s   172.31.141.97   a.us.1   <none>           <none>
kube-system   pod/cilium-operator-9df8d8b68-tmrbn         0/1     Pending   0          57s   <none>          <none>   <none>           <none>
kube-system   pod/cilium-slrtw                            1/1     Running   0          58s   172.31.141.97   a.us.1   <none>           <none>
kube-system   pod/coredns-fb8b8dccf-rhgwg                 1/1     Running   0          99s   10.244.0.33     a.us.1   <none>           <none>
kube-system   pod/coredns-fb8b8dccf-tpjg6                 1/1     Running   0          99s   10.244.0.140    a.us.1   <none>           <none>
kube-system   pod/etcd-a.us.1                             1/1     Running   0          47s   172.31.141.97   a.us.1   <none>           <none>
kube-system   pod/etcd-operator-797978964-s2j2n           0/1     Pending   0          54s   <none>          <none>   <none>           <none>
kube-system   pod/kube-apiserver-a.us.1                   1/1     Running   0          39s   172.31.141.97   a.us.1   <none>           <none>
kube-system   pod/kube-controller-manager-a.us.1          1/1     Running   0          56s   172.31.141.97   a.us.1   <none>           <none>
kube-system   pod/kube-proxy-bgwts                        1/1     Running   0          99s   172.31.141.97   a.us.1   <none>           <none>
kube-system   pod/kube-scheduler-a.us.1                   1/1     Running   0          59s   172.31.141.97   a.us.1   <none>           <none>
```

安装完的组件列表:

```bash
$ kubectl get pods,services --all-namespaces -owide
NAMESPACE     NAME                                        READY   STATUS    RESTARTS   AGE     IP              NODE     NOMINATED NODE   READINESS GATES
kube-system   pod/cilium-etcd-l7rdzbrmdx                  1/1     Running   0          33s     10.244.0.131    a.us.1   <none>           <none>
kube-system   pod/cilium-etcd-nrvz2vh2md                  1/1     Running   0          49s     10.244.0.21     a.us.1   <none>           <none>
kube-system   pod/cilium-etcd-operator-7646c97877-sj8bt   1/1     Running   0          2m44s   172.31.141.97   a.us.1   <none>           <none>
kube-system   pod/cilium-etcd-zsxn9zc59r                  1/1     Running   0          73s     10.244.0.202    a.us.1   <none>           <none>
kube-system   pod/cilium-njsk7                            1/1     Running   0          2m45s   172.31.141.97   a.us.1   <none>           <none>
kube-system   pod/cilium-operator-9df8d8b68-2l45g         1/1     Running   0          2m44s   10.244.0.179    a.us.1   <none>           <none>
kube-system   pod/coredns-fb8b8dccf-jd6hr                 1/1     Running   0          22m     10.244.0.192    a.us.1   <none>           <none>
kube-system   pod/coredns-fb8b8dccf-tdnwh                 1/1     Running   0          22m     10.244.0.220    a.us.1   <none>           <none>
kube-system   pod/etcd-a.us.1                             1/1     Running   0          22m     172.31.141.97   a.us.1   <none>           <none>
kube-system   pod/etcd-operator-797978964-pnf27           1/1     Running   0          2m35s   10.244.0.147    a.us.1   <none>           <none>
kube-system   pod/kube-apiserver-a.us.1                   1/1     Running   0          22m     172.31.141.97   a.us.1   <none>           <none>
kube-system   pod/kube-controller-manager-a.us.1          1/1     Running   0          22m     172.31.141.97   a.us.1   <none>           <none>
kube-system   pod/kube-proxy-r85fj                        1/1     Running   0          22m     172.31.141.97   a.us.1   <none>           <none>
kube-system   pod/kube-scheduler-a.us.1                   1/1     Running   0          22m     172.31.141.97   a.us.1   <none>           <none>

NAMESPACE     NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                  AGE   SELECTOR
default       service/kubernetes           ClusterIP   10.96.0.1       <none>        443/TCP                  23m   <none>
kube-system   service/cilium-etcd          ClusterIP   None            <none>        2379/TCP,2380/TCP        73s   app=etcd,etcd_cluster=cilium-etcd
kube-system   service/cilium-etcd-client   ClusterIP   10.108.64.235   <none>        2379/TCP                 73s   app=etcd,etcd_cluster=cilium-etcd
kube-system   service/kube-dns             ClusterIP   10.96.0.10      <none>        53/UDP,53/TCP,9153/TCP   23m   k8s-app=kube-dns
```

> 附启动过程

```bash
$ kubectl get pods --all-namespaces -owide -w
NAMESPACE     NAME                                    READY   STATUS              RESTARTS   AGE   IP              NODE     NOMINATED NODE   READINESS GATES
kube-system   cilium-njsk7                            0/1     Running             0          56s   172.31.141.97   a.us.1   <none>           <none>
kube-system   cilium-etcd-operator-7646c97877-sj8bt   1/1     Running             0          55s   172.31.141.97   a.us.1   <none>           <none>
kube-system   cilium-njsk7                            1/1     Running             0          76s   172.31.141.97   a.us.1   <none>           <none>
kube-system   coredns-fb8b8dccf-jd6hr                 0/1     Running             0          21m   10.244.0.192    a.us.1   <none>           <none>
kube-system   coredns-fb8b8dccf-tdnwh                 0/1     Running             0          21m   10.244.0.220    a.us.1   <none>           <none>
kube-system   coredns-fb8b8dccf-jd6hr                 1/1     Running             0          21m   10.244.0.192    a.us.1   <none>           <none>
kube-system   cilium-operator-9df8d8b68-2l45g         1/1     Running             0          82s   10.244.0.179    a.us.1   <none>           <none>
kube-system   coredns-fb8b8dccf-tdnwh                 1/1     Running             0          21m   10.244.0.220    a.us.1   <none>           <none>
kube-system   etcd-operator-797978964-pnf27           1/1     Running             0          83s   10.244.0.147    a.us.1   <none>           <none>
kube-system   cilium-etcd-zsxn9zc59r                  1/1     Running             0          21s   10.244.0.202    a.us.1   <none>           <none>
kube-system   cilium-etcd-nrvz2vh2md                  1/1     Running             0          9s    10.244.0.21     a.us.1   <none>           <none>
kube-system   cilium-etcd-l7rdzbrmdx                  1/1     Running             0          9s    10.244.0.131    a.us.1   <none>           <none>
```

********************************************************************************************************************************************************************************************************

## 安装 `Rook` 存储插件 - 未安装

[Ceph Storage Quickstart](https://rook.github.io/docs/rook/master/ceph-quickstart.html)
[rook使用教程，快速编排ceph](https://sealyun.com/post/rook/)

### 安装存储插件

安装 `Rook` + `Ceph`

```bash
git clone https://github.com/rook/rook.git
```

0. 删除已安装的残留文件(集群的每个节点都要删除):

```bash
rm -rf /var/lib/rook
rm -rf /var/lib/rook/mon-*
```

0. 初始化: `Common`

```bash
$ kubectl create -f rook/cluster/examples/kubernetes/ceph/common.yaml
```

1. 第一步: `Rook`

```bash
$ kubectl create -f rook/cluster/examples/kubernetes/ceph/operator.yaml
```

* 查看 `operator.yaml` 是否安装成功:

```bash
$ kubectl get pod -n rook-ceph -owide
NAME                                  READY   STATUS    RESTARTS   AGE     IP              NODE     NOMINATED NODE   READINESS GATES
rook-ceph-agent-4sz6x                 1/1     Running   0          3m26s   172.31.141.97   a.us.1   <none>           <none>
rook-ceph-agent-jh2w2                 1/1     Running   0          3m26s   172.31.141.98   a.us.2   <none>           <none>
rook-ceph-operator-775cf575c5-9tpbh   1/1     Running   0          3m29s   10.44.0.1       a.us.2   <none>           <none>
rook-discover-n957r                   1/1     Running   0          3m26s   10.32.4.108     a.us.1   <none>           <none>
rook-discover-pslwd                   1/1     Running   0          3m26s   10.44.0.3       a.us.2   <none>           <none>
```

2. 第二步: 然后创建 `Ceph` 集群:

```bash
$ kubectl create -f rook/cluster/examples/kubernetes/ceph/cluster.yaml
cephcluster.ceph.rook.io/rook-ceph created
```

查看 `Ceph` 集群:

```bash
$ kubectl get pod -n rook-ceph -owide
NAME                                  READY   STATUS    RESTARTS   AGE     IP              NODE     NOMINATED NODE   READINESS GATES
... ...
rook-ceph-mgr-a-76f567f8c8-z47xz      1/1     Running     0          7m22s   10.44.0.6       a.us.2   <none>           <none>
rook-ceph-mon-a-5ff954d874-n4lk4      1/1     Running     0          7m58s   10.44.0.4       a.us.2   <none>           <none>
rook-ceph-mon-b-74476f4b4c-8mltx      1/1     Running     0          7m50s   10.32.4.127     a.us.1   <none>           <none>
rook-ceph-mon-c-7b4cc9c876-dqw28      1/1     Running     0          7m35s   10.44.0.5       a.us.2   <none>           <none>
rook-ceph-osd-0-694c66b8f4-dmd2p      1/1     Running     4          6m41s   10.44.0.8       a.us.2   <none>           <none>
rook-ceph-osd-1-668b88b889-hwwh4      1/1     Running     3          6m41s   10.32.4.128     a.us.1   <none>           <none>
rook-ceph-osd-prepare-a.us.2-shmxb    0/2     Completed   0          6m51s   10.44.0.7       a.us.2   <none>           <none>
rook-ceph-osd-prepare-a.us.1-h9fd2    0/2     Completed   0          6m51s   10.32.4.128     a.us.1   <none>           <none>
```

* 查看存储插件情况

```bash
$ kubectl describe pods -n rook-ceph
```

* 如果出现 `default-scheduler  0/1 nodes are available: 1 node(s) had taints that the pod didn't tolerate.` 则执行以下命令

```bash
$ kubectl describe node a.us.1 | grep Taints
  Taints:             node-role.kubernetes.io/master:NoSchedule
$ kubectl taint nodes --all node-role.kubernetes.io/master-
node/a.us.1 untainted
$ kubectl describe node a.us.1 | grep Taints
Taints:             <none>
```

访问 `Ceph` 的 `dashboard`:

```bash
$ kubectl get svc -n rook-ceph -owide
NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE   SELECTOR
rook-ceph-mgr             ClusterIP   10.105.32.54     <none>        9283/TCP            10h   app=rook-ceph-mgr,rook_cluster=rook-ceph
rook-ceph-mgr-dashboard   ClusterIP   10.106.168.165   <none>        8443/TCP            10h   app=rook-ceph-mgr,rook_cluster=rook-ceph
rook-ceph-mon-a           ClusterIP   10.98.120.195    <none>        6789/TCP,3300/TCP   10h   app=rook-ceph-mon,ceph_daemon_id=a,mon=a,mon_cluster=rook-ceph,rook_cluster=rook-ceph
rook-ceph-mon-b           ClusterIP   10.97.28.208     <none>        6789/TCP,3300/TCP   10h   app=rook-ceph-mon,ceph_daemon_id=b,mon=b,mon_cluster=rook-ceph,rook_cluster=rook-ceph
rook-ceph-mon-c           ClusterIP   10.110.155.54    <none>        6789/TCP,3300/TCP   10h   app=rook-ceph-mon,ceph_daemon_id=c,mon=c,mon_cluster=rook-ceph,rook_cluster=rook-ceph
```

> 将 `rook-ceph-mgr-dashboard` 改成 `NodePort` 模式: 

```bash
$ kubectl edit service/rook-ceph-mgr-dashboard -n rook-ceph
```

> 该完后像下面这样:

```bash
rook-ceph-mgr-dashboard   NodePort    10.103.84.48     <none>        8443:31631/TCP   66m  # 把这个改成NodePort模式
```

或者重新启动一个 `NodePort` 服务:

```bash
$ kubectl apply -f rook/cluster/examples/kubernetes/ceph/dashboard-external-https.yaml
```

访问 `https://os.iirii.com:30543` 登录 `Ceph` 后台

* 管理账户`admin`,获取登录密码:

```bash
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o yaml | grep "password:" | awk '{print $2}' | base64 --decode
```

* 创建 `PV`:

```bash
kubectl apply -f k8s.rook-ceph.plugins.rook-storage.yaml
```

> 查看创建的 `storageclass`,`cephblockpool`

```bash
$ kubectl get storageclass,cephblockpool --all-namespaces
NAME                                          PROVISIONER          AGE
storageclass.storage.k8s.io/rook-ceph-block   ceph.rook.io/block   4m55s

NAMESPACE   NAME                                     AGE
rook-ceph   cephblockpool.ceph.rook.io/replicapool   4m55s
```

> 查看 `rook-ceph-osd-*` 启动参数:

[Ceph OSD attempts to bind to wrong IP after operator restart](https://github.com/rook/rook/issues/2429)

```bash
$ kubectl -n rook-ceph logs rook-ceph-osd-1-6fd649b6fd-hzt2b config-init
```

* 创建 `PVC`:

在 `cluster/examples/kubernetes` 目录下，官方给了个 `worldpress` 的例子，可以直接运行一下：

```bash
kubectl create -f rook/cluster/examples/kubernetes/mysql.yaml
kubectl create -f rook/cluster/examples/kubernetes/wordpress.yaml
```

刚运行发现等待很久,`Pod` 一直停留在 `ContainerCreating` 的状态:

```bash
$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                    READY   STATUS              RESTARTS   AGE
default       wordpress-595685cc49-4clvk              0/1     ContainerCreating   0          16m
```

查看 `Pod` 报错:

```bash
$ kubectl describe pods wordpress-595685cc49-4clvk -n default
mount command failed, status: Failure, reason: failed to mount volume /dev/rbd4 [xfs] to /var/lib/kubelet/plugins/ceph.rook.io/rook-ceph/mounts/pvc-, error executable file not found in $PATH
```

由于通过 `k8s.rook-ceph.plugins.rook-storage.yaml` 创建 `CephBlockPool` 的时候使用的是 `fstype: xfs`,查看本机支持的文件格式,却发现偏偏没有 `/sbin/mkfs.xfs`:

```bash
$ for i in mkfs.bfs mkfs.cramfs mkfs.ext2 mkfs.ext3 mkfs.ext4 mkfs.minix mkfs.xfs; do which $i; done;
/sbin/mkfs.bfs
/sbin/mkfs.cramfs
/sbin/mkfs.ext2
/sbin/mkfs.ext3
/sbin/mkfs.ext4
/sbin/mkfs.minix
```

于是修改 `fstype: xfs` 为 `fstype: xfs`,并重新部署

```bash
$ kubectl delete -f k8s.rook-ceph.plugins.rook-storage.yaml
$ kubectl apply -f k8s.rook-ceph.plugins.rook-storage.yaml
$ kubectl describe storageclass rook-ceph-block
```

参考 [CoreOS XFS mount error](https://github.com/rook/rook/issues/1476)

* 查看 `PV`、`PVC`：
  
```bash
$ kubectl get pvc,pv
```

### 常见问题

* 注意主机时间一定要同步

```bash
ntpdate 0.asia.pool.ntp.org
```

* 使用宿主机网络时集群无法正常启动 -- 集群中单节点时把mon设置成1即可

```bash
  mon:
    count: 1
    allowMultiplePerNode: true

  network:
    # toggle to use hostNetwork
    hostNetwork: true
```

********************************************************************************************************************************************************************************************************

# Kubernetes 命令

* 列出集群所有 `API` 资源:

```bash
kubectl api-resources
```

是否和命名空间有关

```bash
kubectl api-resources --namespaced=true
kubectl api-resources --namespaced=false
```

* 通过配置创建 `nodes,po,svc`

```bash
kubectl create -f svc.yml
kubectl create -f pod.yml
kubectl apply -f rook-storage.yaml
```

* 获取 `nodes,po,svc` 状态信息

```bash
kubectl get nodes,po,svc --all-namespaces
kubectl get pods --all-namespaces
kubectl get nodes,po,svc --all-namespaces -o wide
kubectl get pods -l app=nginx
kubectl get pods -n kube-system
```

* 通用资源文件

```bash
kubectl get all --all-namespaces
kubectl get all --namespace cert-manager
```

* 获取 `nodes,po,svc` 详细信息

```bash
kubectl describe node v.us.0
kubectl describe pods
kubectl describe pods -n rook-ceph
kubectl describe deployment nginx-deployment
```

* 删除 `deployment,node,pod`

```bash
kubectl delete deployment nginx-deployment
kubectl delete node v.cs.0
kubectl delete pod k8s-demo
```

> 强制删除 `Pod`:

```bash
kubectl delete pod/istio-telemetry-5589fc7d84-c9gjw -n istio-system --grace-period=0 --force
```

> 删除所有 `pods`

```bash
kubectl delete pods --all --all-namespaces
kubectl delete all --all --all-namespaces
```

* 其它

> serviceaccount

```bash
kubectl create serviceaccount --namespace=kube-system tiller
kubectl get serviceaccount --all-namespaces
```

* 查看 `pods` 环境变量

```bash
kubectl exec nginx-deployment-7c8765b784-2kv6h -- printenv | grep SERVICE
```

* 查看 `Service` 后端 `pods`

```bash
kubectl get ep us-nginx
kubectl get endpoints us-nginx
```

* 查看 `coredns` 容器状态

```bash
kubectl describe po $(kubectl get po -n=kube-system | grep coredns | tail -n 1 | awk '{print $1}') -n=kube-system
```

* 获取集群配置信息

```bash
kubectl -n kube-system get cm kubeadm-config -oyaml
```

* 查看集群状态

```bash
kubectl cluster-info
```

* 查看节点状态

```bash
curl https://66.42.110.223:6443 -k
```

* 获取组件的健康状态

```bash
kubectl get cs
```

* 获取当前系统的名称空间

```bash
kubectl get ns
```

* 拆卸集群

```bash
kubectl drain v.cs.0 --delete-local-data --force --ignore-daemonsets
kubectl delete node v.cs.0
```

********************************************************************************************************************************************************************************************************

## kubernetes 升级

* 首先升级 `kubeadm` `kubectl` `kubelet`

```bash
sudo apt update
sudo apt install kubeadm
sudo apt install kubectl
sudo apt install kubelet
```

* 安装指定版本

```bash
yum install -y kubelet-<version> kubectl-<version> kubeadm-<version>
```

```bash
yum install -y kubelet-1.20 kubectl-1.20 kubeadm-1.20
```

```bash
kubeadm version
kubectl version
kubelet --version
```

* 检查是否有更新

```bash
kubeadm upgrade plan
```

* 更新到指定版本

```bash
kubeadm upgrade apply v1.20.5
```

* 如果你的集群安装过程中遇到了其他问题,我们可以使用下面的命令来进行重置:

```bash
sudo kubeadm reset -f
sudo ifconfig cni0 down 
sudo ip link delete cni0
sudo ifconfig weave down
sudo ip link delete weave
sudo ifconfig flannel.1 down
sudo ip link delete flannel.1
sudo rm -rf /var/lib/cni/
```

* 完全删除安装(会删除所有包括Docker)

```bash
sudo kubeadm reset -f
sudo ip link delete docker0
sudo ip link delete cni0
sudo ip link delete weave
sudo ip link delete flannel.1
sudo ip link delete cilium_host
sudo ip link delete cilium_net
sudo ip link delete cilium_vxlan
sudo ip link delete br-*
```

* 卸载软件

```bash
sudo yum remove docker* kubeadm kubectl kubelet -y
sudo rpm -e $(rpm -qa | grep docker)
```

********************************************************************************************************************************************************************************************************

# Kubernetes 管理

* 通过 `YAML` 配置文件创建一个 `nginx` 部署:

```bash
$ wget -O kubernetes-deployment-nginx.yaml https://k8s.io/examples/application/deployment.yaml
$ kubectl apply -f kubernetes-deployment-nginx.yaml
```

* 发布时添加参数 `--record=true` 让 `Kubernetes` 把这行命令记到发布历史中备查

```bash
kubectl apply -f deployment.yml --record=true
```

* 显示发布的实时状态:

```bash
$ kubectl rollout status deployment k8s-demo-deployment
```

* 查看发布历史，如果发布使用了 `--record=true` 所以可以看到用于发布的命令

```bash
$ kubectl rollout history deployment k8s-demo-deployment
```

* 马上回滚到上个版本，可以用这个很简单的操作:

```bash
$ kubectl rollout undo deployment k8s-demo-deployment --to-revision=1
```

********************************************************************************************************************************************************************************************************

### K8s Ingress 实战

* 通用发布命令

```bash
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml
```

```bash
$ kubectl apply -f k8s.coam-in.deploy.mandatory.yaml
namespace/coam-in created
configmap/nginx-configuration created
configmap/tcp-services created
configmap/udp-services created
serviceaccount/nginx-ingress-serviceaccount created
clusterrole.rbac.authorization.k8s.io/nginx-ingress-clusterrole created
role.rbac.authorization.k8s.io/nginx-ingress-role created
rolebinding.rbac.authorization.k8s.io/nginx-ingress-role-nisa-binding created
clusterrolebinding.rbac.authorization.k8s.io/nginx-ingress-clusterrole-nisa-binding created
deployment.apps/nginx-ingress-controller created
service/coam-in created
```

* 构建一个服务

```bash
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/cloud-generic.yaml
```

```bash
$ kubectl apply -f k8s.coam-in.service.us-nginx.yaml
service/us-nginx created
```

* 创建第一个 `Ingress` 规则

```bash
$ kubectl apply -f k8s.coam-in.deploy.ingress.yaml
ingress.extensions/ingress created
```

* 最后指向 `nginx-deployment-*`

```bash
$kubectl apply -f k8s.coam-in.deploy.us-nginx.yaml
deployment.apps/nginx-deployment created
```

********************************************************************************************************************************************************************************************************

### 对外暴露服务端口

```bash
sudo kubectl port-forward --address 0.0.0.0 service/traefik 80:80 30888:8080 443:443 -n default
```

********************************************************************************************************************************************************************************************************

### 安装 `cert-manager` 组件:

[Installing cert-manager](https://cert-manager.readthedocs.io/en/latest/getting-started/install.html#installing-with-helm)

1. `cert-manager` 自定义版本安装 - 推荐✔️

* Install the CustomResourceDefinition resources separately

```bash
$ kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.7/deploy/manifests/00-crds.yaml
```

* Create the namespace for cert-manager

```bash
$ kubectl create namespace cert-manager
```

* Label the cert-manager namespace to disable resource validation

```bash
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
```

* Add the Jetstack Helm repository
```bash
helm repo add jetstack https://charts.jetstack.io
```

* Update your local Helm chart repository cache
```bash
helm repo update
```

* Install the cert-manager Helm chart
```bash
$ helm install jetstack/cert-manager --name cert-manager --namespace cert-manager --version v0.7.0
```

2. `cert-manager` 默认版本安装 - 失败❌

```bash
$ helm search cert-manager
NAME               	CHART VERSION	APP VERSION	DESCRIPTION
stable/cert-manager	v0.6.6       	v0.6.2     	A Helm chart for cert-manager
```

```bash
$ helm install stable/cert-manager --name cert-manager --namespace kube-system --version v0.6.6
Error: a release named cert-manager already exists.
Run: helm ls --all cert-manager; to check the status of the release
Or run: helm del --purge cert-manager; to delete it
```

```bash
$ helm del --purge cert-manager
release "cert-manager" deleted
```

```bash
$ helm install stable/cert-manager --name cert-manager --namespace kube-system --version v0.7.0 --wait
... ...
NOTES:
cert-manager has been deployed successfully!
... ...
```

```bash
$ helm ls --all
NAME        	REVISION	UPDATED                 	STATUS  	CHART              	APP VERSION	NAMESPACE
cert-manager	1       	Wed Apr  3 18:07:59 2019	DEPLOYED	cert-manager-v0.6.6	v0.6.2     	kube-system
```

```bash
kubectl label namespace <deployment-namespace> certmanager.k8s.io/disable-validation="true"
kubectl label namespace kube-system certmanager.k8s.io/disable-validation="true"
```

********************************************************************************************************************************************************************************************************

## 利用 `cert-manager` 让 `Ingress` 启用免费的 `HTTPS` 证书

[利用cert-manager让Ingress启用免费的HTTPS证书](https://imroc.io/posts/kubernetes/let-ingress-enable-free-https-with-cert-manager/)

* 建立 `ClusterIssuer` 颁发者

```bash
apply -f kubernetes/config/k8s-deployment-issuer-staging.yaml
```

* 配置域名证书

```bash
$ kubectl apply -f k8s.coam-in.deploy-domains-staging-cert.yaml
certificate.certmanager.k8s.io/coam-in-staging-pyios-com created
```

* 导入 `Ingress` 规则配置证书使之生效:

```bash
$ kubectl apply -f k8s.coam-in.deploy.ingress.yaml
ingress.extensions/ingress configured
```

```bash
  tls:
    - secretName: coam-in-staging-pyios-com-tls
      hosts:
        - pyios.com
        - www.pyios.com
        - wsa.pyios.com
        - wechat.wh.pyios.com
        - admin.wh.pyios.com
        - operate.wh.pyios.com
        - ucenter.wh.pyios.com
        - mall.wh.pyios.com
        - shop.wh.pyios.com
        - api.wh.pyios.com
        - opi.wh.pyios.com
        - wechat.qd.pyios.com
        - admin.qd.pyios.com
```

********************************************************************************************************************************************************************************************************

## 在 `kubernetes` 中不同命名空间的服务相互访问

[在kubernets中不同命名空间的服务相互访问](https://johng.cn/services-communication-in-different-namespaces-in-kubernets/)
[kubernetes最佳实践S01E02：使用命名空间管理资源](https://kelvinji2009.github.io/blog/k8s-best-practice-s01e02/)
[Using wildcard certificates with cert-manager in Kubernetes and replicating across all namespaces](https://itnext.io/using-wildcard-certificates-with-cert-manager-in-kubernetes-and-replicating-across-all-namespaces-5ed1ea30bb93)

> 涉及到的是Pod和Service之间的相互访问，主要格式如下：

* Pod:

```bash
{pod-ip}.{namespace}.svc.cluster.local
{pod-name}.{namespace}.svc.cluster.local
{pod-name}.{subdomain}.{namespace}.svc.cluster.local
```

* StatefulSet:

```bash
{pod-name}.{service-name}.{namespace}.svc.cluster.local
可以进入到pod中查看/etc/hosts
```

* Service:

```bash
{service-name}.{namespace).svc.cluster.local
```

详细请参考官方文档：https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/

* 跨命名空间访问服务 `ExternalName` 配置 `k8s-service-us.nginx-in.yaml` 不生效:

```bash
k8s-service-us.nginx-in.yaml
```

********************************************************************************************************************************************************************************************************

## 删除 `Pods` 状态为 `Evicted` 的容器

```bash
kubectl get pods -n kube-system| grep Evicted | awk '{print $1}' | xargs kubectl delete pod -n kube-system
```
********************************************************************************************************************************************************************************************************

## 从已有证书生成 secret

[TLS Termination](https://www.getambassador.io/user-guide/tls-termination/)

```bash
kubectl create secret tls user-secret --cert=$FULLCHAIN_PATH --key=$PRIVKEY_PATH
kubectl create secret tls production-tls --cert=/etc/letsencrypt/archive/pyios.com/fullchain.pem --key=/etc/letsencrypt/archive/pyios.com/privkey.pem -n coam-in
kubectl -n coam-in get secret production-tls -oyaml
kubectl -n coam-in delete secret production-tls
```

********************************************************************************************************************************************************************************************************

## Traefik

[traefik.io](https://traefik.io)
[详解k8s组件Ingress边缘路由器并落地到微服务 - kubernetes](http://www.cnblogs.com/justmine/p/8991379.html)

********************************************************************************************************************************************************************************************************

## k8s 暴露集群内端口方法

[k8s pod的4种网络模式最佳实战(externalIPs )](https://www.cnblogs.com/cheyunhua/p/8552457.html)
[从外部访问Kubernetes中的Pod](https://jimmysong.io/posts/accessing-kubernetes-pods-from-outside-of-the-cluster/)

* hostPort

> 相当于 `docker run -p 8081:8080`,不用创建svc,因此端口只在容器运行的vm上监听
> 缺点: 没法多pod负载

```bash
$ cat pod-hostport.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: webapp
  labels:
    app: webapp
spec:
  containers:
  - name: webapp
    image: tomcat
    ports:
    - containerPort: 8080
      hostPort: 8081
```

* hostNetwork

> 相当于 `docker run --net=host` ,不用创建svc,因此端口只在容器运行的vm上监听
> 缺点: 没法多pod负载

```bash
apiVersion: v1
kind: Pod
metadata:
  name: webapp
  labels:
    app: webapp
spec:
  hostNetwork: true
  containers:
  - name: webapp
    image: tomcat
    ports:
    - containerPort: 8080
```

* NodePort-svc

> 由kube-proxy操控,所有节点规则统一,逻辑上市全局的
> 因此,svc上的nodeport会监听在所有的节点上(如果不指定,即是随机端口,由apiserver指定--service-node-port-range '30000-32767'),即使有1个pod,任意访问某台的nodeport都可以访问到这个服务

```bash
kind: Service
apiVersion: v1
metadata:
  name: mynginx
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 80
```

* externalIPs

> 通过svc创建,在指定的node上监听端口
> 适用场景: 想通过svc来负载,但要求某台指定的node上监听,而非像nodeport所有节点监听.
  
```bash
apiVersion: v1
kind: Service
metadata:
  name: svc-nginx
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
  externalIPs: 
    - 192.168.2.12 #这是我的一台node的ip
```

### 常用网络管理命令

```bash
iptables -L -t nat
netstat -n --udp --list
```

********************************************************************************************************************************************************************************************************

## JSONPath 支持

[JSONPath Support](https://kubernetes.io/docs/reference/kubectl/jsonpath/)

* 按 json 格式打印输出

```bash
kubectl -n coam-dev-php-ns get svc us-rpc -o json
```

* 筛选数组元素

```bash
kubectl -n coam-dev-php-ns get svc us-rpc -o jsonpath='{.spec.ports[?(@.targetPort==22222)]}'
kubectl -n coam-dev-php-ns get svc us-rpc -o jsonpath='{.spec.ports[?(@.targetPort==22222)]}{.nodePort}'
```

* 迭代筛选结果并处理结果

> 加字符或加换行符

```bash
kubectl -n coam-dev-php-ns get svc us-rpc -o jsonpath='{range .spec.ports[?(@.targetPort==22222)]}[-{.nodePort}-]{end}'
kubectl -n coam-dev-php-ns get svc us-rpc -o jsonpath='{range .spec.ports[?(@.targetPort==22222)]}{.nodePort}{"\n"}{end}'
```

* 筛选数组结果

```bash
kubectl -n coam-dev-php-ns get svc us-rpc -o jsonpath='{range .spec.ports[?(@.targetPort==22222)]}{.nodePort}{"\n"}{end}' | wc -l
```

********************************************************************************************************************************************************************************************************

## kubernetes 命名空间无法删除问题

[deleting namespace stuck at "Terminating" state #60807](https://github.com/kubernetes/kubernetes/issues/60807)
[删除K8s Namespace时卡在Terminating状态](https://www.ichenfu.com/2019/02/20/kubernetes-namespaces-stuck-in-terminating-state/)
[Delete Namespace Stuck At Terminating State](https://nasermirzaei89.net/2019/01/27/delete-namespace-stuck-at-terminating-state/)


> 以下演示删除命名空间 `cert-manager`:

```bash
$ kubectl get namespaces
NAME              STATUS        AGE
cert-manager      Terminating   24d
... ...
$ kubectl delete namespace/cert-manager
Error from server (Conflict): Operation cannot be fulfilled on namespaces "cert-manager": The system is ensuring all content is removed from this namespace.  Upon completion, this namespace will automatically be purged by the system.
$ kubectl delete ns cert-manager --grace-period=0 --force
warning: Immediate deletion does not wait for confirmation that the running resource has been terminated. The resource may continue to run on the cluster indefinitely.
Error from server (Conflict): Operation cannot be fulfilled on namespaces "cert-manager": The system is ensuring all content is removed from this namespace.  Upon completion, this namespace will automatically be purged by the system.
```

* 通常可以加 `--now` 参数快速删除

```bash
$ kubectl delete ns cert-manager -now
Error from server (Conflict): Operation cannot be fulfilled on namespaces "cert-manager": The system is ensuring all content is removed from this namespace.  Upon completion, this namespace will automatically be purged by the system.
```

* 查看命名空间 `cert-manager` 的 `finalizers`

```bash
$ kubectl get namespace cert-manager -o yaml
apiVersion: v1
kind: Namespace
metadata:
  creationTimestamp: "2019-04-03T10:58:00Z"
  deletionTimestamp: "2019-04-27T15:12:49Z"
  labels:
    certmanager.k8s.io/disable-validation: "true"
  name: cert-manager
  resourceVersion: "9900408"
  selfLink: /api/v1/namespaces/cert-manager
  uid: 58e30179-55ff-11e9-90b6-00163e000ffe
spec:
  finalizers:
  - kubernetes
status:
  phase: Terminating
```

```bash
kubectl get namespace cert-manager -o json > k8s-tmp.json
```

```bash
{
    "apiVersion": "v1",
    "kind": "Namespace",
    "metadata": {
        "annotations": {
            "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Namespace\",\"metadata\":{\"annotations\":{},\"name\":\"cert-manager\"}}\n"
        },
        "creationTimestamp": "2019-04-24T06:38:07Z",
        "deletionTimestamp": "2019-04-28T08:01:35Z",
        "name": "cert-manager",
        "resourceVersion": "9991225",
        "selfLink": "/api/v1/namespaces/cert-manager",
        "uid": "855bb9fa-665b-11e9-96ab-00163e000ffe"
    },
    "spec": {
        "finalizers": [
            "kubernetes"
        ]
    },
    "status": {
        "phase": "Terminating"
    }
}
```

> 删除 "kubernetes" 元素:

```bash
{
    "apiVersion": "v1",
    "kind": "Namespace",
    "metadata": {
        "annotations": {
            "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Namespace\",\"metadata\":{\"annotations\":{},\"name\":\"cert-manager\"}}\n"
        },
        "creationTimestamp": "2019-04-24T06:38:07Z",
        "deletionTimestamp": "2019-04-28T08:01:35Z",
        "name": "cert-manager",
        "resourceVersion": "9991225",
        "selfLink": "/api/v1/namespaces/cert-manager",
        "uid": "855bb9fa-665b-11e9-96ab-00163e000ffe"
    },
    "spec": {
        "finalizers": [

        ]
    },
    "status": {
        "phase": "Terminating"
    }
}
```

* 使用通过配置文件调用接口删除:

```bash
$ curl -k -H "Content-Type: application/json" -X PUT --data-binary @k8s-tmp.json https://172.31.141.97:6443/api/v1/namespaces/cert-manager/finalize
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {

  },
  "status": "Failure",
  "message": "namespaces \"cert-manager\" is forbidden: User \"system:anonymous\" cannot update resource \"namespaces/finalize\" in API group \"\" in the namespace \"cert-manager\"",
  "reason": "Forbidden",
  "details": {
    "name": "cert-manager",
    "kind": "namespaces"
  },
  "code": 403
}
```

> 因为这边的 `k8s` 集群是带认证的，所以又新开了窗口运行 `kubectl proxy` 跑一个API代理在本地的8081端口

```bash
$ kubectl proxy
Starting to serve on 127.0.0.1:8001
```

```bash
$ curl -k -H "Content-Type: application/json" -X PUT --data-binary @k8s-tmp.json http://127.0.0.1:8001/api/v1/namespaces/cert-manager/finalize
{
  "kind": "Namespace",
  "apiVersion": "v1",
  "metadata": {
    "name": "cert-manager",
    "selfLink": "/api/v1/namespaces/cert-manager/finalize",
    "uid": "855bb9fa-665b-11e9-96ab-00163e000ffe",
    "resourceVersion": "9997150",
    "creationTimestamp": "2019-04-24T06:38:07Z",
    "deletionTimestamp": "2019-04-28T08:01:35Z",
    "annotations": {
      "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Namespace\",\"metadata\":{\"annotations\":{},\"name\":\"cert-manager\"}}\n"
    }
  },
  "spec": {

  },
  "status": {
    "phase": "Terminating"
  }
}
```

sudo rm -rf /var/lib/rook
kubectl proxy
kubectl get namespace rook-ceph -o json > k8s-rook-ceph.json
curl -k -H "Content-Type: application/json" -X PUT --data-binary @k8s-rook-ceph.json http://127.0.0.1:8001/api/v1/namespaces/rook-ceph/finalize

* 删除 `Termination` 状态的命名空间

[How to fix — Kubernetes namespace deleting stuck in Terminating state](https://medium.com/@craignewtondev/how-to-fix-kubernetes-namespace-deleting-stuck-in-terminating-state-5ed75792647e)
[deleting namespace stuck at "Terminating" state](https://github.com/kubernetes/kubernetes/issues/60807#issuecomment-408599873)

其它

```bash
kubectl api-resources -o name --verbs=list --namespaced | xargs -n 1 kubectl get --show-kind --ignore-not-found -n coam-devops-ns
kubectl get ns coam-devops-ns -o json > coam-devops-ns.json
curl -k -H "Content-Type:application/json" -X PUT --data-binary @coam-devops-ns.json http://t.cs.1:6443/api/v1/namespaces/coam-devops-ns/finalize
```

********************************************************************************************************************************************************************************************************

## 集群卡,`kube-scheduler-a.us.1`、`kube-controller-manager-a.us.1`、`etcd-operator-797978964-mc6hj`、`rook-ceph-operator-7bbb59d7bd-dm6sh` 等 `Pods` 不停重启

> 查看系统日志

* 从节点 `a.us.2`:

```bash
May 05 10:58:38 a.us.2 kubelet[2128]: E0505 10:58:38.445039    2128 kubelet_volumes.go:154] Orphaned pod "e26eb549-6e4b-11e9-8359-00163e000ffe" found, but volume paths are still present on disk : There were a total of 2 errors similar to this. Turn up verbosity to see them.
```

* 主节点 `a.us.1`:

```bash
May 05 11:01:38 a.us.1 kubelet[597]: E0505 11:01:38.601102     597 pod_workers.go:190] Error syncing pod f423ac50e24b65e6d66fe37e6d721912 ("kube-controller-manager-a.us.1_kube-system(f423ac50e24b65e6d66fe37e6d721912)"), skipping: failed to "StartContainer" for "kube-controller-manager" with CrashLoopBackOff: "Back-off 5m0s restarting failed container=kube-controller-manager pod=kube-controller-manager-a.us.1_kube-system(f423ac50e24b65e6d66fe37e6d721912)"
```

问题定位

从错误信息可以推测到，这台计算节点存在一个孤儿Pod,并且该Pod挂载了数据卷(volume)，阻碍了 Kubelet 对孤儿Pod正常的回收清理。

> 注意: 孤儿Pod: 就是裸露的Pod，没有相关的控制器领养的Pod

解决问题

```bash
sudo rm -r /var/lib/kubelet/pods/e26eb549-6e4b-11e9-8359-00163e000ffe
sudo rm -r /var/lib/kubelet/pods/e8d8382d-6e4b-11e9-8359-00163e000ffe
```

[定位 Orphaned Pod Found - but Volume Paths Are Still Present on Disk 问题](https://xigang.github.io/2018/12/31/Orphaned-pod/)

1.首先通过 `Pod` 的 `ID` 获取 `Pod` 的挂载数据卷的 `mount` 信息:

```bash
mount -l | grep e26eb549-6e4b-11e9-8359-00163e000ffe
```

********************************************************************************************************************************************************************************************************
