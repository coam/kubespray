# audit

[K8S开启/关闭审计日志](https://blog.csdn.net/m0_53683186/article/details/145156774)

## k8s 新增审计日志

新增配置文件 `/etc/kubernetes/audit-policy.yaml` 并添加以下内容

```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  - level: Request
```

修改主节点下的配置文件 `/etc/kubernetes/manifests/kube-apiserver.yaml`，增加以下配置

```yaml
spec:
  containers:
    - command:
        - --audit-policy-file=/etc/kubernetes/audit-policy.yaml
        - --audit-log-path=/var/log/kubernetes/audit/audit.log
      volumeMounts:
        - mountPath: /etc/kubernetes/audit-policy.yaml
          name: audit
          readOnly: true
        - mountPath: /var/log/kubernetes/audit/
          name: audit-log
          readOnly: false
  volumes:
    - name: audit
      hostPath:
        path: /etc/kubernetes/audit-policy.yaml
        type: File
    - name: audit-log
      hostPath:
        path: /var/log/kubernetes/audit/
        type: DirectoryOrCreate
```

配置完后会立即自动重启，或执行命令手动重启: `systemctl restart kubelet`

查看 `kube-apiserver` 服务日志

```bash
nerdctl ps -a | grep kube-apiserver
nerdctl logs -f <api-server-container-id>
```

最后查看审计日志 `/var/log/kubernetes/audit/audit.log`