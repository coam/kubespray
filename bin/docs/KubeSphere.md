# KubeSphere 用法

## 最小化安装 kubeSphere

> 需要配置默认的 sc

```bash
kubectl apply -f https://github.com/kubesphere/ks-installer/releases/download/v3.4.0/kubesphere-installer.yaml
kubectl apply -f https://github.com/kubesphere/ks-installer/releases/download/v3.4.0/cluster-configuration.yaml
```

安装结果:

```bash
Collecting installation results ...
#####################################################
###              Welcome to KubeSphere!           ###
#####################################################

Console: http://148.135.125.157:30880
Account: admin
Password: P@88w0rd
NOTES：
  1. After you log into the console, please check the
     monitoring status of service components in
     "Cluster Management". If any service is not
     ready, please wait patiently until all components
     are up and running.
  2. Please change the default password after login.

#####################################################
https://kubesphere.io             2023-12-05 11:27:57
#####################################################
```

## 常见问题

### prometheus 一直为 `Pending` 状态

```bash
kubesphere-monitoring-system   prometheus-k8s-0                                    0/2     Pending   0             9m49s
```

查看 `pod` 服务日志:

```bash
$ kubectl describe pod prometheus-k8s-0 -n kubesphere-monitoring-system
...
Events:
  Type     Reason            Age    From               Message
  ----     ------            ----   ----               -------
  Warning  FailedScheduling  10m    default-scheduler  0/2 nodes are available: 2 node(s) didn't find available persistent volumes to bind. preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling..
  Warning  FailedScheduling  4m37s  default-scheduler  0/2 nodes are available: 2 node(s) didn't find available persistent volumes to bind. preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling..
```

查看发现有一个 `prometheus-k8s-db-prometheus-k8s-0` 的 `pvc` 记录，显示在 `Pending` 状态

```bash
kubectl get pvc -A
NAMESPACE                      NAME                                 STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS    AGE
kubesphere-monitoring-system   prometheus-k8s-db-prometheus-k8s-0   Pending                                      local-storage   11m
```

绑定了默认的 `local-storage` 但是没有 `pv` 卷。

查看 `local-storage` 声明:

```bash
# kubectl get sc -A
NAME                      PROVISIONER                    RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-storage (default)   kubernetes.io/no-provisioner   Delete          WaitForFirstConsumer   false                  20h
```

默认的 `local-storage` `SC` 的 `provisioner` 设为 `kubernetes.io/no-provisioner` 指的是没有 `Provisioner` 会自动为 `PVC` 创建 `PV`，
参考 `local volume` 的 [K8s官方示例](https://kubernetes.io/docs/concepts/storage/volumes/#local)，这意味着你需要手动创建 `local` 类型的 `PV`，才能使得它被 `PVC` 成功绑定，进一步使得 `Pod` 成功使用 `PVC`。

手动创建 `pv` 卷:

```bash
apiVersion: v1
kind: PersistentVolume
metadata:
  name: prometheus-k8s-pv
  labels:
    type: local
spec:
  storageClassName: local-storage
  capacity:
    storage: 30Gi
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  persistentVolumeReclaimPolicy: Delete
  local:
    path: /mnt/disks/ssd1
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node2
```

提交更改

```bash
kubectl apply -f pv.yaml
```

再次查看 `pod` 容器日志:

```bash
Events:
  Type     Reason            Age                From               Message
  ----     ------            ----               ----               -------
  Warning  FailedScheduling  22m                default-scheduler  0/2 nodes are available: 2 node(s) didn't find available persistent volumes to bind. preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling..
  Warning  FailedScheduling  11m (x2 over 17m)  default-scheduler  0/2 nodes are available: 2 node(s) didn't find available persistent volumes to bind. preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling..
  Normal   Scheduled         15s                default-scheduler  Successfully assigned kubesphere-monitoring-system/prometheus-k8s-0 to node2
  Warning  FailedMount       8s (x5 over 15s)   kubelet            MountVolume.NewMounter initialization failed for volume "prometheus-k8s-pv" : path "/mnt/disks/ssd1" does not exist
```

[prometheus-k8s-0 启动失败，一直 pending 状态。](https://ask.kubesphere.io/forum/d/5445-prometheus-k8s-0-pending)