
# Persistent 持久化存储

## 准备工作

安装 `NFS` 服务器

* 参考 [创建 NFS 存储](NFS.md)

********************************************************************************************************************************************************************************************************

## PV

创建 `PV` 并指定 `NFS` 地址路径

[~/Run/runs/kubernetes/coam/k8s.run.yaml]
```bash
apiVersion: v1
kind: PersistentVolume
metadata:
  name:  pv1
spec:
  capacity: 
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    path: /data/k8s
    server: os.iirii.com
```

查看 `PV` 状态

```bash
 kubectl get pv
NAME   CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
pv1    1Gi        RWO            Recycle          Available                                   4s
```

可以看到当前 `pv-nfs` 是在 `Available` 的一个状态

********************************************************************************************************************************************************************************************************

## PVC

上面我们使用 `NFS` 创建 `PV` 持久化存储卷，但是在我们真正使用的时候是使用的 `PVC`，就类似于我们的服务是通过 `Pod` 来运行的，而不是 `Node`，只是 `Pod` 跑在 `Node` 上而已

我们需要在所有节点安装 `nfs` 客户端程序，安装方法和上节课的安装方法一样的。必须在所有节点都安装 `nfs` 客户端，否则可能会导致 `PV` 挂载不上的问题

[t.cs.1]
```bash
sudo yum -y install nfs-utils rpcbind
```

创建一个 `PVC` 存储声明

[~/Run/runs/kubernetes/coam/k8s.run.yaml]
```bash
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc-nfs
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

查看 `PVC` 状态

```bash
kubectl get pvc
NAME      STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-nfs   Bound    pv1      1Gi        RWO                           23s
```

所以这个时候我们的 `PVC` 可以和这个 `PV` 进行绑定了

```bash
kubectl get pv
NAME   CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS   REASON   AGE
pv1    1Gi        RWO            Recycle          Bound    default/pvc-nfs                           5m33s
```

绑定后可以看到 `PV` 已经从 `Available` 变成 `Bound` 状态了，对应的声明是 `default/pvc-nfs`，
就是 `default` 命名空间下面的 `pvc-nfs`，证明我们刚刚新建的 `pvc-nfs` 和我们的 `pv-nfs` 绑定成功了。

以上我们并没有在 `pvc-nfs` 中指定关于 `pv` 的什么标志，系统会自动帮我们去匹配的，他会根据我们的声明要求去查找处于 `Available` 状态的 `PV`，
如果没有找到的话那么我们的 `PVC` 就会一直处于 `Pending` 状态，找到了的话当然就会把当前的 `PVC` 和目标 `PV` 进行绑定，这个时候状态就会变成 `Bound` 状态了。

### 使用 PVC

[~/Run/runs/kubernetes/coam/k8s.run.yaml]
```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-pvc
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nfs-pvc
  template:
    metadata:
      labels:
        app: nfs-pvc
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
      volumes:
      - name: www
        persistentVolumeClaim:
          claimName: pvc-nfs

---
apiVersion: v1
kind: Service
metadata:
  name: nfs-pvc
  labels:
    app: nfs-pvc
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: web
    nodePort: 31123
  selector:
    app: nfs-pvc
```

我们这里使用 `nginx` 镜像，将容器的 `/usr/share/nginx/html` 目录通过 `volume` 挂载到名为 `pvc2-nfs` 的 `PVC` 上面，然后创建一个 `NodePort` 类型的 `Service` 来暴露服务：

我们可以看到,`k8s` 已经在三台主机启动三个副本集: `nfs-pvc-588c7b9b5d`

```bash
$ kubectl get pod -o wide
NAME                       READY   STATUS    RESTARTS   AGE    IP           NODE     NOMINATED NODE   READINESS GATES
nfs-pvc-588c7b9b5d-5vfrv   1/1     Running   0          105s   10.0.2.62    t.cs.1   <none>           <none>
nfs-pvc-588c7b9b5d-6hlm2   1/1     Running   0          105s   10.0.1.71    t.cs.2   <none>           <none>
nfs-pvc-588c7b9b5d-xlll9   1/1     Running   0          105s   10.0.0.246   t.cs.3   <none>           <none>
```

我们通过任意节点 `IP:31123` 访问发现 `Nginx` 返回 `403`

[](http://ms.iirii.com:31123/)

添加 `index.html` 文件

[u.cs.1:/data/k8s]
```bash
$ echo "<h1>Hello Kubernetes~</h1>" >> /data/k8s/index.html
$ ls
index.html  test.txt
```

再次访问正常

********************************************************************************************************************************************************************************************************

## StorageClass

要使用 `StorageClass`，我们就得安装对应的自动配置程序，比如我们这里存储后端使用的是 `nfs`，那么我们就需要使用到一个 `nfs-client` 的自动配置程序，我们也叫它 `Provisioner`，
这个程序使用我们已经配置好的 `nfs` 服务器，来自动创建持久卷，也就是自动帮我们创建 `PV`。

当然在部署 `nfs-client` 之前，我们需要先成功安装上 `nfs` 服务器，
假设我们 `NFS` 服务地址是 `os.iirii.com`，共享数据目录是`/data/k8s`，然后接下来我们部署 `nfs-client` 即可

[~/Run/runs/kubernetes/coam/k8s.run.yaml]
```bash
kind: Deployment
apiVersion: apps/v1
metadata:
  name: nfs-client-provisioner
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: nfs-client-provisioner
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: quay.io/external_storage/nfs-client-provisioner:latest
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: nfs.iirii.com/coam
            - name: NFS_SERVER
              value: os.iirii.com
            - name: NFS_PATH
              value: /data/k8s
      volumes:
        - name: nfs-client-root
          nfs:
            server: os.iirii.com
            path: /data/k8s
