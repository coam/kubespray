# `k8s` 集群部署

## `kubespray` 集群部署配置

### 配置集群节点

`inventory/mycluster/hosts.yaml`

### 执行脚本配置

执行 `bin/kubespray.sh` 脚本配置 `supplementary_addresses_in_ssl_keys`，添加集群外网访问域名及 `ip`

```bash
bin/kubespray.sh reconfig
```

挂载目录

```bash
sudo mount --bind /zscloud/data/kubelet /var/lib/kubelet
```

### 执行集群部署

执行 `bin/cluster.sh`

```bash
bin/cluster.sh deploy
```

### 下载集群配置文件

执行 `bin/cluster.sh`

```bash
bin/cluster.sh down
```

## `helm` 集群基础配置

### 配置默认 `config/kube.config` 集群授权文件

```bash
bin/link.sh run
```

### 部署 `OpenEBS` 网关

```bash
bin/storage.sh install
```

### 部署 `istio` 网关

```bash
bin/istio.sh install
```

配置 `k8s` 网关资源

```bash
./bin/charts/istio.sh init
```

配置网关 `gpuez-gateway`

```bash
bin/deploy/istio.sh gateway
```

### 部署 `gpu-operator` 运行时

```bash
bin/tests/nvidia-operator.sh install
```

检查是否已自动配置 `nvidia` 运行时

```bash
cat /etc/containerd/config.toml
```

最终部署的资源清单

```bash
kubectl get all -n gpu-operator
NAME                                                             READY   STATUS      RESTARTS   AGE
pod/gpu-feature-discovery-bwfxx                                  1/1     Running     0          20m
pod/gpu-feature-discovery-cvgcm                                  1/1     Running     0          20m
pod/gpu-feature-discovery-fdmsj                                  1/1     Running     0          20m
pod/gpu-operator-65f48cdbf9-6htrz                                1/1     Running     0          24m
pod/gpuoperator-node-feature-discovery-gc-7b9cccd478-dhv95       1/1     Running     0          24m
pod/gpuoperator-node-feature-discovery-master-54467d76d9-d448p   1/1     Running     0          24m
pod/gpuoperator-node-feature-discovery-worker-bmxqd              1/1     Running     0          24m
pod/gpuoperator-node-feature-discovery-worker-qg8xb              1/1     Running     0          24m
pod/gpuoperator-node-feature-discovery-worker-ttxq4              1/1     Running     0          24m
pod/nvidia-container-toolkit-daemonset-8sbkd                     1/1     Running     0          20m
pod/nvidia-container-toolkit-daemonset-ghr7n                     1/1     Running     0          20m
pod/nvidia-container-toolkit-daemonset-xx7sk                     1/1     Running     0          20m
pod/nvidia-cuda-validator-56nfd                                  0/1     Completed   0          7m16s
pod/nvidia-cuda-validator-rsl4t                                  0/1     Completed   0          10m
pod/nvidia-cuda-validator-vtf6k                                  0/1     Completed   0          4m34s
pod/nvidia-dcgm-exporter-gg4h2                                   1/1     Running     0          20m
pod/nvidia-dcgm-exporter-j7mtf                                   1/1     Running     0          20m
pod/nvidia-dcgm-exporter-kdwxl                                   1/1     Running     0          20m
pod/nvidia-device-plugin-daemonset-86lbx                         1/1     Running     0          20m
pod/nvidia-device-plugin-daemonset-b9n4x                         1/1     Running     0          20m
pod/nvidia-device-plugin-daemonset-fdzfh                         1/1     Running     0          20m
pod/nvidia-operator-validator-5nsz8                              1/1     Running     0          20m
pod/nvidia-operator-validator-b2c9s                              1/1     Running     0          20m
pod/nvidia-operator-validator-mh6wm                              1/1     Running     0          20m

NAME                           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/gpu-operator           ClusterIP   10.233.21.149   <none>        8080/TCP   20m
service/nvidia-dcgm-exporter   ClusterIP   10.233.1.127    <none>        9400/TCP   20m

NAME                                                       DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                                                          AGE
daemonset.apps/gpu-feature-discovery                       3         3         3       3            3           nvidia.com/gpu.deploy.gpu-feature-discovery=true                       20m
daemonset.apps/gpuoperator-node-feature-discovery-worker   3         3         3       3            3           <none>                                                                 24m
daemonset.apps/nvidia-container-toolkit-daemonset          3         3         3       3            3           nvidia.com/gpu.deploy.container-toolkit=true                           20m
daemonset.apps/nvidia-dcgm-exporter                        3         3         3       3            3           nvidia.com/gpu.deploy.dcgm-exporter=true                               20m
daemonset.apps/nvidia-device-plugin-daemonset              3         3         3       3            3           nvidia.com/gpu.deploy.device-plugin=true                               20m
daemonset.apps/nvidia-device-plugin-mps-control-daemon     0         0         0       0            0           nvidia.com/gpu.deploy.device-plugin=true,nvidia.com/mps.capable=true   20m
daemonset.apps/nvidia-driver-daemonset                     0         0         0       0            0           nvidia.com/gpu.deploy.driver=true                                      20m
daemonset.apps/nvidia-mig-manager                          0         0         0       0            0           nvidia.com/gpu.deploy.mig-manager=true                                 20m
daemonset.apps/nvidia-operator-validator                   3         3         3       3            3           nvidia.com/gpu.deploy.operator-validator=true                          20m

NAME                                                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/gpu-operator                                1/1     1            1           24m
deployment.apps/gpuoperator-node-feature-discovery-gc       1/1     1            1           24m
deployment.apps/gpuoperator-node-feature-discovery-master   1/1     1            1           24m

NAME                                                                   DESIRED   CURRENT   READY   AGE
replicaset.apps/gpu-operator-65f48cdbf9                                1         1         1       24m
replicaset.apps/gpuoperator-node-feature-discovery-gc-7b9cccd478       1         1         1       24m
replicaset.apps/gpuoperator-node-feature-discovery-master-54467d76d9   1         1         1       24m
```

### 部署 `hami` gpu 虚拟化

配置 `RuntimeClass`

```bash
bin/tests/nvidia-device-plugin.sh runtime
```

查看运行时配置

```bash
$ kubectl get runtimeclass -A
NAME     HANDLER   AGE
nvidia   nvidia    20s
```

部署 `hami` 服务组件

```bash
bin/tests/hami.sh install
```

## tools

部署 `tools` 服务组件

```bash
./bin/charts/tools.sh install
```

## 其它配置

创建命名空间

```bash
kubectl create ns gpuez
```

同步基础文件到远程服务器

```bash
sst /Users/coam/Downloads/container zsc.hf.14:/root/container
```

创建私有镜像仓库密码机域名证书配置

```bash
bin/deploy/config.sh reconfig
```