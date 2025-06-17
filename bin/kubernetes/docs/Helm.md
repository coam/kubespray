
# Helm 工具

* 参考博客文章

********************************************************************************************************************************************************************************************************

# Helm 安装管理 - kubernetes 的包管理器

[快速安装 Helm](https://imroc.io/posts/kubernetes/install-helm/)

> `Helm`` 是 `Kubernetes` 的包管理器，可以帮我们简化 `kubernetes` 的操作，一键部署应用。假如你的机器上已经安装了 `kubectl` 并且能够操作集群，那么你就可以安装 `Helm` 了。

### 执行脚本安装 `helm` 客户端:

```bash
$ curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  7028  100  7028    0     0   326k      0 --:--:-- --:--:-- --:--:--  326k
Downloading https://kubernetes-helm.storage.googleapis.com/helm-v2.13.1-linux-amd64.tar.gz
Preparing to install helm and tiller into /usr/local/bin
[sudo] password for coam:
helm installed into /usr/local/bin/helm
tiller installed into /usr/local/bin/tiller
Run 'helm init' to configure helm.
```

### 安装 `tiller` 服务端到 `kubernetes` 集群:

```bash
$ helm init --upgrade
Creating /data/home/coam/.helm
Creating /data/home/coam/.helm/repository
Creating /data/home/coam/.helm/repository/cache
Creating /data/home/coam/.helm/repository/local
Creating /data/home/coam/.helm/plugins
Creating /data/home/coam/.helm/starters
Creating /data/home/coam/.helm/cache/archive
Creating /data/home/coam/.helm/repository/repositories.yaml
Adding stable repo with URL: https://kubernetes-charts.storage.googleapis.com
Adding local repo with URL: http://127.0.0.1:8879/charts
$HELM_HOME has been configured at /data/home/coam/.helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
To prevent this, run `helm init` with the --tiller-tls-verify flag.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
Happy Helming!
```

* 校验客户端版本:

```bash
$ helm version
Client: &version.Version{SemVer:"v2.13.1", GitCommit:"618447cbf203d147601b4b9bd7f8c37a5d39fbb4", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.13.1", GitCommit:"618447cbf203d147601b4b9bd7f8c37a5d39fbb4", GitTreeState:"clean"}
```

* 查看 `tiller` 是否启动成功:

```bash
$ kubectl get pods --namespace=kube-system | grep tiller
tiller-deploy-c48485567-mfgfv          1/1     Running   0          118s
```

默认安装的 `tiller` 权限很小，我们执行下面的脚本给它加最大权限，这样方便我们可以用 `helm` 部署应用到任意 `namespace` 下:

```bash
kubectl create serviceaccount --namespace=kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace=kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
```

********************************************************************************************************************************************************************************************************