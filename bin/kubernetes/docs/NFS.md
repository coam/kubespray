
# 创建 NFS 存储

## 准备工作

安装 `NFS` 服务器

节点类型 | 主机名 | 域名 | IP
------ | ---- | -------------
服务器 | u.cs.1 | os.iirii.com | 165.154.5.141
客户端 | v.cs.1 | vs.iirii.com | 8.9.3.182

[u.cs.1]
```bash
yum -y install nfs-utils rpcbind
```

设置目录权限

[u.cs.1]
```bash
mkdir -p /data/k8s
chmod 755 /data/k8s
```

配置 `NFS`

[/etc/exports]
```bash
/data/k8s  *(rw,sync,no_root_squash)
```

启动服务,注意安装顺序

先启动 `rpcbind`

[u.cs.1]
```bash
sudo systemctl start rpcbind
sudo systemctl enable rpcbind
sudo systemctl status rpcbind
```

再启动 `nfs`

[u.cs.1]
```bash
sudo systemctl start nfs-server
sudo systemctl enable nfs-server
sudo systemctl status nfs-server
```

通过以下命令确认

[u.cs.1]
```bash
$ rpcinfo -p|grep nfs
    100003    3   tcp   2049  nfs
    100003    4   tcp   2049  nfs
    100227    3   tcp   2049  nfs_acl
```

查看具体目录挂载权限

```bash
$ cat /var/lib/nfs/etab
/data/k8s	*(rw,sync,wdelay,hide,nocrossmnt,secure,no_root_squash,no_all_squash,no_subtree_check,secure_locks,acl,no_pnfs,anonuid=65534,anongid=65534,sec=sys,rw,secure,no_root_squash,no_all_squash)
```

验证安装

在另一台服务器安装 NFS 客户端,和安装服务端流程一样

[v.cs.1]
```bash
sudo yum -y install nfs-utils rpcbind
```

[v.cs.1]
```bash
sudo systemctl start rpcbind
sudo systemctl enable rpcbind
sudo systemctl status rpcbind
```

首先检查下 nfs 是否有共享目录：

[v.cs.1]
```bash
$ showmount -e u.cs.1
Export list for u.cs.1:
/data/k8s *
```

然后我们在客户端上新建目录：

[v.cs.1]
```bash
mkdir -p /opt/data/k8s
```

将 nfs 共享目录挂载到上面的目录：

[v.cs.1]
```bash
$ mount -t nfs u.cs.1:/data/k8s /opt/data/k8s
```

挂载成功后，在客户端上面的目录中新建一个文件，然后我们观察下 nfs 服务端的共享目录下面是否也会出现该文件：

[v.cs.1]
```bash
$ touch /opt/data/k8s/test.txt
```

然后在 `nfs` 服务端查看：

[u.cs.1]
```bash
$ ls -ls /data/k8s/
total 0
0 -rw-r--r-- 1 root root 0 Oct 12 15:51 test.txt
```

如果上面出现了 `test.txt` 的文件，那么证明我们的 `nfs` 挂载成功了。

* 参考博客文章

[](https://www.qikqiak.com/k8s-book/docs/33.PV.html)

********************************************************************************************************************************************************************************************************