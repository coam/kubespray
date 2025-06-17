# Cilium 部署失败

```bash
$ ./bin/cluster.sh deploy
$ ansible-playbook -i inventory/mycluster/hosts.yaml -u root --become --become-user=root cluster.yml
```

报错

```bash
TASK [network_plugin/cilium : Cilium | Install] **************************************************************************************************************************************************************************************************************************************************
fatal: [server-15]: FAILED! => {"changed": true, "cmd": ["/usr/local/bin/cilium", "install", "--version", "1.17.3", "-f", "/etc/kubernetes/cilium-values.yaml"], "delta": "0:00:00.230951", "end": "2025-06-16 17:54:50.135767", "msg": "non-zero return code", "rc": 1, "start": "2025-06-16 17:54:49.904816", "stderr": "\nError: Unable to install Cilium: cannot re-use a name that is still in use", "stderr_lines": ["", "Error: Unable to install Cilium: cannot re-use a name that is still in use"], "stdout": "ℹ️  Using Cilium version 1.17.3\nℹ️  Using cluster name \"default\"\n🔮 Auto-detected kube-proxy has been installed", "stdout_lines": ["ℹ️  Using Cilium version 1.17.3", "ℹ️  Using cluster name \"default\"", "🔮 Auto-detected kube-proxy has been installed"]}
```

在服务器上查看 `cilium` 服务状态

```bash
/usr/local/bin/cilium status
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             1 errors
 \__/¯¯\__/    Operator:           disabled
 /¯¯\__/¯¯\    Envoy DaemonSet:    disabled (using embedded mode)
 \__/¯¯\__/    Hubble Relay:       disabled
    \__/       ClusterMesh:        disabled

Containers:            cilium
                       cilium-operator
                       clustermesh-apiserver
                       hubble-relay
Cluster Pods:          53/57 managed by Cilium
Helm chart version:    1.17.3
Errors:                cilium    cilium    daemonsets.apps "cilium" not found
status check failed: [daemonsets.apps "cilium" not found]
```

手动在服务器上执行命令尝试启动报同样的错误

```bash
/usr/local/bin/cilium install --version 1.17.3 -f /etc/kubernetes/cilium-values.yaml
ℹ️  Using Cilium version 1.17.3
ℹ️  Using cluster name "default"
🔮 Auto-detected kube-proxy has been installed

Error: Unable to install Cilium: cannot re-use a name that is still in use
```

使用 `cilium sysdump` 查看系统状态

```bash
$ /usr/local/bin/cilium sysdump
🔍 Collecting sysdump with cilium-cli version: v0.18.3, args: [sysdump]
⚠️ Failed to detect Cilium installation
⚠️ Failed to detect Cilium operator
ℹ️ Using default Cilium Helm release name: "cilium"
ℹ️ Using default Tetragon Helm release name: "tetragon"
🔍 Collecting Kubernetes nodes
🔍 Collect Kubernetes nodes
🔍 Collecting Kubernetes events
🔍 Collect Kubernetes version
🔍 Collecting Kubernetes pods
🔍 Collecting Kubernetes namespaces
🔍 Collecting Kubernetes services
🔍 Collecting Kubernetes pods summary
🔍 Collecting Kubernetes endpoints
🔍 Collecting Kubernetes network policies
🔍 Collecting Kubernetes endpointslices
🔍 Collecting Kubernetes metrics
🔍 Collecting Kubernetes leases
🔍 Collecting logs from Tetragon pods
🔍 Collecting crashed test pod logs
🔍 Collecting logs from Tetragon operator pods
I0616 19:49:12.156438 2069456 request.go:729] Waited for 1.159418211s due to client-side throttling, not priority and fairness, request: GET:https://127.0.0.1:6443/api/v1/namespaces
🔍 Collecting bugtool output from Tetragon pods
🔍 Collecting Tetragon PodInfo custom resources
🔍 Collecting Tetragon configmap
🔍 Collecting Tetragon namespaced tracing policies
🔍 Collecting Helm metadata from the Cilium release
🔍 Collecting Tetragon tracing policies
🔍 Collecting Helm metadata from the Tetragon release
🔍 Collecting Helm values from the Cilium release
🔍 Collecting Helm values from the Tetragon release
⚠️ The following tasks failed, the sysdump may be incomplete:
⚠️ [17] Collecting Tetragon PodInfo custom resources: failed to collect podinfo (v1alpha1): the server could not find the requested resource
⚠️ [18] Collecting Tetragon tracing policies: failed to collect tracingpolicies (v1alpha1): the server could not find the requested resource
⚠️ [19] Collecting Tetragon namespaced tracing policies: failed to collect tracingpoliciesnamespaced (v1alpha1): the server could not find the requested resource
⚠️ [21] Collecting Helm metadata from the Tetragon release: failed to get the helm metadata from the release: unable to retrieve helm meta from release tetragon: release: not found
⚠️ [23] Collecting Helm values from the Tetragon release: failed to get the helm values from the release: unable to retrieve helm value from release tetragon: release: not found
⚠️ Please note that depending on your Cilium version and installation options, this may be expected
🗳 Compiling sysdump
✅ The sysdump has been saved to cilium-sysdump-20250616-194910.zip
```

