#!/bin/bash

# [kubernetes] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

echo "Kubernetes - Dashboard 访问 Token:"
#kubectl describe secrets $(kubectl get secrets --namespace kube-system | grep admin-coam-serviceaccount-token | awk '{print $1}') --namespace kube-system | grep token: | awk '{print $2}'
#echo "[Kubernetes - Dashboard](https://ms.ioros.com:30443)";
kubectl describe secrets $(kubectl get secrets --namespace kubernetes-dashboard | grep kubernetes-dashboard-token | awk '{print $1}') --namespace kubernetes-dashboard | grep token: | awk '{print $2}'
echo "[Kubernetes - Dashboard](https://dashboard.kubernetes.ioros.com)"
echo "[Kubernetes - Metrics](https://metrics.kubernetes.ioros.com)"

echo "[Traefik - Dashboard]相关"
#echo "[Traefik - Dashboard](http://ms.iirii.com:30888)"
echo "[Traefik - Dashboard](https://dashboard.traefik.ioros.com)"

echo "Istio 相关"
echo "[Istio - Kiali](https://kiali.istio.kubernetes.ioros.com/kiali)"
echo "[Istio - Jaeger](https://tracing.istio.kubernetes.ioros.com/jaeger)"
echo "[Istio - Prometheus](https://prometheus.istio.kubernetes.ioros.com/graph)"
echo "[Istio - Grafana](http://ms.ioros.com:$(kubectl get service/grafana -n istio-system -o jsonpath={.spec.ports..nodePort}))"

echo "Jenkins 相关"
echo "[Jenkins - Dashboard](https://jenkins.ioros.com)"

echo "Harbor 相关"
echo "[Harbor - Registry](https://registry.ioros.com)"
echo "[Harbor - Repository](https://repository.ioros.com)"

echo "监控相关"

#echo "Prometheus 监控相关"
#echo "[Prometheus - Grafana](http://ms.ioros.com:30100)";
#echo "[Prometheus - Metrics](http://ms.ioros.com:30200/metrics)";
#echo "[Prometheus - Graph](http://ms.ioros.com:30200/graph)";
#echo "[Prometheus - AlertManager](http://ms.ioros.com:30300)";

#echo "Weave-Scope 监控相关"
#echo "[Weave - Scope](http://ms.ioros.com:30400)";

#echo "Rook 分布式存储相关"
#echo "[Rook - Ceph 后台](https://ms.ioros.com:30543)";
#echo "登录[账号: admin][密码: $(kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o yaml | grep "password:" | awk '{print $2}' | base64 --decode)]"

#echo "Rook 分布式存储测试相关"
#echo "[Rook - WordPress](http://ms.ioros.com:30480)";

echo "RabbitMQ 相关"
echo "[RabbitMQ - 后台管理](http://ms.ioros.com:15672) 用户名: admin 密码: admin"

echo "EMQX 相关"
echo "[EMQX - 后台管理](http://ms.ioros.com:30083) 用户名: admin 密码: public"

echo "Ejabberd 相关"
echo "[Ejabberd - 后台管理](https://ms.ioros.com:5280/admin) 用户名: zyf@nocs.cn 密码: 123456"

echo "ELK 相关"
echo "[ELK - ES接口](curl http://ms.ioros.com:9200) - 不推荐"
echo "[ELK - 后台管理](http://ms.ioros.com:5601) - 不推荐"
echo "[ELK - ES接口](curl https://es.ioros.com)"
echo "[ELK - 后台管理](https://kibana.ioros.com)"

echo "其它相关测试页面:..."
echo "[](https://ap.nocs.cn/account/adminListPaginate)"
echo "[](http://wsa.pyios.com/index.php)"
echo "[](http://wsa.pyios.com/index.html)"

echo "博客文档:..."
echo "[Docs](https://www.ioros.com)"

# [Ended] @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
