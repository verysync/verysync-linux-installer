## 说明
本仓库代码用于Linux下自动安装verysync, 并加入各种系统的开机启动，
- 默认索引存放路径~/.config/verysync
- 端口号: 8886


## 快速安装 
```
#(如果需要指定索引存放位置请在后面添加-d 路径 如 -d /data/verysync)

curl https://raw.githubusercontent.com/verysync/verysync-linux-installer/master/go-installer.sh > go-installer.sh 
chmod +x go-installer.sh
./go-installer.sh
```


## 参数说明
```
./go-installer.sh [-h] [-c] [--remove] [-p proxy] [-f] [--version vx.y.z] [-l file] [-d index location]
  -h, --help            显示帮助
  -p, --proxy           指定代理服务器 -p socks5://127.0.0.1:1080 or -p http://127.0.0.1:3128 etc
  -f, --force           强制安装
      --version         安装特定版本 例如 --version v0.15.11-rc2
  -l, --local           从本地下载好的文件安装 需要使用绝对路径如 -l /root/verysync-linux-amd64-v0.15.12-rc1.tar.gz
      --remove          卸载微力同步
  -c, --check           检查更新
  -d  --home            指定微力索引存放位置, 默认 ~/.config/verysync
```

## 经测试系统:
- CentOS 6.5  init.d
- CentOS 7.5  systemd
- Debian 7.11 systemv
- Debian 9.5  systemd


由于Centos默认仓库 没有daemon套件，所以本仓库自带了i386 amd64 arm arm64版本的start-stop-daemon程序，省去了系统编译安装. 如果使用其它架构的系统，需要自行编译daemon套件方法 https://gist.github.com/yuuichi-fujioka/c4388cc672a3c8188423
