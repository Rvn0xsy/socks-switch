#!/bin/bash
redsocks_bin_path="/usr/bin/redsocks"
redsocks_config_file_path="/etc/redsocks.conf"
socks_api_url='*****'
shell_log_path="/tmp/socks-switch.log"
# ssh port
ssh_port="22"
# read -p "please input ssh port:" ssh_port

redsocks_user="redsocks"

socks_loging(){
    current_time=$(date +"%Y-%m-%d %H:%M:%S");
    echo "[*] "$current_time ": " $1 >> $shell_log_path
    echo "[*] "$current_time ": " $1
}


change_socks(){
    local socks_ip=$1;
    local socks_port=$2;
    socks_loging "Change Socks: $1, Port: $2";
    # 61行是Socks IP
    sed -i '61d' $redsocks_config_file_path
    sed -i "61i\        ip=$socks_ip;"  $redsocks_config_file_path

    # 62行是Socks Port
    sed -i '62d' $redsocks_config_file_path
    sed -i "62i\        port=$socks_port;"  $redsocks_config_file_path
    pkill redsocks
    socks_loging "Run redsocks...."
    $redsocks_bin_path -c $redsocks_config_file_path
}

start_pentest(){
    uninstall_iptables
    iptables -t nat -N REDSOCKS
    iptables -t nat -F REDSOCKS # 清空
    
    iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
    iptables -t nat -A REDSOCKS -p tcp -d 10.0.0.0/8 -j REDIRECT --to-port 31338
    iptables -t nat -A REDSOCKS -p tcp -d 172.16.0.0/16 -j REDIRECT --to-port 31338
    iptables -t nat -A REDSOCKS -p tcp -d 192.168.0.0/16 -j REDIRECT --to-port 31338
    
    unset_iptables
    set_iptables
    local socks_ip=$1;
    local socks_port=$2;
    change_socks $socks_ip $socks_port
    socks_loging "Change Socks: $1, Port: $2";

}

install_iptables(){
    iptables -t nat -F OUTPUT
    iptables -t nat -F PREROUTING
    # 如果没有就新建一个
    local is_redsocks=`iptables -t nat -nL --line-number |grep REDSOCKS`
    if [ -z "$is_redsocks" ]; then
            iptables -t nat -N REDSOCKS
    fi
    iptables -t nat -F REDSOCKS # 清空
    iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
    iptables -t nat -A REDSOCKS -p tcp --dport $ssh_port -j RETURN
    iptables -t nat -A REDSOCKS -d http.tiqu.alicdns.com -j RETURN
    iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 169.254.0.0/16 -j RETURN
    iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
    iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN
    iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-port 31338
    socks_loging "Install Success!"
}


uninstall_iptables(){
    iptables -t nat -F OUTPUT
    iptables -t nat -F PREROUTING
    socks_loging "Uninstall iptables  ..."
    is_redsocks=`iptables -t nat -nvL REDSOCKS |wc -l`
    if [ "$is_redsocks"!="0" ]; then
            iptables -t nat -F REDSOCKS
            iptables -t nat -X REDSOCKS
    fi
}


set_iptables(){
    iptables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner $redsocks_user  -j REDSOCKS
}

unset_iptables(){
    ids=`iptables -t nat -nL OUTPUT --line-number | grep REDSOCKS | awk '{print $1}'`
    if [ -z "$ids" ]; then
        socks_loging "No Set Iptables ..."
        return
    fi
    id_array=(${ids//\\n/ })
    socks_loging "REDSOCKS OUTPUT Chian ID : $id_array"
    for id in ${id_array[@]}
    do
        id=`echo $id|egrep -o "[0-9]{1,4}"`
        if [ $id!="" ]; then
            iptables -t nat -D OUTPUT $id
        fi
    done
}




if [ -z "$1" ]; then
    echo "[*] Usage : $0 <start | stop | clean | install | uninstall | change IP PORT | pentest IP PORT>
        $0 start : 启动redsocks，自动设置iptables
        $0 stop : 停止redsocks，自动清空iptables
        $0 clean : 清空iptables所有规则
        $0 install : 安装iptables规则
        $0 uninstall : 卸载iptables规则
        $0 change : 改变Socks的IP和端口
        $0 pentest : 开始内网渗透，传入Socks的IP和端口
    "
    exit 0
fi



if [ "$1" = "install" ]; then
    install_iptables
    exit 0
fi

if [ "$1" = "pentest" ]; then
    start_pentest $2 $3
    exit 0
fi


if [ "$1" = "change" ]; then
    change_socks $2 $3
    exit 0
fi


if [ "$1" = "stop" ]; then
    pkill redsocks
    unset_iptables
    exit 0
fi

if [ "$1" = "uninstall" ]; then
    pkill redsocks
    uninstall_iptables
    exit 0
fi

if [ "$1" = "clean" ]; then
    iptables -t nat -F

    iptables -t nat -X

    iptables -t nat -P PREROUTING ACCEPT

    iptables -t nat -P POSTROUTING ACCEPT

    iptables -t nat -P OUTPUT ACCEPT

    iptables -t mangle -F

    iptables -t mangle -X

    iptables -t mangle -P PREROUTING ACCEPT

    iptables -t mangle -P INPUT ACCEPT

    iptables -t mangle -P FORWARD ACCEPT

    iptables -t mangle -P OUTPUT ACCEPT

    iptables -t mangle -P POSTROUTING ACCEPT

    iptables -F

    iptables -X

    iptables -P FORWARD ACCEPT

    iptables -P INPUT ACCEPT

    iptables -P OUTPUT ACCEPT

    iptables -t raw -F

    iptables -t raw -X

    iptables -t raw -P PREROUTING ACCEPT

    iptables -t raw -P OUTPUT ACCEPT
    socks_loging "Clean Iptables ..."
    exit 0
fi


if [ "$1" = "start" ]; then
    is_redsocks=`ps -aux | grep "redsocks -c" -c`
    if [ "$is_redsocks" != "1" ]; then
        pkill redsocks
    fi
    socks_options=$(curl $socks_api_url)
    socks_options=${socks_options%?} # 去除最后一位

    socks_loging "Get Socks: $socks_options" 

    socks_ip=$(echo $socks_options|awk -F : '{print $1}');
    socks_port=$(echo $socks_options|awk -F : '{print $2}');
    socks_loging "Socks IP : $socks_ip, Socks Port : $socks_port";

    if [ -z `echo $socks_ip|egrep -o "([0-9]{1,3}.){3}[0-9]{1,3}"` ] || [ -z `echo $socks_port | egrep -o "[0-9]{1,4}"` ] ; then
        socks_loging "Fomat is Error!"
        exit 8
    fi
    unset_iptables
    change_socks $socks_ip $socks_port
    
    set_iptables
    exit 0
fi
