
# Traefik 管理工具

********************************************************************************************************************************************************************************************************

升级到 `v2.3` 后报错

```bash
Failed to list *v1beta1.IngressClass: ingressclasses.networking.k8s.io is forbidden: User "system:serviceaccount:coam-dev-traefik-ns:traefik-ingress-controller" cannot list resource "ingressclasses" in API group "networking.k8s.io" at the cluster scope
```

将 `ClusterRole` 中的这段

```bash
  - apiGroups:
      - extensions
    resources:
      - ingresses
    verbs:
      - get
      - list
      - watch
```

改为

```bash
 - apiGroups:
      - extensions
      - networking.k8s.io
    resources:
      - ingresses
      - ingressclasses
    verbs:
      - get
      - list
      - watch
```

[Getting `Failed to list *v1beta1.IngressClass: ingressclasses.networking.k8s.io` error with Traefikv2.3](https://stackoverflow.com/questions/63109422/getting-failed-to-list-v1beta1-ingressclass-ingressclasses-networking-k8s-io)

********************************************************************************************************************************************************************************************************
