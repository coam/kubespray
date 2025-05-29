# Dashboard 配置

## `Dashboard` 账号权限管理

创建 `ServiceAccount`

```bash
kubectl create sa kube-ds-viewer -n kube-system
kubectl create sa kube-ds-editor -n kube-system
kubectl create sa kube-ds-admin -n kube-system
```

创建 `ClusterRoleBinding`

```bash
kubectl create clusterrolebinding kube-ds-viewer-role-binding --clusterrole=view --user=system:serviceaccount:kube-system:kube-ds-viewer
kubectl create clusterrolebinding kube-ds-editor-role-binding --clusterrole=edit --user=system:serviceaccount:kube-system:kube-ds-editor
kubectl create clusterrolebinding kube-ds-admin-role-binding --clusterrole=admin --user=system:serviceaccount:kube-system:kube-ds-admin
```

创建 `token`

```bash
kubectl create token kube-ds-viewer -n kube-system
kubectl create token kube-ds-editor -n kube-system
kubectl create token kube-ds-admin -n kube-system
```

通过 `token` 访问 `Dashboard` 后台

[安装 Kubernetes Dashboard](https://todoit.tech/k8s/dashboard/)
[Installing and Accessing Kubernetes-Dashboard Via Token](https://medium.com/@nikhil.nagarajappa/installing-and-accessing-kubernetes-dashboard-e1b14de3f5db)
[Use the TokenRequest API to create Tokens in Kubernetes 1.24](https://programmingwithwolfgang.com/use-the-tokenrequest-api-to-create-tokens-in-kubernetes/)