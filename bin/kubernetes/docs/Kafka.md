
# Kafka 持久化存储

```bash
helm repo add incubator http://mirror.azure.cn/kubernetes/charts-incubator/
helm repo update
```

********************************************************************************************************************************************************************************************************

```bash
kubectl create namespace kafka
```

```bash
kubectl apply -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka
```

```bash
kubectl apply -f https://strimzi.io/examples/latest/kafka/kafka-persistent-single.yaml -n kafka 
```

```bash
kubectl wait kafka/my-cluster --for=condition=Ready --timeout=300s -n kafka 
```

```bash
kubectl -n kafka run kafka-producer -ti --image=strimzi/kafka:0.20.0-kafka-2.6.0 --rm=true --restart=Never -- bin/kafka-console-producer.sh --broker-list my-cluster-kafka-bootstrap:9092 --topic my-topic
```

```bash
kubectl -n kafka run kafka-consumer -ti --image=strimzi/kafka:0.20.0-kafka-2.6.0 --rm=true --restart=Never -- bin/kafka-console-consumer.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 --topic my-topic --from-beginning
```



```bash

```

********************************************************************************************************************************************************************************************************

* 添加最新的官方源

* [New Location For Stable and Incubator Charts](https://helm.sh/blog/new-location-stable-incubator-charts/)

```bash
helm repo add stable https://charts.helm.sh/stable --force-update
helm repo add incubator https://charts.helm.sh/incubator --force-update
helm repo update
```

* 安装 Kafka 集群

```bash
helm install incubator/kafka
```

* 下载配置

```bash
curl https://raw.githubusercontent.com/helm/charts/master/incubator/kafka/values.yaml > kfk-values.yaml
```

********************************************************************************************************************************************************************************************************