发起其中一行 `️ Using default Cilium Helm release name: "cilium"` 提示 `cilium` 服务是使用 `helm chart` 部署的

```bash
helm list -A
NAME               	NAMESPACE        	REVISION	UPDATED                                	STATUS  	CHART                    	APP VERSION
cilium             	kube-system      	1       	2025-06-16 19:50:57.963650523 +0800 CST	deployed	cilium-1.17.3            	1.17.3
```

估计是第一次安装有 `cilium`,再次执行 `cilium install ...` 会提示已经存在

查看配置文件 `cilium help`

```bash
$ cilium help
  install      Install Cilium in a Kubernetes cluster using Helm
```

手动删除

```bash
helm delete cilium -n kube-system
```

再次尝试，启动成功。

```bash
$ /usr/local/bin/cilium install --version 1.17.3 -f /etc/kubernetes/cilium-values.yaml
ℹ️  Using Cilium version 1.17.3
ℹ️  Using cluster name "default"
🔮 Auto-detected kube-proxy has been installed
```

查看 `cilium` 服务状态

```bash
 /usr/local/bin/cilium status
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             7 errors
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    1 errors
 \__/¯¯\__/    Hubble Relay:       disabled
    \__/       ClusterMesh:        disabled

DaemonSet              cilium                   Desired: 3, Unavailable: 3/3
DaemonSet              cilium-envoy             Desired: 3, Unavailable: 3/3
Deployment             cilium-operator          Desired: 2, Ready: 2/2, Available: 2/2
Containers:            cilium                   Running: 3
                       cilium-envoy             Running: 3
                       cilium-operator          Running: 2
                       clustermesh-apiserver
                       hubble-relay
Cluster Pods:          53/57 managed by Cilium
Helm chart version:    1.17.3
Image versions         cilium             quay.io/cilium/cilium:v1.17.3@sha256:1782794aeac951af139315c10eff34050aa7579c12827ee9ec376bb719b82873: 3
                       cilium-envoy       quay.io/cilium/cilium-envoy:v1.32.5-1744305768-f9ddca7dcd91f7ca25a505560e655c47d3dec2cf@sha256:a01cadf7974409b5c5c92ace3d6afa298408468ca24cab1cb413c04f89d3d1f9: 3
                       cilium-operator    quay.io/cilium/operator-generic:v1.17.3@sha256:8bd38d0e97a955b2d725929d60df09d712fb62b60b930551a29abac2dd92e597: 2
Errors:                cilium             cilium          3 pods of DaemonSet cilium are not ready
                       cilium             cilium-88sr5    unable to retrieve cilium status: command failed (pod=kube-system/cilium-88sr5, container=cilium-agent): command terminated with exit code 1: "Get \"http://localhost/v1/healthz\": dial unix /var/run/cilium/cilium.sock: connect: no such file or directory\nIs the agent running?\n"
                       cilium             cilium-88sr5    unable to retrieve cilium endpoint information: command failed (pod=kube-system/cilium-88sr5, container=cilium-agent): command terminated with exit code 1: "Error: cannot get endpoint list: Get \"http://localhost/v1/endpoint\": dial unix /var/run/cilium/cilium.sock: connect: no such file or directory\nIs the agent running?\n\n"
                       cilium             cilium-8hg75    unable to retrieve cilium status: command failed (pod=kube-system/cilium-8hg75, container=cilium-agent): command terminated with exit code 1: "Get \"http://localhost/v1/healthz\": dial unix /var/run/cilium/cilium.sock: connect: no such file or directory\nIs the agent running?\n"
                       cilium             cilium-8hg75    unable to retrieve cilium endpoint information: command failed (pod=kube-system/cilium-8hg75, container=cilium-agent): command terminated with exit code 1: "Error: cannot get endpoint list: Get \"http://localhost/v1/endpoint\": dial unix /var/run/cilium/cilium.sock: connect: no such file or directory\nIs the agent running?\n\n"
                       cilium             cilium-hqhch    unable to retrieve cilium status: command failed (pod=kube-system/cilium-hqhch, container=cilium-agent): command terminated with exit code 1: "Get \"http://localhost/v1/healthz\": dial unix /var/run/cilium/cilium.sock: connect: no such file or directory\nIs the agent running?\n"
                       cilium             cilium-hqhch    unable to retrieve cilium endpoint information: command failed (pod=kube-system/cilium-hqhch, container=cilium-agent): command terminated with exit code 1: "Error: cannot get endpoint list: Get \"http://localhost/v1/endpoint\": dial unix /var/run/cilium/cilium.sock: connect: no such file or directory\nIs the agent running?\n\n"
                       cilium-envoy       cilium-envoy    3 pods of DaemonSet cilium-envoy are not ready
```

