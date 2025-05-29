
# Istio 服务网格

* 参考博客文章

[Kubernetes Istio微服务架构部署和使用](https://xuchao918.github.io/2019/03/01/Kubernetes-Istio微服务架构部署和使用/)
[K8S训练营](https://www.qikqiak.com/k8strain/istio/install/)

********************************************************************************************************************************************************************************************************

### 根据系统下载对应版本

```bash
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.6.7 sh -
```

或者手动下载对应版本,解压

```bash
wget https://github.com/istio/istio/releases/download/1.6.7/istio-1.6.7-linux.tar.gz
wget https://github.com/istio/istio/releases/download/1.6.7/istio-1.6.7-osx.tar.gz
```

解压缩后的目录结构如下:

[/data/home/coam/Run/runs/kubernetes/src/istio-1.6.7]
```bash
$ tree . -L 2
.
├── LICENSE
├── README.md
├── bin
│   └── istioctl
├── manifest.yaml
├── manifests
│   ├── charts
│   ├── deploy
│   ├── examples
│   ├── profiles
│   ├── translateConfig
│   └── versions.yaml
├── samples
│   ├── README.md
│   ├── addons
│   ├── bookinfo
│   ├── certs
│   ├── custom-bootstrap
│   ├── external
│   ├── fortio
│   ├── health-check
│   ├── helloworld
│   ├── httpbin
│   ├── https
│   ├── kubernetes-blog
│   ├── multicluster
│   ├── operator
│   ├── rawvm
│   ├── security
│   ├── sleep
│   ├── tcp-echo
│   └── websockets
└── tools
    ├── _istioctl
    ├── certs
    ├── convert_RbacConfig_to_ClusterRbacConfig.sh
    ├── dump_kubernetes.sh
    └── istioctl.bash
```

* 其中 `install/kubernetes` 目录中包含了在 `k8s` 集群上部署 `Istio` 的 `.yaml` 文件
* `bin` 目录中的 `istioctl` 是 `istio` 的客户端文件，用来手动将 `Envoy` 作为 `sidecar proxy` 注入，以及对路由规则和策略的管理

将 `istioctl` 加入到 `PATH` 环境变量，这里直接将其拷贝到 `/usr/local/bin` 下.

```bash
export PATH=$PWD/bin:$PATH
```

[/data/home/coam/Run/runs/kubernetes/src/istio-1.6.7]
```bash
$ cp bin/istioctl /usr/local/bin
$ istioctl version
client version: 1.6.7
control plane version: 1.6.7
data plane version: 1.6.7 (3 proxies)
```

部署官方 `demo` 配置

```bash
$ istioctl install --set profile=demo
✔ Istio core installed
✔ Istiod installed
✔ Egress gateways installed
✔ Ingress gateways installed
✔ Addons installed
✔ Installation complete
```

查看 `Pods`

```bash
$ kubectl get pods -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
grafana-b54bb57b9-f9lbj                 1/1     Running   0          20h
istio-egressgateway-64bc874f5c-p4ftt    1/1     Running   0          20h
istio-ingressgateway-6b947b8c5d-xcc2k   1/1     Running   0          20h
istio-tracing-9dd6c4f7c-zksr7           1/1     Running   0          20h
istiod-654b4b468b-gx87j                 1/1     Running   0          20h
kiali-d45468dc4-69sw6                   1/1     Running   0          20h
prometheus-77566c9987-29xtw             2/2     Running   0          20h
```

设置默认 `default` 命名空间自动注入

```bash
kubectl label namespace default istio-injection=enabled
```

********************************************************************************************************************************************************************************************************

********************************************************************************************************************************************************************************************************

### 服务网格 `istio` 部署

## 安装方案

[Istio 1.0学习笔记(一):在Kubernetes安装Istio](https://blog.frognew.com/2018/08/learning-istio-1.0-1.html)

### 使用 Helm 进行安装 -- 推荐

### 下载发布包

```bash
wget https://github.com/istio/istio/releases/download/1.3.3/istio-1.3.3-linux.tar.gz
tar -zxvf istio-1.3.3-linux.tar.gz
```

### 创建命名空间

```bash
kubectl create namespace istio-system
```

### 安装 `istio` 的 `CRD`

安装 `istio` 的 `CRD(Custom Resource Definitions)`，并等待一段时间 `CRDs` 将被提交到 `kube-apiserver` 中:

[runs/kubernetes/src/istio-1.3.3]
```bash
helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
```

查看安装的 `CRD`:

```bash
kubectl get CustomResourceDefinition
```

验证安装

```bash
$ kubectl get crds | grep 'istio.io' | wc -l
23
```

### 安装 `Istio` 的核心组件

安装 `istio-cni`

[runs/kubernetes/src/istio-1.3.3]
```bash
helm template install/kubernetes/helm/istio-cni --name=istio-cni --namespace=kube-system | kubectl apply -f -
```

安装 `istio`

[runs/kubernetes/src/istio-1.3.3]
```bash
helm template install/kubernetes/helm/istio --name istio --namespace istio-system --set istio_cni.enabled=true | kubectl apply -f -
```

附完整安装组件

```bash
poddisruptionbudget.policy/istio-galley created
poddisruptionbudget.policy/istio-ingressgateway created
poddisruptionbudget.policy/istio-policy created
poddisruptionbudget.policy/istio-telemetry created
poddisruptionbudget.policy/istio-pilot created
poddisruptionbudget.policy/istio-sidecar-injector created
configmap/istio-galley-configuration created
configmap/prometheus created
configmap/istio-security-custom-resources created
configmap/istio created
configmap/istio-sidecar-injector created
serviceaccount/istio-galley-service-account created
serviceaccount/istio-ingressgateway-service-account created
serviceaccount/istio-mixer-service-account created
serviceaccount/istio-pilot-service-account created
serviceaccount/prometheus created
serviceaccount/istio-security-post-install-account created
clusterrole.rbac.authorization.k8s.io/istio-security-post-install-istio-system created
clusterrolebinding.rbac.authorization.k8s.io/istio-security-post-install-role-binding-istio-system created
job.batch/istio-security-post-install-1.3.3 created
serviceaccount/istio-citadel-service-account created
serviceaccount/istio-sidecar-injector-service-account created
serviceaccount/istio-multi created
clusterrole.rbac.authorization.k8s.io/istio-galley-istio-system created
clusterrole.rbac.authorization.k8s.io/istio-mixer-istio-system created
clusterrole.rbac.authorization.k8s.io/istio-pilot-istio-system created
clusterrole.rbac.authorization.k8s.io/prometheus-istio-system created
clusterrole.rbac.authorization.k8s.io/istio-citadel-istio-system created
clusterrole.rbac.authorization.k8s.io/istio-sidecar-injector-istio-system created
clusterrole.rbac.authorization.k8s.io/istio-reader created
clusterrolebinding.rbac.authorization.k8s.io/istio-galley-admin-role-binding-istio-system created
clusterrolebinding.rbac.authorization.k8s.io/istio-mixer-admin-role-binding-istio-system created
clusterrolebinding.rbac.authorization.k8s.io/istio-pilot-istio-system created
clusterrolebinding.rbac.authorization.k8s.io/prometheus-istio-system created
clusterrolebinding.rbac.authorization.k8s.io/istio-citadel-istio-system created
clusterrolebinding.rbac.authorization.k8s.io/istio-sidecar-injector-admin-role-binding-istio-system created
clusterrolebinding.rbac.authorization.k8s.io/istio-multi created
role.rbac.authorization.k8s.io/istio-ingressgateway-sds created
rolebinding.rbac.authorization.k8s.io/istio-ingressgateway-sds created
service/istio-galley created
service/istio-ingressgateway created
service/istio-policy created
service/istio-telemetry created
service/istio-pilot created
service/prometheus created
service/istio-citadel created
service/istio-sidecar-injector created
deployment.apps/istio-galley created
deployment.apps/istio-ingressgateway created
deployment.apps/istio-policy created
deployment.apps/istio-telemetry created
deployment.apps/istio-pilot created
deployment.apps/prometheus created
deployment.apps/istio-citadel created
deployment.apps/istio-sidecar-injector created
horizontalpodautoscaler.autoscaling/istio-ingressgateway created
horizontalpodautoscaler.autoscaling/istio-policy created
horizontalpodautoscaler.autoscaling/istio-telemetry created
horizontalpodautoscaler.autoscaling/istio-pilot created
mutatingwebhookconfiguration.admissionregistration.k8s.io/istio-sidecar-injector created
attributemanifest.config.istio.io/istioproxy created
attributemanifest.config.istio.io/kubernetes created
instance.config.istio.io/requestcount created
instance.config.istio.io/requestduration created
instance.config.istio.io/requestsize created
instance.config.istio.io/responsesize created
instance.config.istio.io/tcpbytesent created
instance.config.istio.io/tcpbytereceived created
instance.config.istio.io/tcpconnectionsopened created
instance.config.istio.io/tcpconnectionsclosed created
handler.config.istio.io/prometheus created
rule.config.istio.io/promhttp created
rule.config.istio.io/promtcp created
rule.config.istio.io/promtcpconnectionopen created
rule.config.istio.io/promtcpconnectionclosed created
handler.config.istio.io/kubernetesenv created
rule.config.istio.io/kubeattrgenrulerule created
rule.config.istio.io/tcpkubeattrgenrulerule created
instance.config.istio.io/attributes created
destinationrule.networking.istio.io/istio-policy created
destinationrule.networking.istio.io/istio-telemetry created
```

### 验证安装

确认 `istio` 相关的 `Service` 已经部署:

```bash
$ kubectl get svc -n istio-system
NAME                     TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                                                                                  AGE     SELECTOR
istio-citadel            ClusterIP      10.103.199.118   <none>        8060/TCP,15014/TCP                                                                                                                       2m32s   istio=citadel
istio-galley             ClusterIP      10.108.34.131    <none>        443/TCP,15014/TCP,9901/TCP                                                                                                               2m32s   istio=galley
istio-ingressgateway     LoadBalancer   10.104.170.59    <pending>     15020:32952/TCP,80:31380/TCP,443:31390/TCP,31400:31400/TCP,15029:14644/TCP,15030:944/TCP,15031:24317/TCP,15032:6295/TCP,15443:5128/TCP   2m32s   app=istio-ingressgateway,istio=ingressgateway,release=istio
istio-pilot              ClusterIP      10.109.79.228    <none>        15010/TCP,15011/TCP,8080/TCP,15014/TCP                                                                                                   2m32s   istio=pilot
istio-policy             ClusterIP      10.107.119.171   <none>        9091/TCP,15004/TCP,15014/TCP                                                                                                             2m32s   istio-mixer-type=policy,istio=mixer
istio-sidecar-injector   ClusterIP      10.109.117.224   <none>        443/TCP,15014/TCP                                                                                                                        2m32s   istio=sidecar-injector
istio-telemetry          ClusterIP      10.104.54.26     <none>        9091/TCP,15004/TCP,15014/TCP,42422/TCP                                                                                                   2m32s   istio-mixer-type=telemetry,istio=mixer
prometheus               ClusterIP      10.101.76.232    <none>        9090/TCP                                                                                                                                 2m32s   app=prometheus
```

保证所有 `istio-system` 相关 `Pods` 的状态 `Running`:

```bash
$ kubectl get pods -n istio-system
NAME                                      READY   STATUS      RESTARTS   AGE     IP             NODE     NOMINATED NODE   READINESS GATES
istio-citadel-67f6594c46-8nf5f            1/1     Running     0          2m55s   10.244.1.192   a.us.2   <none>           <none>
istio-galley-6c7fcf86d4-dcwk7             1/1     Running     0          2m56s   10.244.1.44    a.us.2   <none>           <none>
istio-ingressgateway-6d68548679-lvrv5     1/1     Running     0          2m56s   10.244.1.60    a.us.2   <none>           <none>
istio-init-crd-10-1.3.3-lc9gd             0/1     Completed   0          6m18s   10.244.1.133   a.us.2   <none>           <none>
istio-init-crd-11-1.3.3-9t6zw             0/1     Completed   0          6m18s   10.244.1.100   a.us.2   <none>           <none>
istio-init-crd-12-1.3.3-rgbf2             0/1     Completed   0          6m18s   10.244.1.170   a.us.2   <none>           <none>
istio-pilot-789d4748b-zrswv               2/2     Running     0          2m55s   10.244.0.56    a.us.1   <none>           <none>
istio-policy-59d8f8c9f8-254wf             2/2     Running     2          2m56s   10.244.1.228   a.us.2   <none>           <none>
istio-security-post-install-1.3.3-kbqfb   0/1     Completed   0          2m56s   10.244.1.188   a.us.2   <none>           <none>
istio-sidecar-injector-6d967869b5-8sqjs   1/1     Running     0          2m55s   10.244.1.144   a.us.2   <none>           <none>
istio-telemetry-646f74c6bf-5xvlt          2/2     Running     2          2m55s   10.244.1.23    a.us.2   <none>           <none>
prometheus-6f74d6f76d-hv4lm               1/1     Running     0          2m55s   10.244.1.246   a.us.2   <none>           <none>
```

### 卸载删除

[runs/kubernetes/src/istio-1.3.3]
```bash
helm template install/kubernetes/helm/istio --name istio --namespace istio-system --set istio_cni.enabled=true | kubectl delete -f -
helm template install/kubernetes/helm/istio-cni --name=istio-cni --namespace=kube-system | kubectl delete -f -
kubectl delete -f install/kubernetes/helm/istio-init/files
kubectl delete namespace istio-system
```

********************************************************************************************************************************************************************************************************

## `Istio` 升级

* 下载代码

```bash
wget https://github.com/istio/istio/releases/download/1.3.3/istio-1.3.3-linux.tar.gz
tar -zxvf istio-1.3.3-linux.tar.gz
```

### Istio `CNI` upgrade

首先检查 `istio-cni` 是否安装,检查名字为 `istio-cni-node` 的 `pods`:

```bash
$ kubectl get pods -l k8s-app=istio-cni-node --all-namespaces
No resources found
```

在 `kube-system` 命名空间安装 `istio-cni`:

[runs/kubernetes/src/istio-1.3.3]
```bash
$ helm template install/kubernetes/helm/istio-cni --name=istio-cni --namespace=kube-system | kubectl apply -f -
clusterrole.rbac.authorization.k8s.io/istio-cni created
clusterrolebinding.rbac.authorization.k8s.io/istio-cni created
configmap/istio-cni-config created
daemonset.apps/istio-cni-node created
serviceaccount/istio-cni created
```

再次检查:

[runs/kubernetes/src]
```bash
$ kubectl get pods -l k8s-app=istio-cni-node --all-namespaces
NAMESPACE     NAME                   READY   STATUS    RESTARTS   AGE
kube-system   istio-cni-node-ckzgg   1/1     Running   0          63s
kube-system   istio-cni-node-npqsx   1/1     Running   0          63s
```

### 控制平面升级

* 执行编译文件

[runs/kubernetes/src/istio-1.3.3]
```bash
$ helm upgrade --install istio-init install/kubernetes/helm/istio-init --namespace istio-system
```

查看 `CRD` 量:

```bash
$ kubectl get crds | grep 'istio.io' | wc -l
23
```

升级 `istio` 数量:

```bash
$ helm upgrade istio install/kubernetes/helm/istio --namespace istio-system --set istio_cni.enabled=true
```

### `Sidecar` 升级

> 控制平面升级后，已经运行 `Istio` 的应用程序仍将使用旧版本的 `sidecar`。要想升级 `sidecar`，您需要重新注入它。

重启 `Pod` 即可

```bash
$ kubectl replace --force -f k8s.080.coam-dev-php-ns.us-rpc.yaml
```

* 通过以下命令验证:

```bash
$ kubectl -n coam-dev-php-ns get pod rpc-deployment-6f78f6464b-wcgst -o jsonpath='{.spec.containers[?(@.name=="istio-proxy")].image}'
docker.io/istio/proxyv2:1.3.3
```

********************************************************************************************************************************************************************************************************

## 常用命令

```bash
kubectl get svc istio-coamgateway -n istio-system
```

```bash
export SOURCE_POD=$(kubectl get pod -l app=sleep,version=v1 -o jsonpath={.items..metadata.name})
kubectl exec -it -c sleep $SOURCE_POD bash
for i in `seq 100`;do http --body http://flaskapp/fetch?url=http://flaskapp/env/version >> /dev/null;done
for i in `seq 100`;do http --body http://flaskapp/fetch?url=http://flaskapp/env/version;done
for i in `seq 100`;do http --debug http://flaskapp/fetch_with_header?url=http://httpbin:8000/get;done
for i in `seq 100`;do http http://flaskapp/fetch_with_trace?url=http://httpbin:8000/ip;done
for i in `seq 100`;do http http://flaskapp/fetch_with_header?url=http://httpbin:8000/ip;done
http --body http://flaskapp/env/version
```

* http 流量权重

```bash
for i in `seq 10`;do http --body http://flaskapp/env/version;done | awk -F"v1" '{print NF-1}'
```

* 金丝雀部署

```bash
for i in `seq 10`;do http --body http://flaskapp/env/version;done
for i in `seq 10`;do http --body http://flaskapp/env/version lab:canary;done
```

* 跟随 `301` 跳转

```bash
http --follow http://flaskapp/env/HOSTNAME
```

* post 请求

```bash
http -f POST http://httpbin:8000/post data=nothing
```

* 超时

```bash
http --body http://httpbin:8000/delay/2
```

* 返回500

```bash
http --body http://httpbin:8000/status/500
```

### 开放管理工具

[Istio 1.0学习笔记(一):在Kubernetes安装Istio](https://blog.frognew.com/2018/08/learning-istio-1.0-1.html)

* Grafana

[Grafana](http://os.iirii.com:32191)
[Grafana](https://grafana-istio-k8s.iirii.com/grafana)

* Prometheus

[Prometheus](http://os.iirii.com:32090)
[Prometheus](https://prometheus-istio-k8s.iirii.com/graph)

> 几个指标: `istio_request_total`、`grpc_server_handled_total`

* Jaeger

[Jaeger 后台](https://tracing-istio-k8s.iirii.com/jaeger)

* Kiali

[Kiali 后台](https://kiali-istio-k8s.iirii.com/kiali)

********************************************************************************************************************************************************************************************************

## 部署 `bookinfo` 示例

```bash
istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo.yaml > samples/bookinfo/platform/kube/bookinfo-inject.yaml
kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo-inject.yaml)
```

********************************************************************************************************************************************************************************************************

## `Istio` 随书代码

[《深入浅出 Istio》读后感](http://www.servicemesher.com/blog/reading-istio-service-mesh-book/)

```bash
for i in `seq 100`;do http --body http://flaskapp/env/version;done
```

********************************************************************************************************************************************************************************************************

## 常见问题

### `Mysql` 在外网连接不上

* [安全方面的常见问题](https://istio.io/zh/help/faq/security/#mysql-with-mtls)
* [Istio blocking connection to MySQL](https://stackoverflow.com/questions/53947015/istio-blocking-connection-to-mysql)

```bash
#kubectl describe meshpolicies.authentication.istio.io default
#kubectl delete meshpolicies.authentication.istio.io default
```

********************************************************************************************************************************************************************************************************