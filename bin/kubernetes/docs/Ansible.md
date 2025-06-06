
# Ansible 服务管理

* 参考博客文章

[Ansible简明教程](https://jaydenz.github.io/2018/05/12/6.Ansible教程/)
[ansible](http://blog.whysdomain.com/blog/247/)

[常见开源协议介绍](https://jaydenz.github.io/2018/05/01/2.常见开源协议介绍/)
[Linux系统启动流程](https://jaydenz.github.io/2018/05/05/4.Linux系统启动流程/)

********************************************************************************************************************************************************************************************************

* 使用 `Ansible` 部署 `Rancher` 集群

[ansible-rancher](https://github.com/xuelangos/ansible-rancher)

********************************************************************************************************************************************************************************************************

## 命令行

### 向目标主机同步文件

```bash
ansible wc_test -m copy -a "src=/etc/hosts dest=/tmp/hosts"
ansible wr_test -m copy -a "src=/etc/hosts dest=/tmp/hosts"
```

### 在所有的远程主机上，以当前bash的同名用户，在远程主机执行“echo bash”

```bash
ansible all -a "/bin/echo hello"
ansible all -i hosts -a "/bin/echo hello"
```

安装包

远程主机（组）web安装apt包acme

```bash
ansible wc_test -m apt -a "name=acme state=present"
```

```bash
ansible wc_test -m yum -a 'list=installed'
```

下载git包

```bash
ansible all -i hosts -m git -a "repo=https://github.com/zyfmix/xmpp.git dest=/tmp/xmpp version=HEAD"
```

添加用户

```bash
ansible all -i hosts -m user -a "name=foo password=123456"
```

启动服务

```bash
ansible all -i hosts -m service -a "name=docker state=started"
```

并行执行

启动10个并行进行执行重起

```bash
ansible all -i hosts -a "/bin/echo hello" -f 10
```

查看远程主机的全部系统信息！！！

```bash
ansible all -m setup
```

********************************************************************************************************************************************************************************************************

## 脚本

```bash
ansible-playbook test/run.yml
```

********************************************************************************************************************************************************************************************************

Ansible参数

-f forks 一次执行几个
-m module_name 默认为command
-a arg 参数
ansible-doc -l 查看支持的模块

-s <module_name>指定模块的详细内容

需要配置hosts，默认有示例

all所有主机

常见模块

command 但是不能使用变量，可以用shell
cron 可以在主机生成定时任务-m cron -a 'minute="*/10" job="/bin/echo why" name="why test"'，移除添加参数state=absent，默认为present安装
user 创建用户
group 创建组
copy 复制文件copy -a 'src=/etc/fstab dest=/tmp/fstab owner=root mode=640'，也支持直接访问指定文件内容替代src，'content="Hello \nwhy"'

```bash
ansible web -m copy -a "src=/etc/hosts dest=/tmp/hosts"
```

file 设置文件的属性，软链等 

```bash
ansible -m file -a 'src=/etc/fstab path=/etc/fstab.link state=link'
```

* ping 查看主机链接

```bash
ansible all -m ping
```

service 用于管理注册的service
shell 执行命令，shell -a 'echo 123456|passwd --stdin why'
script 将本地脚本复制到远程主机执行
yum 安装程序包
setup 收集远程主机的facts

## ansible的运行模式

* 纯命令行
* playbook
* python api 模式

### ansible 命令行模式

> ansible -h

即可掌握大致的用法。

常见的参数如下：

-i hosts # 指定操作的主机文件
-m raw/copy # raw表示执行命令 copy表示传文件
-a “hostname” # 后面接具体的命令
-b –become-user=user00 #改变执行的用户

### playbook模式

playbook通俗的来讲，就是把命令行操作的内容按照一定的规范编排起来。

Playbooks contain plays
Plays contain tasks
Tasks call modules
at last, we have handlers which can be triggered to be executed after some actions.

执行 playbook

# -f 表示同时在几台目标机器上执行

$ ansible-playbook playbook.yml -f 10

### python api模式


********************************************************************************************************************************************************************************************************