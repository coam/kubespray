
## metrics-server

[metrics-server](https://github.com/kubernetes-sigs/metrics-server)

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.7/components.yaml
```

[~/Run/runs/kubernetes/coam]
```bash
wget https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.7/components.yaml -O k8s.metrics-server.yaml
```

[~/Run/runs/kubernetes/coam]
```bash
kubectl apply -f k8s.metrics-server.yaml
```

查看指标

```bash
kubectl top pods
kubectl top nodes
```

一直出现问题

```bash
$ kubectl top pods
W1012 22:32:13.140641 1146302 top_pod.go:274] Metrics not available for pod default/nfs-client-provisioner-5b8cc46fbf-6gcr9, age: 5h41m48.140631438s
error: Metrics not available for pod default/nfs-client-provisioner-5b8cc46fbf-6gcr9, age: 5h41m48.140631438s
$ kubectl top nodes
error: metrics not available yet
```

增加以下配置,并等几分钟再看

[~/Run/runs/kubernetes/coam/k8s.metrics-server.yaml]
```bash
--logtostderr
--kubelet-insecure-tls=true
--kubelet-preferred-address-types=InternalIP
```

并结合日志排查问题

```bash
kube logs metrics-server-57bbc856f8-vjzlp
```

用到的命令

```bash
kubectl top nodes
kubectl top pod
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/pods"
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes"
```

[Kubernetes1.16集群中部署指标服务遇见的坑](https://www.netmesh.cn/posts/k8s/%E9%9B%86%E7%BE%A4%E6%A0%B8%E5%BF%83%E6%8C%87%E6%A0%87%E6%9C%8D%E5%8A%A1/)
[从 Metric Server 到 Kubelet 服务证书](https://blog.fleeto.us/post/from-metric-server/)