等待片刻再次查看

```bash
$ cilium status
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    OK
 \__/¯¯\__/    Hubble Relay:       disabled
    \__/       ClusterMesh:        disabled

DaemonSet              cilium                   Desired: 3, Ready: 3/3, Available: 3/3
DaemonSet              cilium-envoy             Desired: 3, Ready: 3/3, Available: 3/3
Deployment             cilium-operator          Desired: 2, Ready: 2/2, Available: 2/2
Containers:            cilium                   Running: 3
                       cilium-envoy             Running: 3
                       cilium-operator          Running: 2
                       clustermesh-apiserver
                       hubble-relay
Cluster Pods:          58/58 managed by Cilium
Helm chart version:    1.17.3
Image versions         cilium             quay.io/cilium/cilium:v1.17.3@sha256:1782794aeac951af139315c10eff34050aa7579c12827ee9ec376bb719b82873: 3
                       cilium-envoy       quay.io/cilium/cilium-envoy:v1.32.5-1744305768-f9ddca7dcd91f7ca25a505560e655c47d3dec2cf@sha256:a01cadf7974409b5c5c92ace3d6afa298408468ca24cab1cb413c04f89d3d1f9: 3
                       cilium-operator    quay.io/cilium/operator-generic:v1.17.3@sha256:8bd38d0e97a955b2d725929d60df09d712fb62b60b930551a29abac2dd92e597: 2
```

查看 `pod` 状态，发现均已启动成功

```bash
$ kubectl get po -A -o wide
kube-system         cilium-88sr5                                       1/1     Running     0                  2m19s   10.100.0.105    server-15   <none>           <none>
kube-system         cilium-8hg75                                       1/1     Running     0                  2m19s   10.100.0.107    server-17   <none>           <none>
kube-system         cilium-envoy-7tb77                                 1/1     Running     0                  2m19s   10.100.0.106    server-16   <none>           <none>
kube-system         cilium-envoy-hcvhf                                 1/1     Running     0                  2m19s   10.100.0.107    server-17   <none>           <none>
kube-system         cilium-envoy-nwqvm                                 1/1     Running     0                  2m19s   10.100.0.105    server-15   <none>           <none>
kube-system         cilium-hqhch                                       1/1     Running     0                  2m19s   10.100.0.106    server-16   <none>           <none>
kube-system         cilium-operator-b4856bd98-c2plt                    1/1     Running     0                  2m19s   10.100.0.105    server-15   <none>           <none>
kube-system         cilium-operator-b4856bd98-wnfr2                    1/1     Running     0                  2m19s   10.100.0.107    server-17   <none>           <none>
```

最后记录完成的系统信息

