
# Kubernetes 管理工具

********************************************************************************************************************************************************************************************************

## kube-shell

[cloudnativelabs/kube-shell](https://github.com/cloudnativelabs/kube-shell)

* 安装

```bash
pip install kube-shell
```

********************************************************************************************************************************************************************************************************

## kubens

[kubectx](https://kubectx.dev)

* Mac

```bash
brew install kubectx
```

* Linux

```bash
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
```

********************************************************************************************************************************************************************************************************

## krew

[krew](https://krew.dev)

* 安装插件 - Linux

```bash
(
  set -x; cd "$(mktemp -d)" &&
  curl -fsSLO "https://storage.googleapis.com/krew/v0.2.1/krew.{tar.gz,yaml}" &&
  tar zxvf krew.tar.gz &&
  ./krew-"$(uname | tr '[:upper:]' '[:lower:]')_amd64" install \
    --manifest=krew.yaml --archive=krew.tar.gz
)
```

* 导出环境变量

```bash
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
```

* 常用命令

```bash
kubectl krew search                 # show all plugins
kubectl krew install view-secret    # install a plugin named "view-secret"
kubectl view-secret                 # use the plugin
kubectl krew upgrade                # upgrade installed plugins
kubectl krew uninstall view-secret  # uninstall a plugin
```

********************************************************************************************************************************************************************************************************

## Kustomize

* MacOS

```bash
brew install kustomize
```

或者有 Go 语言环境,可以这样安装:

```bash
go get sigs.k8s.io/kustomize
```

常用命令

```bash
kustomize build xxx
```

********************************************************************************************************************************************************************************************************

## HTTPie

[HTTPie](https://httpie.org/doc)
[HTTPie:超爽的HTTP命令行客户端](https://tonydeng.github.io/2015/07/10/httpie-howto/)

### 使用例子

* 定制头部

```bash
http tonydeng.github.io/blog/2015/07/10/httpie-howto/ User-Agent:Xmodlo/1.0 Referer:http://tonydeng.github.io
```

这个 `HTTP` 请求看起是这样。

```bash
GET /blog/2015/07/10/httpie-howto/ HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate
Connection: keep-alive
Host: tonydeng.github.io
Referer: http://tonydeng.github.io
User-Agent: Xmodlo/1.0
```

### 使用其他HTTP方法

除了默认的 `GET` 方法，你还可以使用其他方法（比如 `PUT`、`POST`、`DELETE`、`HEAD`）

* PUT

```bash
http PUT tonydeng.github.io name='Tony Deng' email='tonydeng@email.com'
```

* POST

```bash
http -f POST tonydeng.github.io name='Tony Deng' email='tonydeng@email.com'
```

> `-f` 选项使 `http` 命令序列化数据字段，并将 `Content-Type` 设置为 `application/x-www-form-urlencoded;charset=utf-8`

这个 `HTTP` `POST` 请求看起这样：

```bash
POST / HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate
Connection: keep-alive
Content-Length: 41
Content-Type: application/x-www-form-urlencoded; charset=utf-8
Host: tonydeng.github.io
User-Agent: HTTPie/0.9.2
name=Tony+Deng&email=tonydeng%40email.com
```

* HEAD

```bash
http HEAD tonydeng.github.io
```

> `HEAD` 这个方法只会让服务器返回 `http response headers`。

### JSON支持

> `HTTPie` 内置 `JSON` 的支持。事实上 `HTTPie` 默认使用的 `Content-Type` 就是 `application/json`。因此，当你不指定 `Content-Type` 发送请求参数时，它们就会自动序列化为 `JSON` 对象。

```bash
http POST tonydeng.github.io name='Tony Deng' email='tonydeng@email.com'
```

这个请求看起来就是这样：

```bash
POST / HTTP/1.1
Accept: application/json
Accept-Encoding: gzip, deflate
Connection: keep-alive
Content-Length: 52
Content-Type: application/json
Host: tonydeng.github.io
User-Agent: HTTPie/0.9.2
{
    "email": "tonydeng@email.com",
    "name": "Tony Deng"
}
```

### 输入重定向

> `HTTPie` 的另外一个友好特性就是输入重定向，你可以使用缓冲数据提供 `HTTP` 请求内容。例如：

```bash
http POST tonydeng.github.io < my_info.json
```

或:

```bash
echo '{"name": "Tony Deng","email": "tonydeng@email.com"}' | http POST tonydeng.github.io
```

********************************************************************************************************************************************************************************************************
