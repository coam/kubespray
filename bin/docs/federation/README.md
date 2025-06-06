
# Federation 管理

********************************************************************************************************************************************************************************************************
## Federation 模式部署

[Federation](https://kubernetes.feisky.xyz/he-xin-yuan-li/index-1/federation)

1. kubefed 下载

* Linux

```bash
curl -LO https://storage.cloud.google.com/kubernetes-federation-release/release/v1.10.0-alpha.0/federation-client-linux-amd64.tar.gz
tar -xzvf federation-client-linux-amd64.tar.gz

sudo cp kubernetes/client/bin/kubefed /usr/local/bin
sudo chmod +x /usr/local/bin/kubefed
```

```bash
git clone https://github.com/kubernetes/federation.git
cd federation
make
```

```bash
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/kubernetes-client-linux-amd64.tar.gz
tar -xzvf kubernetes-client-linux-amd64.tar.gz
```

2. 初始化主集群

> 选择一个已部署好的 Kubernetes 集群作为主集群，作为集群联邦的控制平面，并配置好本地的 kubeconfig。然后运行 kubefed init 命令来初始化主集群：

```bash
$ kubefed init fellowship \
    --host-cluster-context=rivendell \   # 部署集群的 kubeconfig 配置名称
    --dns-provider="google-clouddns" \   # DNS 服务提供商，还支持 aws-route53 或 coredns
    --dns-zone-name="example.com." \     # 域名后缀，必须以. 结束
    --apiserver-enable-basic-auth=true \ # 开启 basic 认证
    --apiserver-enable-token-auth=true \ # 开启 token 认证
    --apiserver-arg-overrides="--anonymous-auth=false,--v=4" # federation API server 自定义参数
$ kubectl config use-context fellowship
```

********************************************************************************************************************************************************************************************************