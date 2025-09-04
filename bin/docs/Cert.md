# Certs 证书配置

## 部署完 k8s 集群后，执行 kubectl 命令查询集群资源报错

```bash
$ kubectl get po
E0826 09:55:42.166783   19048 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"https://183.162.211.229:6443/api?timeout=32s\": tls: failed to verify certificate: x509: certificate is valid for 10.233.0.1, 192.168.0.4, 127.0.0.1, not 183.162.211.229"
```

查询当前节点配置

```bash
$ openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 1 "Subject Alternative Name"
```

## 集群 `certSANs` 配置文件示例

配置文件 `/etc/kubernetes/kubeadm-config.yaml`

```yaml
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
clusterName: cluster.local
apiServer:
  certSANs:
  - "kubernetes"
  - "kubernetes.default"
  - "kubernetes.default.svc"
  - "kubernetes.default.svc.cluster.local"
  - "10.233.0.1"
  - "localhost"
  - "127.0.0.1"
  - "server-hf-4"
  - "lb-apiserver.kubernetes.local"
  - "0.hf.zsc.iirii.com"
  - "183.162.211.229"
  - "192.168.0.4"
  - "server-hf-4.cluster.local"
```