# OpenEBS 存储

## 使用 helm chart 部署 `openebs`

```bash
helm repo add openebs https://openebs.github.io/charts
helm repo update
helm install openebs --namespace openebs openebs/openebs --create-namespace
```

安装完后会默认创建两个 `openebs` sc:

```bash
Tue Dec 05 17:25:10 root@node1:~# kubectl get sc
NAME                      PROVISIONER                    RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
openebs-device            openebs.io/local               Delete          WaitForFirstConsumer   false                  61s
openebs-hostpath          openebs.io/local               Delete          WaitForFirstConsumer   false                  61s
```

## 参考

[Kubernetes使用 OpenEBS 实现 Local PV 动态持久化存储](https://www.sundayhk.com/post/openebs/)
[Helm 部署 OpenEBS LocalPV 作为伸缩存储](https://blog.csdn.net/xixihahalelehehe/article/details/129967490)