```bash
/usr/local/bin/cilium sysdump
🔍 Collecting sysdump with cilium-cli version: v0.18.3, args: [sysdump]
🔮 Detected Cilium installation in namespace: "kube-system"
🔮 Detected Cilium operator in namespace: "kube-system"
ℹ️ Using default Cilium Helm release name: "cilium"
ℹ️ Using default Tetragon Helm release name: "tetragon"
ℹ️ Failed to detect Cilium SPIRE installation - using Cilium namespace as Cilium SPIRE namespace: "kube-system"
🔍 Collecting Kubernetes nodes
🔮 Detected Cilium features: map[bpf-lb-external-clusterip:Disabled cidr-match-nodes:Disabled clustermesh-enable-endpoint-sync:Disabled cni-chaining:Disabled:none enable-bgp-control-plane:Disabled enable-encryption-strict-mode:Disabled enable-envoy-config:Disabled enable-gateway-api:Disabled enable-ipsec:Disabled enable-ipv4-egress-gateway:Disabled enable-local-redirect-policy:Disabled enable-policy-secrets-sync:Enabled endpoint-routes:Disabled ingress-controller:Disabled ipam:Disabled:cluster-pool ipv4:Enabled ipv6:Disabled multicast-enabled:Disabled mutual-auth-spiffe:Disabled policy-secrets-only-from-secrets-namespace:Enabled wireguard-encapsulate:Disabled]
🔍 Collecting profiling data from Cilium pods
🔍 Collecting tracing data from Cilium pods
🔍 Collect Kubernetes nodes
🔍 Collecting Kubernetes events
🔍 Collect Kubernetes version
🔍 Collecting Kubernetes pods
🔍 Collecting Kubernetes namespaces
🔍 Collecting Kubernetes services
🔍 Collecting Kubernetes pods summary
🔍 Collecting Kubernetes endpoints
🔍 Collecting Kubernetes network policies
🔍 Collecting Kubernetes leases
🔍 Collecting Kubernetes endpointslices
🔍 Collecting crashed test pod logs
🔍 Collecting Kubernetes metrics
🔍 Collecting Cilium cluster-wide network policies
🔍 Collecting Cilium network policies
🔍 Collecting Cilium CIDR Groups
🔍 Collecting Cilium Egress Gateway policies
🔍 Collecting Cilium endpoints
🔍 Collecting Cilium local redirect policies
🔍 Collecting Cilium endpoint slices
🔍 Collecting Cilium identities
🔍 Collecting Cilium nodes
🔍 Collecting Cilium Node Configs
🔍 Collecting IngressClasses
🔍 Collecting Ingresses
🔍 Collecting the Cilium daemonset(s)
🔍 Collecting the Cilium Node Init daemonset
W0616 20:06:00.215205 2080710 warnings.go:70] cilium.io/v2alpha1 CiliumNodeConfig will be deprecated in cilium v1.16; use cilium.io/v2 CiliumNodeConfig
⚠️ Daemonset "cilium-node-init" not found in namespace "kube-system" - this is expected if Node Init DaemonSet is not enabled
🔍 Collecting Cilium Pod IP Pools
🔍 Collecting Cilium LoadBalancer IP Pools
🔍 Collecting the Cilium Envoy configuration
🔍 Collecting the Cilium configuration
🔍 Checking if cilium-etcd-secrets exists in kube-system namespace
🔍 Collecting the Hubble Relay deployment
🔍 Collecting the Hubble Relay configuration
🔍 Collecting the Hubble daemonset
🔍 Collecting the Cilium Envoy daemonset
🔍 Collecting the Hubble UI deployment
🔍 Collecting the Hubble generate certs cronjob
🔍 Collecting the Hubble generate certs pod logs
🔍 Collecting the Hubble cert-manager certificates
🔍 Collecting the Cilium operator deployment
🔍 Collecting the Cilium operator metrics
🔍 Collecting the clustermesh debug information, metrics and gops stats
⚠️ Deployment "hubble-relay" not found in namespace "kube-system" - this is expected if Hubble is not enabled
Secret "cilium-etcd-secrets" not found in namespace "kube-system" - this is expected when using the CRD KVStore
⚠️ cronjob "hubble-generate-certs" not found in namespace "kube-system" - this is expected if auto TLS is not enabled or if not using hubble.auto.tls.method=cronjob
⚠️ Deployment "hubble-ui" not found in namespace "kube-system" - this is expected if Hubble UI is not enabled
🔍 Collecting the CNI configuration files from Cilium pods
🔍 Collecting the 'clustermesh-apiserver' deployment
🔍 Collecting the CNI configmap
🔍 Collecting gops stats from Cilium pods
⚠️ Deployment "clustermesh-apiserver" not found in namespace "kube-system" - this is expected if 'clustermesh-apiserver' isn't enabled
🔍 Collecting gops stats from Cilium-operator pods
🔍 Collecting gops stats from Hubble pods
🔍 Collecting gops stats from Hubble Relay pods
🔍 Collecting bugtool output from Cilium pods
🔍 Collecting profiling data from Cilium Operator pods
🔍 Collecting logs from Cilium pods
I0616 20:06:02.720264 2080710 request.go:729] Waited for 1.193762268s due to client-side throttling, not priority and fairness, request: GET:https://127.0.0.1:6443/api/v1/namespaces/kube-system/pods/cilium-88sr5/log?container=mount-bpf-fs&limitBytes=1073741824&sinceTime=2024-06-16T12%3A06%3A01Z&timestamps=true
🔍 Collecting logs from crashing Cilium pods
🔍 Collecting logs from Cilium Envoy pods
🔍 Collecting logs from Cilium Node Init pods
🔍 Collecting logs from Cilium operator pods
🔍 Collecting logs from 'clustermesh-apiserver' pods
🔍 Collecting logs from Hubble pods
🔍 Collecting logs from Hubble Relay pods
🔍 Collecting logs from Hubble UI pods
🔍 Collecting platform-specific data
🔍 Collecting kvstore data
🔍 Collecting Hubble flows from Cilium pods
🔍 Collecting logs from Tetragon pods
🔍 Collecting logs from Tetragon operator pods
🔍 Collecting bugtool output from Tetragon pods
🔍 Collecting Tetragon PodInfo custom resources
🔍 Collecting Tetragon configmap
🔍 Collecting Tetragon namespaced tracing policies
🔍 Collecting Helm metadata from the Cilium release
🔍 Collecting Tetragon tracing policies
🔍 Collecting Helm metadata from the Tetragon release
🔍 Collecting Helm values from the Cilium release
🔍 Collecting Helm values from the Tetragon release
⚠️ The following tasks failed, the sysdump may be incomplete:
⚠️ [15] Collecting Cilium Egress Gateway policies: failed to collect Cilium Egress Gateway policies: the server could not find the requested resource (get ciliumegressgatewaypolicies.cilium.io)
⚠️ [17] Collecting Cilium local redirect policies: failed to collect Cilium local redirect policies: the server could not find the requested resource (get ciliumlocalredirectpolicies.cilium.io)
⚠️ [19] Collecting Cilium endpoint slices: failed to collect Cilium endpoint slices: the server could not find the requested resource (get ciliumendpointslices.cilium.io)
⚠️ [34] Collecting the Hubble Relay configuration: failed to collect the Hubble Relay configuration: configmaps "hubble-relay-config" not found
⚠️ hubble-flows-cilium-88sr5: failed to collect hubble flows for "cilium-88sr5" in namespace "kube-system": command failed (pod=kube-system/cilium-88sr5, container=cilium-agent): command terminated with exit code 1
⚠️ hubble-flows-cilium-8hg75: failed to collect hubble flows for "cilium-8hg75" in namespace "kube-system": command failed (pod=kube-system/cilium-8hg75, container=cilium-agent): command terminated with exit code 1
⚠️ hubble-flows-cilium-hqhch: failed to collect hubble flows for "cilium-hqhch" in namespace "kube-system": command failed (pod=kube-system/cilium-hqhch, container=cilium-agent): command terminated with exit code 1
⚠️ [68] Collecting Tetragon PodInfo custom resources: failed to collect podinfo (v1alpha1): the server could not find the requested resource
⚠️ [69] Collecting Tetragon tracing policies: failed to collect tracingpolicies (v1alpha1): the server could not find the requested resource
⚠️ [70] Collecting Tetragon namespaced tracing policies: failed to collect tracingpoliciesnamespaced (v1alpha1): the server could not find the requested resource
⚠️ [72] Collecting Helm metadata from the Tetragon release: failed to get the helm metadata from the release: unable to retrieve helm meta from release tetragon: release: not found
⚠️ [74] Collecting Helm values from the Tetragon release: failed to get the helm values from the release: unable to retrieve helm value from release tetragon: release: not found
⚠️ Please note that depending on your Cilium version and installation options, this may be expected
🗳 Compiling sysdump
✅ The sysdump has been saved to cilium-sysdump-20250616-200529.zip
```