```

将环境变量 `NFS_SERVER` 和 `NFS_PATH` 替换，当然也包括下面的 `nfs` 配置，我们可以看到我们这里使用了一个名为 `nfs-client-provisioner` 的 `serviceAccount`，所以我们也需要创建一个 sa，然后绑定上对应的权限：

[~/Run/runs/kubernetes/coam/k8s.run.yaml]
```bash
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nfs-client-provisioner

---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-client-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["list", "watch", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["create", "delete", "get", "list", "watch", "patch", "update"]

---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    namespace: default
roleRef:
  kind: ClusterRole
  name: nfs-client-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
```

我们这里新建的一个名为 `nfs-client-provisioner` 的 `ServiceAccount`，然后绑定了一个名为 `nfs-client-provisioner-runner` 的 `ClusterRole`，
而该 `ClusterRole` 声明了一些权限，其中就包括对 `persistentvolumes` 的增、删、改、查等权限，所以我们可以利用该 `ServiceAccount` 来自动创建 `PV`。

`nfs-client` 的 `Deployment` 声明完成后，我们就可以来创建一个 `StorageClass` 对象了：

[~/Run/runs/kubernetes/coam/k8s.run.yaml]
```bash
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: coam-nfs-storage
provisioner: nfs.iirii.com/coam # or choose another name, must match deployment's env PROVISIONER_NAME'
```

我们声明了一个名为 `coam-nfs-storage` 的 `StorageClass` 对象，注意下面的 `provisioner` 对应的值一定要和上面的 `Deployment` 下面的 `PROVISIONER_NAME` 这个环境变量的值一样。

创建以上资源 `Deployment`、`ServiceAccount`、`ClusterRole` 及 `ClusterRoleBinding` 就可以创建 `StorageClass` 了

```bash
kubectl get storageclass
NAME                 PROVISIONER      RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
coam-nfs-storage   nfs.iirii.com/coam   Delete          Immediate           false                  2m29s
```

### 测试下动态 PV

[~/Run/runs/kubernetes/coam/k8s.run.yaml]
```bash
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: test-pvc
  annotations:
    volume.beta.kubernetes.io/storage-class: "coam-nfs-storage"
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Mi
```

创建后发现多了 PV:(persistentvolume/pvc-f80c2fe1-c4c5-438f-bb33-4f25d7acd2b3) 和 PVC:(persistentvolumeclaim/test-pvc) 都绑定到 StorageClass:(coam-nfs-storage) 上

```bash
$ kubectl get pv,pvc -o wide
NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM              STORAGECLASS         REASON   AGE   VOLUMEMODE
persistentvolume/pv1                                        1Gi        RWO            Recycle          Bound    default/pvc-nfs                                  57m   Filesystem
persistentvolume/pvc-f80c2fe1-c4c5-438f-bb33-4f25d7acd2b3   1Mi        RWX            Delete           Bound    default/test-pvc   coam-nfs-storage            3s    Filesystem

NAME                             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS         AGE   VOLUMEMODE
persistentvolumeclaim/pvc-nfs    Bound    pv1                                        1Gi        RWO                                 52m   Filesystem
persistentvolumeclaim/test-pvc   Bound    pvc-f80c2fe1-c4c5-438f-bb33-4f25d7acd2b3   1Mi        RWX            coam-nfs-storage   3s    Filesystem
```

测试使用 `PVC`

```bash
kind: Pod
apiVersion: v1
metadata:
  name: test-pod
spec:
  containers:
  - name: test-pod
    image: busybox
    imagePullPolicy: IfNotPresent
    command:
    - "/bin/sh"
    args:
    - "-c"
    - "touch /mnt/SUCCESS && exit 0 || exit 1"
    volumeMounts:
    - name: nfs-pvc
      mountPath: "/mnt"
  restartPolicy: "Never"
  volumes:
  - name: nfs-pvc
    persistentVolumeClaim:
      claimName: test-pvc
```

待 `Pod` 执行完成后可以到 `NFS` 服务器查看

[u.cs.1:/data/k8s]
```bash
$ ls
default-test-pvc-pvc-f80c2fe1-c4c5-438f-bb33-4f25d7acd2b3  index.html  test.txt
$ ls default-test-pvc-pvc-f80c2fe1-c4c5-438f-bb33-4f25d7acd2b3/
SUCCESS
```

可以看到 `NFS` 服务器多了一个 `default-test-pvc-pvc-f80c2fe1-c4c5-438f-bb33-4f25d7acd2b3` 目录,这个文件夹的命名方式是不是和我们上面的规则：${namespace}-${pvcName}-${pvName}是一样的,并且下面已创建一个文件 `SUCCESS`

以上我们是手动创建的一个 `PVC` 对象，在实际工作中，使用 `StorageClass` 更多的是 `StatefulSet` 类型的服务，
`StatefulSet` 类型的服务我们也可以通过一个 `volumeClaimTemplates` 属性来直接使用 `StorageClass`

```bash
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nfs-web
spec:
  serviceName: "nginx"
  replicas: 3
  selector:
    matchLabels:
      app: nfs-web
  template:
    metadata:
      labels:
        app: nfs-web
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
      annotations:
        volume.beta.kubernetes.io/storage-class: coam-nfs-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
```

查看 `PV`,`PVC` 可以看到是不是也生成了3个 `PVC` 对象，名称由模板名称 `name` 加上 `Pod` 的名称组合而成，这3个 `PVC` 对象也都是 绑定状态了，

```bash
$ kubectl get pvc -o wide
NAME                                  STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS         AGE   VOLUMEMODE
persistentvolumeclaim/www-nfs-web-0   Bound    pvc-a9bbf04b-d214-4f48-aef7-249d457bb5f6   1Gi        RWO            coam-nfs-storage   33s   Filesystem
persistentvolumeclaim/www-nfs-web-1   Bound    pvc-4553705f-ac33-4c04-a0e4-18e6e6a56789   1Gi        RWO            coam-nfs-storage   29s   Filesystem
persistentvolumeclaim/www-nfs-web-2   Bound    pvc-9454206e-01e1-48ca-a010-1057127ab93b   1Gi        RWO            coam-nfs-storage   23s   Filesystem
```

很显然我们查看 `PV` 也可以看到对应的3个 `PV` 对象：

```bash
$ kubectl get pv -o wide
NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                   STORAGECLASS         REASON   AGE   VOLUMEMODE
persistentvolume/pvc-4553705f-ac33-4c04-a0e4-18e6e6a56789   1Gi        RWO            Delete           Bound    default/www-nfs-web-1   coam-nfs-storage            29s   Filesystem
persistentvolume/pvc-9454206e-01e1-48ca-a010-1057127ab93b   1Gi        RWO            Delete           Bound    default/www-nfs-web-2   coam-nfs-storage            23s   Filesystem
persistentvolume/pvc-a9bbf04b-d214-4f48-aef7-249d457bb5f6   1Gi        RWO            Delete           Bound    default/www-nfs-web-0   coam-nfs-storage            33s   Filesystem
```

查看 `nfs` 服务器上面的共享数据目录

[u.cs.1:/data/k8s]
```bash
$ ls
default-www-nfs-web-1-pvc-4553705f-ac33-4c04-a0e4-18e6e6a56789  default-www-nfs-web-0-pvc-a9bbf04b-d214-4f48-aef7-249d457bb5f6  default-www-nfs-web-2-pvc-9454206e-01e1-48ca-a010-1057127ab93b
```

********************************************************************************************************************************************************************************************************

* 参考博客文章

[](https://www.qikqiak.com/k8s-book/docs/33.PV.html)

********************************************************************************************************************************************************************************************************