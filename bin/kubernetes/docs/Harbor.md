
# Istio 服务网格

* 参考博客文章

[](http://charts.ost.ai/)
[国内的 Helm 镜像源](https://www.chenshaowen.com/blog/configure-helm-mirror-in-china.html)

[使用Helm安装harbor到Kubernates集群](http://jaychang.cn/2019/07/14/ntitled/)
[使用 Helm 在 Kubernetes 集群中安装 Harbor](https://blog.etby.org/2020/04/28/k8s-install-harbor/)

********************************************************************************************************************************************************************************************************

查看镜像源

```bash
helm repo list
```

添加仓库源

```bash
sudo helm repo add harbor https://helm.goharbor.io
```

更新包信息

```bash
sudo helm repo update
```

搜索包

```bash
helm search repo harbor
```

导出 `harbor/harbor` 配置

[/data/home/coam/Run/runs/kubernetes/docs]
```bash
sudo helm inspect values harbor/harbor > /data/home/coam/Run/runs/System/etc/harbor/origin.yaml
```

拉取指定版本包

```bash
helm pull harbor/harbor --version 1.4.1
```

安装包

```bash
mkdir -p /home/scanner/.cache/trivy
mkdir -p /home/scanner/.cache/reports
chmod o+w /home/scanner/.cache/trivy
chmod o+w /home/scanner/.cache/reports
```

```bash
kubectl create namespace coam-dev-harbor-ns
kubectl delete secret coam-harbor-acme-iirii.com-tls -n coam-dev-harbor-ns
kubectl create secret tls coam-harbor-acme-iirii.com-tls --cert=/etc/ssl/coam/domains/iirii.com/fullchain.crt --key=/etc/ssl/coam/domains/iirii.com/private.key -n coam-dev-harbor-ns
helm install corn harbor/harbor -f /data/home/coam/Run/runs/System/etc/harbor/origin.yaml --namespace coam-dev-harbor-ns
```

查看已部署服务

```bash
helm ls
helm ls --namespaces coam-dev-harbor-ns
helm ls --all-namespaces
```

卸载

```bash
helm uninstall corn --namespace coam-dev-harbor-ns
kubectl delete --namespace coam-dev-harbor-ns --all pvc
```

#helm install --name coam-hb --set rbac.create=true harbor/harbor --namespace coam-dev-harbor-ns

[That's because you don't have the permission to deploy tiller, add an account for it:](https://github.com/helm/helm/issues/3130)

********************************************************************************************************************************************************************************************************