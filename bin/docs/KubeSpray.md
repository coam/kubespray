# Kubespray 用法

> 请不要使用 `Kubespray` 的 `master` 分支，请使用最新 `tag` 来安装 `K8S` 集群

项目部署

```bash
ansible-playbook plays/deploy.yml
```

集群配置

```bash
cp -rfp inventory/sample inventory/mycluster

declare -a IPS=(148.135.125.157 142.171.26.116)
CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}
```

集群部署

```bash
ansible-playbook -i inventory/mycluster/hosts.yaml -u root --become --become-user=root cluster.yml
```

移除集群

```bash
ansible-playbook -i inventory/mycluster/hosts.yaml -u root --become --become-user=root -e reset_confirmation=yes reset.yml
```

### 集群更新

更新对应的配置位置，执行集群部署命令即可

```bash
ansible-playbook -i inventory/mycluster/hosts.yaml -u root --become --become-user=root cluster.yml
```

使用 `kubectl port-forward` 开启 `Dashboard` 对外访问

```bash
sudo kubectl port-forward --address 0.0.0.0 service/kubernetes-dashboard 443:443 -n kube-system
```

现在访问: https://148.135.125.157/#/login

### 集群升级

```bash
ansible-playbook -i inventory/mycluster/hosts.yaml -e dashboard_enabled=true -b --become-user=root upgrade-cluster.yml
```

## 其它

### 开启交换分区

需要在 `/root/kubespray/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml` 增加以下配置

```bash
kubelet_fail_swap_on: false
kube_feature_gates:
- "NodeSwap=True"
```

### 设置集群默认 `storageclass`

默认使用 `kubespray` 安装 `k8s` 集群后开启 `local_volume_provisioner_enabled: true` 会创建了一个名为 `local-storage` 的 `storageclass`。

以下命令设置集群默认 `storageclass` 为 `local-storage`:

```bash
kubectl patch storageclass local-storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

[Change the default StorageClass](https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/)

## 常见问题

### Ubuntu `22.04` 安装出现 `CoreDNS` 启动失败

修改 [inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml] 配置,将 `ipvs` 改成 `iptables` 模式:

```bash
kube_proxy_mode: iptables
```

重新部署集群

## 参考资料

* [Kubespray Advanced Configuration For A Production Cluster](https://technekey.com/kubespray-advanced-configuration-for-a-production-cluster/)
* [Setting up a Kubernetes cluster with Kubespray](https://medium.com/@leonardo.bueno/setting-up-a-kubernetes-cluster-with-kubespray-1bf4ce8ccd73)
* [使用kubespray部署](https://jinhui.dev/kubernetes/deploy/kubespray.html)