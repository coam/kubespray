
# RabbitMQ 集群

[RabbitMQ Cluster Operator for Kubernetes](https://www.rabbitmq.com/kubernetes/operator/operator-overview.html#kubernetes-versions)
[Installing RabbitMQ Cluster Operator in a Kubernetes cluster](https://www.rabbitmq.com/kubernetes/operator/install-operator.html)
[Using RabbitMQ Cluster Kubernetes Operator](https://www.rabbitmq.com/kubernetes/operator/using-operator.html)

********************************************************************************************************************************************************************************************************

```bash
git clone git@github.com:rabbitmq/cluster-operator.git
cd cluster-operator
kubectl create -f config/namespace/base/namespace.yaml
kubectl create -f config/crd/bases/rabbitmq.com_rabbitmqclusters.yaml
kubectl -n rabbitmq-system create --kustomize config/rbac/
kubectl -n rabbitmq-system create --kustomize config/manager/
```

********************************************************************************************************************************************************************************************************