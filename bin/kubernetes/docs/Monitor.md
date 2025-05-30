
# Kubernetes 监控

********************************************************************************************************************************************************************************************************

[kubernetes1.13集群监控方案](https://blog.csdn.net/fanren224/article/details/86610492)

[Prometheus监控Kubernetes系列1——监控框架](http://www.servicemesher.com/blog/prometheus-monitor-k8s-1)
[Prometheus监控Kubernetes系列2——监控部署](http://www.servicemesher.com/blog/prometheus-monitor-k8s-2)

* 有时间必读

[52. 在 Kubernets 中手动安装 Prometheus](https://www.qikqiak.com/k8s-book/docs/52.Prometheus基本使用.html)

## cAdvisor

```bash
kustomize build deploy/kubernetes/base
kustomize build deploy/kubernetes/overlays/examples
```

> 编译配置文件

```bash
kustomize build cadvisor/deploy/kubernetes/overlays/examples > k8s.030.cadvisor.cadvisor.yaml
kubectl apply -f k8s.030.cadvisor.cadvisor.yaml
```

## Metrics-server

```bash
kubectl apply  -f metrics-server/deploy/1.8+/
```

* 查看指标

```bash
kubectl top node
kubectl top pods --all-namespaces
```

* 通过命令行api请求

```bash
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods
```

* 通过接口

```bash
curl --insecure https://172.31.141.97:6443/apis/metrics.k8s.io/v1beta1/nodes
curl -k https://172.31.141.97:6443/apis/metrics.k8s.io/v1beta1/nodes
curl -k https://172.31.141.97:6443/apis/metrics.k8s.io/v1beta1/pods
```

## Prometheus

```bash
git clone https://github.com/coreos/kube-prometheus.git
kubectl apply -f kube-prometheus/manifests
```

```bash
$ kubectl get pod -n monitoring  -o wide
NAME                                   READY   STATUS    RESTARTS   AGE   IP              NODE     NOMINATED NODE   READINESS GATES
alertmanager-main-0                    2/2     Running   0          12m   10.244.0.88     a.us.1   <none>           <none>
alertmanager-main-1                    2/2     Running   3          12m   10.244.1.64     a.us.2   <none>           <none>
alertmanager-main-2                    2/2     Running   0          6m    10.244.1.70     a.us.2   <none>           <none>
grafana-b6bd6d987-qfrpt                1/1     Running   0          12m   10.244.1.199    a.us.2   <none>           <none>
kube-state-metrics-b5fb4c5cc-tlh5x     4/4     Running   0          11m   10.244.0.248    a.us.1   <none>           <none>
node-exporter-4rfm6                    2/2     Running   0          12m   172.31.141.98   a.us.2   <none>           <none>
node-exporter-qgstn                    2/2     Running   0          12m   172.31.141.97   a.us.1   <none>           <none>
prometheus-adapter-57c497c557-l7w8c    1/1     Running   0          12m   10.244.1.107    a.us.2   <none>           <none>
prometheus-k8s-0                       3/3     Running   1          12m   10.244.1.168    a.us.2   <none>           <none>
prometheus-k8s-1                       3/3     Running   1          12m   10.244.0.34     a.us.1   <none>           <none>
prometheus-operator-747d7b67dc-57ssk   1/1     Running   0          13m   10.244.0.166    a.us.1   <none>           <none>
```

### 修改访问方式,通过 `NodePort` 开放服务

```bash
kube-prometheus/manifests/grafana-service.yaml
kube-prometheus/manifests/prometheus-service.yaml
kube-prometheus/manifests/alertmanager-service.yaml
```

### 查看后台

* Grafana

```bash
http://os.iirii.com:30100
```

> 用户名密码默认admin/admin

* Prometheus

```bash
http://os.iirii.com:30200/metrics
http://os.iirii.com:30200/graph
```

> prometheus的WEB界面上提供了基本的查询K8S集群中每个POD的CPU使用情况，查询条件如下：

```bash
sum by (pod_name)(rate(container_cpu_usage_seconds_total{image!="", pod_name!=""}[1m]))
```

* alert-manager

```bash
http://os.iirii.com:30300
```

********************************************************************************************************************************************************************************************************

## 使用 `weave scope`

[Monitoring, visualisation & management for Docker & Kubernetes](https://www.weave.works/oss/scope/)

* 安装

```bash
git clone https://github.com/weaveworks/scope
kubectl apply -f weaveworks/scope/examples/k8s
```

* 调整服务访问模式为 `NodePort`

```bash
...
```

* 访问后台

```bash
http://os.iirii.com:30400/
```

********************************************************************************************************************************************************************************************************
