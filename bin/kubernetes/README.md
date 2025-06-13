
### Mac 下安装 kubernetes 集群环境

环境准备

> VT-x or AMD-v virtualization must be enabled in your computer’s BIOS.

```bash
sysctl -a | grep machdep.cpu.features
```

相关软件安装

* kubectl
* docker (for Mac)
* minikube
* virtualbox

* 执行安装

```bash
brew update && brew install kubectl && brew cask install docker minikube virtualbox
```

* 校验软件版本信息

```bash
$ docker --version
Docker version 18.09.2, build 6247962
$ docker-compose --version
docker-compose version 1.23.2, build 1110ad01
$ docker-machine --version
docker-machine version 0.16.1, build cce350d7
$ minikube version
minikube version: v1.0.1
$ kubectl version --client  
Client Version: version.Info{Major:"1", Minor:"14", GitVersion:"v1.14.1", GitCommit:"b7394102d6ef778017f2ca4046abbaa23b88c290", GitTreeState:"clean", BuildDate:"2019-04-19T22:12:47Z", GoVersion:"go1.12.4", Compiler:"gc", Platform:"darwin/amd64"} 
```

## 启动 kubernetes 集群

```bash
minikube start --bootstrapper=localkube
```

## 重新安装

```bash
minikube start
rm -rf ~/.minikube
```

[Install Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)
[Kubernetes 环境搭建 - MacOS](https://www.jianshu.com/p/74957f08646b)
[利用 minikube 在 macOS 上部署一个 Go 程序](https://maiyang.me/post/2018-07-31-minikube-guide-in-mac/)