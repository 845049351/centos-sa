#!/bin/bash

CurDir=$(dirname $0)
if [ -f $CurDir/confile ]; then
    source $CurDir/confile
else
    echo "配置文件没有生成，请检查！"
    exit 1
fi

export LANG=$LANG
export PATH=$PATH

InstallDir=/opt/app/nginx
version=1.6.2
pcre=pcre-8.36

## 以root用户运行
user=$(whoami)
if [ $user != 'root' ] ; then
    echo "该脚本需要以root用户运行, 当前用户为 $user"
    exit 1;
fi

## 删除自动安装设置
sed -i /install-nginx.sh/d /etc/rc.local

## 解压文件
cd $PWDir
if [ ! -f nginx-$version.tar.gz ]; then
    wget -q http://share.huikaiche.com/sa/nginx-$version.tar.gz
fi
if [ ! -f $pcre.tar.gz ]; then
    wget -q http://share.huikaiche.com/sa/$pcre.tar.gz
fi
tar xzf nginx-$version.tar.gz
tar xzf $pcre.tar.gz

## 编译
cd nginx-$version
./configure --prefix=$InstallDir --user=www --group=www --with-http_stub_status_module --with-openssl=/usr/ --with-pcre=../$pcre
make && make install

## 配置
mkdir -p $InstallDir/conf/conf.d
/bin/cp -f $PWDir/conf/nginx.conf $InstallDir/conf/
/bin/cp -f $PWDir/conf/nginx_default_site.conf $InstallDir/conf/conf.d/
/bin/cp -f $PWDir/conf/nginx_init /etc/init.d/nginx
chmod +x /etc/init.d/nginx

## 开机启动：
chkconfig --add nginx

## 当iptable没有设置时，在此设置
grep '--dport 80 ' /etc/sysconfig/iptables >/dev/null 2>&1
if [ $? -ne 0 ]; then
    sed -i '10a -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT' /etc/sysconfig/iptables
fi

## 删除解压缩文件
cd $PWDir
rm -rf nginx-$version
rm -rf $pcre

echo "nginx 安装成功!"
