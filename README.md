# 透明代理脚本

一个支持打点切换出口IP和内网渗透透明代理的脚本。

优点：

1. 防溯源
2. 支持无限切换IP
3. 能够应用于路由器

缺点：

1. 依赖[redsocks](https://github.com/darkk/redsocks)


## 使用规范


### Packages

- [Archlinux AUR](https://aur.archlinux.org/packages/redsocks-git)
- [Debian](http://packages.debian.org/search?searchon=names&keywords=redsocks)
- [Ubuntu](http://packages.ubuntu.com/search?searchon=names&keywords=redsocks)

- Arch Linux : `yaourt -S redsocks`
- Ubuntu : `apt-get install redsocks`
- ....

### 子命令

```
[*] Usage : ./socks-switch.sh <start | stop | clean | install | uninstall | change IP PORT | pentest IP PORT>
    ./socks-switch.sh start : 启动redsocks，自动设置iptables
    ./socks-switch.sh stop : 停止redsocks，自动清空iptables
    ./socks-switch.sh clean : 清空iptables所有规则
    ./socks-switch.sh install : 安装iptables规则
    ./socks-switch.sh uninstall : 卸载iptables规则
    ./socks-switch.sh change : 改变Socks的IP和端口
    ./socks-switch.sh pentest : 开始内网渗透，传入Socks的IP和端口
```

打点模式简单使用：

```
sudo ./socks-switch.sh install
sudo ./socks-switch.sh start
```

切换至内网模式使用：

```
sudo ./socks-switch.sh uninstall
sudo ./socks-switch.sh pentest 1.1.1.1 5566
```

手动指定Socks的IP和端口：

```
sudo ./socks-switch.sh change 2.2.2.2 7788
```



## 配置项

```bash
#!/bin/bash
redsocks_bin_path="/usr/bin/redsocks" # redsocks二进制文件路径
redsocks_config_file_path="/etc/redsocks.conf" # redsocks配置文件路径
socks_api_url='http://http.tiqu.alicdns.com/getip3?num=1&type=1&pro=&city=0&yys=0&port=2&time=2&ts=0&ys=0&cs=0&lb=1&sb=0&pb=4&mr=1&regions=&gm=4' # api接口，返回socks5：IP:端口
shell_log_path="/tmp/root-test-socks.log" # 日志文件
```


