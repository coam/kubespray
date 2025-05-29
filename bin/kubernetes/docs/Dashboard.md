
# Dashboard 安装配置

* 安装 `Dashboard` 控制面板

```bash
$ kubectl apply -f config/k8s.kube-system.dashboard.init.yaml
```

## 新建一个管理员

1. 用 `Dashboard` 自带的角色添加权限

* 给 `k8s-dashboard` 的 `ServiceAccount` 绑定权限

```bash
kubectl apply -f k8s-dashboard-admin.yaml
```

> 此账户获取 `Token` 的方式

```bash
kubectl describe secrets $(kubectl get secrets --namespace kube-system | grep dashboard-token | awk '{print $1}') --namespace kube-system | grep token: | awk '{print $2}'
```

2. 新建一个账户 赋予权限

```bash
kubectl apply -f k8s.kube-system.deploy.account.yaml
```

> 此账户获取 `Token` 的方式

```bash
kubectl describe secrets $(kubectl get secrets --namespace kube-system | grep admin-coam-serviceaccount-token | awk '{print $1}') --namespace kube-system | grep token: | awk '{print $2}'
```

* 如果登录 `dashboard` 后台提示如下警告:

```bash
persistentvolumeclaims is forbidden: User "system:serviceaccount:kube-system:admin-coam-serviceaccount" cannot list resource "persistentvolumeclaims" in API group "" in the namespace "default" 
configmaps is forbidden: User "system:serviceaccount:kube-system:admin-coam-serviceaccount" cannot list resource "configmaps" in API group "" in the namespace "default" 
```

> 执行以下命令解决:

```bash
kubectl create clusterrolebinding admin-coam-serviceaccount --clusterrole=cluster-admin --serviceaccount=kube-system:admin-coam-serviceaccount
```

> 其它: 查看角色配置信息

```bash
kubectl -n kube-system describe role kubernetes-dashboard-minimal
kubectl -n kube-system describe rolebinding kubernetes-dashboard-minimal
```

参考 [Dashboard permission errors from `kubectl proxy` on K8s 1.10.3 cluster deployed from acs-engine master](https://github.com/Azure/acs-engine/issues/3130)

## 通过新建服务对外暴露端口:

通过 `NodeIP` + `NodePort` 访问,此方法可以任意访问.但是存在证书问题,忽略即可

> 重新修改 `k8s-dashboard.yaml` 拉到底 找到 `Service` 区域 `spec` 改为 `NodePort`, 重新部署,使其生效

```bash
kubectl apply -f k8s-dashboard.yaml
```