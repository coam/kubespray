# Rancher 配置

使用 `docker` 启动一个 `rancher` 服务

```bash
docker run -it --rm --name=rancher -p 8080:80 -p 8443:443 --privileged rancher/rancher
```

