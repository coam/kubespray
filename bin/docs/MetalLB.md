# MetalLB 集群部署指南

## 部署准备

[k8s系列06-负载均衡器之MatelLB](https://tinychen.com/20220519-k8s-06-loadbalancer-metallb/)
[Kubernetes网络篇——ExternalIP和NodePort](https://morningspace.github.io/tech/k8s-net-externalip-nodeport/)

### 修改 `kube-proxy` 中的 `strictARP` 配置

#### 查看 kube-proxy 中的 strictARP 配置

```bash
$ kubectl get configmap -n kube-system kube-proxy -o yaml | grep strictARP
      strictARP: false
```

#### 手动修改 `strictARP` 配置为 `true`

```bash
$ kubectl edit configmap -n kube-system kube-proxy
configmap/kube-proxy edited
```

#### 使用命令直接修改并对比不同

```bash
$ kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl diff -f - -n kube-system
```

#### 确认无误后使用命令直接修改并生效

```bash
$ kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl apply -f - -n kube-system
```

#### 重启 `kube-proxy` 确保配置生效

```bash
$ kubectl rollout restart ds kube-proxy -n kube-system
```

#### 确认配置生效

```bash
$ kubectl get configmap -n kube-system kube-proxy -o yaml | grep strictARP
      strictARP: true
```