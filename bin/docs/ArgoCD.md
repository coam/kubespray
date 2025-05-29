# ArgoCD 用法

## ArgoCLI 命令

```bash
brew install argocd
```

初始化 `admin` 账号密码(确保当前 `kubeconfig` 配置正确)

```bash
argocd admin initial-password -n argocd
```

登录

```bash
argocd login 1.cos.iirii.com:8443
```

## Argo 后台

暴露服务端口

```bash
kubectl port-forward --address 0.0.0.0 service/argocd-server -n argocd 8443:443
```

访问后台: https://148.135.125.157:8443/