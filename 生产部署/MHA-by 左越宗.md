# MHA
## 前    言  
MHA 是当 master 出现故障，挑选一个 slave 作为新的 master 并构建成新的主从架构的管理工具。<br/>
从 master 出现故障到构建成新的主从架构时间是 10-30秒。<br/>
在 master 出现故障时可能会出现 slave 同步的数据不一致的现象，此工具可以自动应用差异的中继日志到其他 slave 上保证数据的一致性。<br/>
## Mha 优点
### Master crash 时可以快速的进行故障切换。<br/>
9-12 秒内可以检测到 master 故障， 7-10 秒内可以关闭 master 机器避免脑裂，在几秒内可以应用差异日志，并构建新的主从架构，整个过程大约在 10-30秒内可以完成，最大化的减少故障修复时间。<br/>
### Master crash 时可以最大化的减少数据丢失
当 master crash 时 MHA 自动检测选择数据同步最全的 slave，并把差异日志应用到其他 slave 上， 以保障数据的一致性。结合使用 mysql 
### Semi-Synchronous Replication 可以最大化的减少数据的丢失。<br/>
MHA 的更改升级配置等不影响线上正在运行的数据库使用 mha 不需要增加太多的服务器MHA 由 MHA Manager 和 MHA Node 组成。 MHA Node 运行在 MYSQL 服务器上，所以不会因为 MHA node 增加新的服务器。MHA Manager 通常需要独立运行在一台服务器上，所以你需要增加一台服务器用于监控管理运行 MHA Manager，但是一台服务器上的 MHA Manager 可以同时监控管理多达百台 master，所以总的来说服务器增加不会太多。<br/>
MHA Manger 也可以运行在一台 slave 上，这样总的服务器数也不会增加。
### 原来应用系统整体性能不会降低太多
MHA 工作在异步或半同步的主从架构上。当监控 master 时，MHA 会每隔 5 秒 （默认 3 秒） 向 master 发出 ping 包并且不需要大的 sql 语句用于监控 master的健康状况。<br/>
Slave 需要开启 binlog，整体性能不会有太大的降低。MHA 适合任何存储引擎
只要能主从复制的存储引擎它都支持，不限于支持事物的 innodb 引擎。
## Mha 部署测试文档 
## 安  装
共有 4 台服务器： 一个管理服务器，一个 master 服务器，两个 slave 服务器。
操作系统 Centos 6.4 64 bit 。
192.168.186.141 MYSQL.COM
192.168.186.142 SLAVE1.COM
192.168.186.146 SLAVE2.COM
192.168.186.144 MANAGER.COM
数据库版本mysql-5.6.10
### 1.首先在三台机器上装编译安装MYSQL-5.6.10
关闭selinux iptables 服务以便后期主从同步不出错
```shell
[root@MYSQL ~]# cd /usr/local/src/
[root@MYSQL src]# ls
installmysql5.sh  mysql-5.6.10  mysql-5.6.10.tar.gz
[root@MYSQL src]# sh installmysql5.sh 
please enter you mysql version (eg:/mysql-5.5.34):mysql-5.6.10
please enter you mysql datadir (eg:/data/mysql/data):/home/mysql/data 
```        
 
### 2.配置HOSTS环境
```
[root@MANAGER ~]# vi /etc/hosts

[root@MYSQL etc]# vi /etc/hosts

127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.186.141 MYSQL.COM
192.168.186.142 SLAVE1.COM
192.168.186.146 SLAVE2.COM
192.168.186.144 MANAGER.COM

[root@MYSQL etc]# for i in  142 146 144;do scp /etc/hosts 192.168.186.$i:/etc/;done
root@192.168.186.142's password: 
Permission denied, please try again.
root@192.168.186.142's password: 
Permission denied, please try again.
root@192.168.186.142's password: 
hosts                                                                         100%  266     0.3KB/s   00:00    
root@192.168.186.146's password: 
hosts                                                                         100%  266     0.3KB/s   00:00    
root@192.168.186.144's password: 
```
 
### 3.安装MYSQL 主从半同步
```
# 所有mysql数据库服务器，安装半同步插件(semisync_master.so,semisync_slave.so)  
mysql> install plugin rpl_semi_sync_master soname 'semisync_master.so';      
mysql> install plugin rpl_semi_sync_slave soname 'semisync_slave.so';  

[root@MYSQL etc]vi /etc/my.cnf
[mysqld]
rpl_semi_sync_master_enabled=1
rpl_semi_sync_master_timeout=1000
rpl_semi_sync_slave_enabled=1
relay_log_purge=0
#socket=/usr/mysql.sock
#auto_increment_offset = 2
#auto_increment_increment = 2
server-id = 1
log-bin=mysql-bin
三台机器可以全部开启 仅仅server-id不同


mysql> show variables like '%sync%';  
# 查看半同步状态：  
mysql> show status like '%sync%';  
# 有几个状态参数值得关注的：  
rpl_semi_sync_master_status：显示主服务是异步复制模式还是半同步复制模式  
rpl_semi_sync_master_clients：显示有多少个从服务器配置为半同步复制模式  
rpl_semi_sync_master_yes_tx：显示从服务器确认成功提交的数量  
rpl_semi_sync_master_no_tx：显示从服务器确认不成功提交的数量  
rpl_semi_sync_master_tx_avg_wait_time：事务因开启semi_sync，平均需要额外等待的时间  
rpl_semi_sync_master_net_avg_wait_time：事务进入等待队列后，到网络平均等待时间  

 [root@MYSQL src]# service mysqld restart 每台机器重启
```
每一台机器配置互相无交互
```
[root@MYSQL src]# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.186.141 MYSQL.COM
192.168.186.142 SLAVE1.COM
192.168.186.146 SLAVE2.COM
192.168.186.144 MANAGER.COM

[root@MYSQL src]# ssh-keygen 
[root@MYSQL src]# ssh-copy-id 192.168.186.142
[root@MYSQL src]# ssh-copy-id 192.168.186.144
[root@MYSQL src]# ssh-copy-id 192.168.186.146
```
其他台配置方法与以上一致 保证每台互相无交互
配置完成后每一个都登录一次
```
[root@MYSQL ~]# ssh MANAGER.COM
[root@MYSQL ~]# ssh SLAVE1.COM
[root@MYSQL ~]# ssh SALVE2.COM
```
作用首次连接需要输入一次YES 在know-hosts问价记录，达成无交互
配置主从
执行主从脚本
建议自己做 用这个脚本要是后期带来各种不便 不要怪我

```shell
[root@MYSQL src]# sh mslave.sh 
please enter you mysql SLAVEIP  (eg:192.168.152.138):192.168.186.142
please enter you master mysql password  (eg:yunwei123):123
please enter you slave mysql password  (eg:yunwei123):123
please enter you master mysql binlog  (eg:mysql-bin.000001):mysql-bin.000001

[root@MYSQL src]# sh mslave.sh 
please enter you mysql SLAVEIP  (eg:192.168.152.138):192.168.186.146
please enter you master mysql password  (eg:yunwei123):123  这个是你的主MYSQL 登录密码
please enter you slave mysql password  (eg:yunwei123):123    这个是你的从的MYSQL登录密码
please enter you master mysql binlog  (eg:mysql-bin.000001):mysql-bin.000001
```
至此MYSQL 安装主从半同步配置完成


安装MHA
每台机器做如下操作
```
[root@SLAVE2 data]#rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
 
[root@MANAGER src]# yum clean all
Loaded plugins: fastestmirror, refresh-packagekit, security
Cleaning repos: epel name
Cleaning up Everything
Cleaning up list of fastest mirrors

[root@MANAGER src]# yum makecache

[root@MANAGER src]# rpm --import /etc/pki/rpm-gpg/*

[root@SLAVE2 data]# yum  -y install perl-DBD-MySQL perl-Config-Tiny perl-Log-Dispatch perl-Parallel-ForkManager perl-Config-IniFiles  ncftp perl-Params-Validate  perl-CPAN perl-Test-Mock-LWP.noarch perl-LWP-Authen-Negotiate.noarch perl-devel 

 [root@SLAVE2 data]#yum install perl-ExtUtils-CBuilder perl-ExtUtils-MakeMaker  
 ```
 这个百度文档没有但是显然是要装的
以下操作管理节点需要两个都安装，在3台数据库节点只要安装MHA的node节点：
* 1	# 如果安装下面包，报依赖关系错，请先安装mysql-share-compat包  
* 2	# 先安装下面的 perl-dbd-mysql包  
* 3	# 在下面执行perl时，如果出现报错，需要安装如下这几个perl包： perl-devel perl-CPAN  
```
[root@MANAGER src]# tar -xf mha4mysql-node-0.53.tar.gz 
[root@MANAGER src]# cd mha4mysql-node-0.53
[root@MANAGER mha4mysql-node-0.53]# perl Makefile.PL          
[root@MANAGER mha4mysql-node-0.53]# make && make install      黄色字体这部分是每一台节点都要做的

[root@MANAGER src]# tar -xf  mha4mysql-manager-0.53.tar.gz
[root@MANAGER src]# cd mha4mysql-manager-0.53
[root@MANAGER mha4mysql-manager-0.53]# perl Makefile.PL 
[root@MANAGER mha4mysql-manager-0.53]# make && make install
```
根据提示输入 如果中间有卡顿现象 直接crtl+c 然后继续会出现下载的进度条，说明是正常的
```
[root@MANAGER src]# mkdir /etc/masterha
[root@MANAGER mha]# mkdir -p /master/app1
[root@MANAGERmha]# mkdir -p /scripts
[root@MANAGER mha]# cp samples/conf/* /etc/masterha/
[root@MANAGERmha]# cp samples/scripts/*  /scripts
[root@MANAGER mha4mysql-manager-0.53]#  cp samples/conf/* /etc/masterha/
[root@MANAGER masterha]# vi app1.cnf 
```
内容如下;
```
[server default]
manager_workdir=/masterha/app1
manager_log=/masterha/app1/manager.log
user=mha_mon
password=123
ssh_user=root
repl_user=slave
repl_password=yunwei123
ping_interval=1
shutdown_script=""
master_ip_online_change_script=""
report_script=""

[server1]
hostname=192.168.186.141
master_binlog_dir=/data/mysql/data
candidate_master=1

[server2]
hostname=192.168.186.142
master_binlog_dir=/data/mysql/data
candidate_master=1

[server3]
hostname=192.168.186.146
master_binlog_dir=/data/mysql/data
no_master=1
```
保存退出！
```
[root@MANAGER masterha]# >masterha_default.cnf 

[root@MANAGER masterha]# masterha_check_ssh --global_conf=/etc/masterha/masterha_default.cnf  --conf=/etc/masterha/app1.cnf
Wed Jul  9 02:26:57 2014 - [info] Reading default configuratoins from /etc/masterha/masterha_default.cnf..
Wed Jul  9 02:26:57 2014 - [info] Reading application default configurations from /etc/masterha/app1.cnf..
Wed Jul  9 02:26:57 2014 - [info] Reading server configurations from /etc/masterha/app1.cnf..
Wed Jul  9 02:26:57 2014 - [info] Starting SSH connection tests..
Wed Jul  9 02:26:58 2014 - [debug] 
Wed Jul  9 02:26:57 2014 - [debug]  Connecting via SSH from root@192.168.186.141(192.168.186.141:22) to root@192.168.186.142(192.168.186.142:22)..
Wed Jul  9 02:26:57 2014 - [debug]   ok.
Wed Jul  9 02:26:57 2014 - [debug]  Connecting via SSH from root@192.168.186.141(192.168.186.141:22) to root@192.168.186.146(192.168.186.146:22)..
Wed Jul  9 02:26:57 2014 - [debug]   ok.
Wed Jul  9 02:26:58 2014 - [debug] 
Wed Jul  9 02:26:57 2014 - [debug]  Connecting via SSH from root@192.168.186.142(192.168.186.142:22) to root@192.168.186.141(192.168.186.141:22)..
Wed Jul  9 02:26:57 2014 - [debug]   ok.
Wed Jul  9 02:26:57 2014 - [debug]  Connecting via SSH from root@192.168.186.142(192.168.186.142:22) to root@192.168.186.146(192.168.186.146:22)..
 
Wed Jul  9 02:26:58 2014 - [debug]   ok.
Wed Jul  9 02:26:58 2014 - [debug] 
Wed Jul  9 02:26:58 2014 - [debug]  Connecting via SSH from root@192.168.186.146(192.168.186.146:22) to root@192.168.186.141(192.168.186.141:22)..
Wed Jul  9 02:26:58 2014 - [debug]   ok.
Wed Jul  9 02:26:58 2014 - [debug]  Connecting via SSH from root@192.168.186.146(192.168.186.146:22) to root@192.168.186.142(192.168.186.142:22)..
Wed Jul  9 02:26:58 2014 - [debug]   ok.
Wed Jul  9 02:26:58 2014 - [info] All SSH connection tests passed successfully.
```

登入每台数据库
```
mysql> grant all privileges on *.* to mha_mon@'%' identified by '123';
Query OK, 0 rows affected (1.00 sec)

mysql> flush privileges;
Query OK, 0 rows affected (0.01 sec)

[root@SLAVE1 ~]# ln -s /usr/local/mysql/bin/* /usr/bin 在每台MYSQL 服务器上做这件事情 极度重要哦

mysql>set global read_only=1;  set  global  relay_log_purge=0;  在从上执行 或者干脆写到my.cnf文件里面最好

[root@SLAVE1 ~]# vi /etc/my.cnf
read_only=1
slave-skip-errors=1396
```
为什么要跳过这个错误呢 因为啊在主里面删除用户的时候 从会报错说没有这个用户所以跳过这个错误吧


如果数据库存在空的用户 域名的用户 一定要删除否则MHA  连接MYSQL 会报错连不上 一般只要在从上面删除 如果直接没删除也OK 那就OK 吧如果报错登录不了就删除掉吧 或者跳过域名解析，或者你授权的时候记得也授权域名等等方法多种
```sql
mysql> select user,host from mysql.user;
+---------+---------------+
| user    | host          |
+---------+---------------+
| root    | 127.0.0.1     |
| mha_mon | 192.168.186.% |
| repl    | 192.168.186.% |
| slave   | 192.168.186.% |
| root    | ::1           |
|         | SLAVE2.COM    |
| root    | SLAVE2.COM    |
| root    | localhost     |
+---------+---------------+
8 rows in set (0.00 sec)
mysql> drop user 'root'@SLAVE2.COM;
Query OK, 0 rows affected (0.00 sec)
```

```sql
[root@MANAGER masterha]#  masterha_check_repl   --conf=/etc/masterha/app1.cnf
Wed Jul  9 04:23:16 2014 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Wed Jul  9 04:23:16 2014 - [info] Reading application default configurations from /etc/masterha/app1.cnf..
Wed Jul  9 04:23:16 2014 - [info] Reading server configurations from /etc/masterha/app1.cnf..
Wed Jul  9 04:23:16 2014 - [info] MHA::MasterMonitor version 0.53.
Wed Jul  9 04:23:17 2014 - [info] Dead Servers:
Wed Jul  9 04:23:17 2014 - [info] Alive Servers:
Wed Jul  9 04:23:17 2014 - [info]   192.168.186.141(192.168.186.141:3306)
Wed Jul  9 04:23:17 2014 - [info]   192.168.186.142(192.168.186.142:3306)
Wed Jul  9 04:23:17 2014 - [info]   SLAVE2.COM(192.168.186.146:3306)
Wed Jul  9 04:23:17 2014 - [info] Alive Slaves:
Wed Jul  9 04:23:17 2014 - [info]   192.168.186.142(192.168.186.142:3306)  Version=5.6.10-log (oldest major version between slaves) log-bin:enabled
Wed Jul  9 04:23:17 2014 - [info]     Replicating from 192.168.186.141(192.168.186.141:3306)
Wed Jul  9 04:23:17 2014 - [info]     Primary candidate for the new Master (candidate_master is set)
Wed Jul  9 04:23:17 2014 - [info]   SLAVE2.COM(192.168.186.146:3306)  Version=5.6.10-log (oldest major version between slaves) log-bin:enabled
Wed Jul  9 04:23:17 2014 - [info]     Replicating from 192.168.186.141(192.168.186.141:3306)
Wed Jul  9 04:23:17 2014 - [info]     Not candidate for the new Master (no_master is set)
Wed Jul  9 04:23:17 2014 - [info] Current Alive Master: 192.168.186.141(192.168.186.141:3306)
Wed Jul  9 04:23:17 2014 - [info] Checking slave configurations..
Wed Jul  9 04:23:17 2014 - [info] Checking replication filtering settings..
Wed Jul  9 04:23:17 2014 - [info]  binlog_do_db= , binlog_ignore_db= 
Wed Jul  9 04:23:17 2014 - [info]  Replication filtering check ok.
Wed Jul  9 04:23:17 2014 - [info] Starting SSH connection tests..
Wed Jul  9 04:23:18 2014 - [info] All SSH connection tests passed successfully.
Wed Jul  9 04:23:18 2014 - [info] Checking MHA Node version..
Wed Jul  9 04:23:19 2014 - [info]  Version check ok.
Wed Jul  9 04:23:19 2014 - [info] Checking SSH publickey authentication settings on the current master..
Wed Jul  9 04:23:19 2014 - [info] HealthCheck: SSH to 192.168.186.141 is reachable.
Wed Jul  9 04:23:19 2014 - [info] Master MHA Node version is 0.53.
Wed Jul  9 04:23:19 2014 - [info] Checking recovery script configurations on the current master..
Wed Jul  9 04:23:19 2014 - [info]   Executing command: save_binary_logs --command=test --start_pos=4 --binlog_dir=/data/mysql/data --output_file=/var/tmp/save_binary_logs_test --manager_version=0.53 --start_file=mysql-bin.000001 
Wed Jul  9 04:23:19 2014 - [info]   Connecting to root@192.168.186.141(192.168.186.141).. 
  Creating /var/tmp if not exists..    ok.
  Checking output directory is accessible or not..
   ok.
  Binlog found at /data/mysql/data, up to mysql-bin.000001
Wed Jul  9 04:23:20 2014 - [info] Master setting check done.
Wed Jul  9 04:23:20 2014 - [info] Checking SSH publickey authentication and checking recovery script configurations on all alive slave servers..
Wed Jul  9 04:23:20 2014 - [info]   Executing command : apply_diff_relay_logs --command=test --slave_user=mha_mon --slave_host=192.168.186.142 --slave_ip=192.168.186.142 --slave_port=3306 --workdir=/var/tmp --target_version=5.6.10-log --manager_version=0.53 --relay_log_info=/data/mysql/data/relay-log.info  --relay_dir=/data/mysql/data/  --slave_pass=xxx
Wed Jul  9 04:23:20 2014 - [info]   Connecting to root@192.168.186.142(192.168.186.142:22).. 
  Checking slave recovery environment settings..
    Opening /data/mysql/data/relay-log.info ... ok.
    Relay log found at /data/mysql/data, up to SLAVE1-relay-bin.000002
    Temporary relay log file is /data/mysql/data/SLAVE1-relay-bin.000002
    Testing mysql connection and privileges..Warning: Using a password on the command line interface can be insecure.
 done.
    Testing mysqlbinlog output.. done.
    Cleaning up test file(s).. done.
Wed Jul  9 04:23:20 2014 - [info]   Executing command : apply_diff_relay_logs --command=test --slave_user=mha_mon --slave_host=SLAVE2.COM --slave_ip=192.168.186.146 --slave_port=3306 --workdir=/var/tmp --target_version=5.6.10-log --manager_version=0.53 --relay_log_info=/data/mysql/data/relay-log.info  --relay_dir=/data/mysql/data/  --slave_pass=xxx
Wed Jul  9 04:23:20 2014 - [info]   Connecting to root@192.168.186.146(SLAVE2.COM:22).. 
  Checking slave recovery environment settings..
    Opening /data/mysql/data/relay-log.info ... ok.
    Relay log found at /data/mysql/data, up to slave2-relay-bin.000002
    Temporary relay log file is /data/mysql/data/slave2-relay-bin.000002
    Testing mysql connection and privileges..Warning: Using a password on the command line interface can be insecure.
 done.
    Testing mysqlbinlog output.. done.
    Cleaning up test file(s).. done.
Wed Jul  9 04:23:21 2014 - [info] Slaves settings check done.
Wed Jul  9 04:23:21 2014 - [info] 
192.168.186.141 (current master)
 +--192.168.186.142
 +--SLAVE2.COM

Wed Jul  9 04:23:21 2014 - [info] Checking replication health on 192.168.186.142..
Wed Jul  9 04:23:21 2014 - [info]  ok.
Wed Jul  9 04:23:21 2014 - [info] Checking replication health on SLAVE2.COM..
Wed Jul  9 04:23:21 2014 - [info]  ok.
Wed Jul  9 04:23:21 2014 - [warning] master_ip_failover_script is not defined.
Wed Jul  9 04:23:21 2014 - [warning] shutdown_script is not defined.
Wed Jul  9 04:23:21 2014 - [info] Got exit code 0 (Not master dead).

MySQL Replication Health is OK.
```

至此说明你的MHA 已经配置好了

```
[root@MANAGER ~]# nohup masterha_manager --conf=/etc/mastermha/app1.cnf > /tmp/mha_manager.log  </dev/null 2>&1 &   启动MHA 
``` 
 

测试重构
测试
测试 将MYSQL.COM机器上的MYSQL服务关闭 ，注意观察 manager.log  日志会发现 切换到了SLAVE1.COM 并且SLAVE1.COM变成了主  而SLAVE2.COM 则变成了SLAVE1.COM 的从
```
[root@MANAGER app1]# tail -f manager.log   这是启动后还没关闭主数据库的日志内容
192.168.186.141 (current master)
 +--192.168.186.142
 +--SLAVE2.COM

Wed Jul  9 18:52:32 2014 - [warning] master_ip_failover_script is not defined.
Wed Jul  9 18:52:32 2014 - [warning] shutdown_script is not defined.
Wed Jul  9 18:52:32 2014 - [info] Set master ping interval 1 seconds.
Wed Jul  9 18:52:32 2014 - [warning] secondary_check_script is not defined. It is highly recommended setting it to check master reachability from two or more routes.
Wed Jul  9 18:52:32 2014 - [info] Starting ping health check on 192.168.186.141(192.168.186.141:3306)..
Wed Jul  9 18:52:32 2014 - [info] Ping(SELECT) succeeded, waiting until MySQL doesn't respond..

[root@MYSQL ~]# service mysqld stop
Shutting down MySQL..... SUCCESS! 


[root@MANAGER app1]# tail -f manager.log   最要看最后几行 就知道有没有切换成功
192.168.186.141 (current master)
 +--192.168.186.142
 +--SLAVE2.COM
Wed Jul  9 18:56:47 2014 - [info] Dead Servers:
Wed Jul  9 18:56:47 2014 - [info]   192.168.186.141(192.168.186.141:3306)
Wed Jul  9 18:56:47 2014 - [info] Alive Servers:
Wed Jul  9 18:56:47 2014 - [info]   192.168.186.142(192.168.186.142:3306)
Wed Jul  9 18:56:47 2014 - [info]   SLAVE2.COM(192.168.186.146:3306)
Wed Jul  9 18:56:47 2014 - [info] Alive Slaves:
Wed Jul  9 18:56:47 2014 - [info]   192.168.186.142(192.168.186.142:3306)  Version=5.6.10-log (oldest major version between slaves) log-bin:enabled
Wed Jul  9 18:56:47 2014 - [info]     Replicating from 192.168.186.141(192.168.186.141:3306)
Wed Jul  9 18:56:47 2014 - [info]     Primary candidate for the new Master (candidate_master is set)
Wed Jul  9 18:56:47 2014 - [info]   SLAVE2.COM(192.168.186.146:3306)  Version=5.6.10-log (oldest major version between slaves) log-bin:enabled
Wed Jul  9 18:56:47 2014 - [info]     Replicating from 192.168.186.141(192.168.186.141:3306)
Wed Jul  9 18:56:47 2014 - [info]     Not candidate for the new Master (no_master is set)
Wed Jul  9 18:56:47 2014 - [info] Checking slave configurations..
Wed Jul  9 18:56:47 2014 - [info] Checking replication filtering settings..
Wed Jul  9 18:56:47 2014 - [info]  Replication filtering check ok.
Wed Jul  9 18:56:47 2014 - [info] Master is down!
Wed Jul  9 18:56:47 2014 - [info] Terminating monitoring script.
Wed Jul  9 18:56:47 2014 - [info] Got exit code 20 (Master dead).
Wed Jul  9 18:56:47 2014 - [info] MHA::MasterFailover version 0.53.
Wed Jul  9 18:56:47 2014 - [info] Starting master failover.
Wed Jul  9 18:56:47 2014 - [info] * Phase 2: Dead Master Shutdown Phase completed.
Wed Jul  9 18:56:47 2014 - [info]   192.168.186.142(192.168.186.142:3306)  Version=5.6.10-log (oldest major version between slaves) log-bin:enabled
Wed Jul  9 18:56:47 2014 - [info]     Replicating from 192.168.186.141(192.168.186.141:3306)
Wed Jul  9 18:56:47 2014 - [info]     Primary candidate for the new Master (candidate_master is set)
Wed Jul  9 18:56:47 2014 - [info]   SLAVE2.COM(192.168.186.146:3306)  Version=5.6.10-log (oldest major version between slaves) log-bin:enabled
Wed Jul  9 18:56:47 2014 - [info]     Replicating from 192.168.186.141(192.168.186.141:3306)
Wed Jul  9 18:56:47 2014 - [info]     Not candidate for the new Master (no_master is set)
Wed Jul  9 18:56:47 2014 - [info] The oldest binary log file/position on all slaves is mysql-bin.000001:214
Wed Jul  9 18:56:47 2014 - [info] Oldest slaves:
Wed Jul  9 18:56:47 2014 - [info]   192.168.186.142(192.168.186.142:3306)  Version=5.6.10-log (oldest major version between slaves) log-bin:enabled
Wed Jul  9 18:56:47 2014 - [info]     Replicating from 192.168.186.141(192.168.186.141:3306)
Wed Jul  9 18:56:47 2014 - [info]     Primary candidate for the new Master (candidate_master is set)
Wed Jul  9 18:56:47 2014 - [info]   SLAVE2.COM(192.168.186.146:3306)  Version=5.6.10-log (oldest major version between slaves) log-bin:enabled
Wed Jul  9 18:56:47 2014 - [info]     Replicating from 192.168.186.141(192.168.186.141:3306)
Wed Jul  9 18:56:47 2014 - [info]     Not candidate for the new Master (no_master is set)
Wed Jul  9 18:56:47 2014 - [info] 
Wed Jul  9 18:56:47 2014 - [info] * Phase 3.2: Saving Dead Master's Binlog Phase..
Wed Jul  9 18:56:47 2014 - [info] 
Wed Jul  9 18:56:48 2014 - [info] Fetching dead master's binary logs..
Wed Jul  9 18:56:48 2014 - [info] Executing command on the dead master 192.168.186.141(192.168.186.141:3306): save_binary_logs --command=save --start_file=mysql-bin.000001  --start_pos=214 --binlog_dir=/data/mysql/data --output_file=/var/tmp/saved_master_binlog_from_192.168.186.141_3306_20140709185647.binlog --handle_raw_binlog=1 --disable_log_bin=0 --manager_version=0.53
  Creating /var/tmp if not exists..    ok.
 Concat binary/relay logs from mysql-bin.000001 pos 214 to mysql-bin.000001 EOF into /var/tmp/saved_master_binlog_from_192.168.186.141_3306_20140709185647.binlog ..
  Dumping binlog format description event, from position 0 to 120.. ok.
  Dumping effective binlog data from /data/mysql/data/mysql-bin.000001 position 214 to tail(237).. ok.
 Concat succeeded.
Wed Jul  9 18:56:48 2014 - [info] scp from root@192.168.186.141:/var/tmp/saved_master_binlog_from_192.168.186.141_3306_20140709185647.binlog to local:/masterha/app1/saved_master_binlog_from_192.168.186.141_3306_20140709185647.binlog succeeded.
Wed Jul  9 18:56:49 2014 - [info] HealthCheck: SSH to 192.168.186.142 is reachable.
Wed Jul  9 18:56:49 2014 - [info] HealthCheck: SSH to SLAVE2.COM is reachable.
Wed Jul  9 18:56:49 2014 - [info] 
Wed Jul  9 18:56:49 2014 - [info] * Phase 3.3: Determining New Master Phase..
Wed Jul  9 18:56:49 2014 - [info] 
Wed Jul  9 18:56:49 2014 - [info] Finding the latest slave that has all relay logs for recovering other slaves..
Wed Jul  9 18:56:49 2014 - [info] All slaves received relay logs to the same position. No need to resync each other.
Wed Jul  9 18:56:49 2014 - [info] Searching new master from slaves..
Wed Jul  9 18:56:49 2014 - [info]  Candidate masters from the configuration file:
Wed Jul  9 18:56:49 2014 - [info]   192.168.186.142(192.168.186.142:3306)  Version=5.6.10-log (oldest major version between slaves) log-bin:enabled
Wed Jul  9 18:56:49 2014 - [info]     Replicating from 192.168.186.141(192.168.186.141:3306)
Wed Jul  9 18:56:49 2014 - [info]     Primary candidate for the new Master (candidate_master is set)
Wed Jul  9 18:56:49 2014 - [info]  Non-candidate masters:
Wed Jul  9 18:56:49 2014 - [info]   SLAVE2.COM(192.168.186.146:3306)  Version=5.6.10-log (oldest major version between slaves) log-bin:enabled
Wed Jul  9 18:56:49 2014 - [info]     Replicating from 192.168.186.141(192.168.186.141:3306)
Wed Jul  9 18:56:49 2014 - [info]     Not candidate for the new Master (no_master is set)
Wed Jul  9 18:56:49 2014 - [info]  Searching from candidate_master slaves which have received the latest relay log events..
Wed Jul  9 18:56:49 2014 - [info] New master is 192.168.186.142(192.168.186.142:3306)
Wed Jul  9 18:56:49 2014 - [info] Starting master failover..
Wed Jul  9 18:56:49 2014 - [info] 
From:
192.168.186.141 (current master)
 +--192.168.186.142
 +--SLAVE2.COM

To:
192.168.186.142 (new master)
 +--SLAVE2.COM
Wed Jul  9 18:56:49 2014 - [info] 
Wed Jul  9 18:56:49 2014 - [info] * Phase 3.3: New Master Diff Log Generation Phase..
Wed Jul  9 18:56:49 2014 - [info] 
Wed Jul  9 18:56:49 2014 - [info]  This server has all relay logs. No need to generate diff files from the latest slave.
Wed Jul  9 18:56:49 2014 - [info] Sending binlog..
Wed Jul  9 18:56:50 2014 - [info] scp from local:/masterha/app1/saved_master_binlog_from_192.168.186.141_3306_20140709185647.binlog to root@192.168.186.142:/var/tmp/saved_master_binlog_from_192.168.186.141_3306_20140709185647.binlog succeeded.
Wed Jul  9 18:56:50 2014 - [info] 
Wed Jul  9 18:56:50 2014 - [info] * Phase 3.4: Master Log Apply Phase..
Wed Jul  9 18:56:50 2014 - [info] 
Wed Jul  9 18:56:50 2014 - [info] *NOTICE: If any error happens from this phase, manual recovery is needed.
Wed Jul  9 18:56:50 2014 - [info] Starting recovery on 192.168.186.142(192.168.186.142:3306)..
Wed Jul  9 18:56:50 2014 - [info]  Generating diffs succeeded.
Wed Jul  9 18:56:50 2014 - [info] Waiting until all relay logs are applied.
Wed Jul  9 18:56:50 2014 - [info]  done.
Wed Jul  9 18:56:50 2014 - [info] Getting slave status..
Wed Jul  9 18:56:50 2014 - [info] This slave(192.168.186.142)'s Exec_Master_Log_Pos equals to Read_Master_Log_Pos(mysql-bin.000001:214). No need to recover from Exec_Master_Log_Pos.
Wed Jul  9 18:56:50 2014 - [info] Connecting to the target slave host 192.168.186.142, running recover script..
Wed Jul  9 18:56:50 2014 - [info] Executing command: apply_diff_relay_logs --command=apply --slave_user=mha_mon --slave_host=192.168.186.142 --slave_ip=192.168.186.142  --slave_port=3306 --apply_files=/var/tmp/saved_master_binlog_from_192.168.186.141_3306_20140709185647.binlog --workdir=/var/tmp --target_version=5.6.10-log --timestamp=20140709185647 --handle_raw_binlog=1 --disable_log_bin=0 --manager_version=0.53 --slave_pass=xxx
Wed Jul  9 18:56:50 2014 - [info] 
MySQL client version is 5.6.10. Using --binary-mode.
Applying differential binary/relay log files /var/tmp/saved_master_binlog_from_192.168.186.141_3306_20140709185647.binlog on 192.168.186.142:3306. This may take long time...
Applying log files succeeded.
Wed Jul  9 18:56:50 2014 - [info]  All relay logs were successfully applied.
Wed Jul  9 18:56:50 2014 - [info] Getting new master's binlog name and position..
Wed Jul  9 18:56:50 2014 - [info]  mysql-bin.000007:504
Wed Jul  9 18:56:50 2014 - [info]  All other slaves should start replication from here. Statement should be: CHANGE MASTER TO MASTER_HOST='192.168.186.142', MASTER_PORT=3306, MASTER_LOG_FILE='mysql-bin.000007', MASTER_LOG_POS=504, MASTER_USER='repl', MASTER_PASSWORD='xxx';
Wed Jul  9 18:56:50 2014 - [warning] master_ip_failover_script is not set. Skipping taking over new master ip address.
Wed Jul  9 18:56:50 2014 - [info] Setting read_only=0 on 192.168.186.142(192.168.186.142:3306)..
Wed Jul  9 18:56:50 2014 - [info]  ok.
Wed Jul  9 18:56:50 2014 - [info] ** Finished master recovery successfully.
Wed Jul  9 18:56:50 2014 - [info] * Phase 3: Master Recovery Phase completed.
Wed Jul  9 18:56:50 2014 - [info] 
Wed Jul  9 18:56:50 2014 - [info] * Phase 4: Slaves Recovery Phase..
Wed Jul  9 18:56:50 2014 - [info] 
Wed Jul  9 18:56:50 2014 - [info] * Phase 4.1: Starting Parallel Slave Diff Log Generation Phase..
Wed Jul  9 18:56:50 2014 - [info] 
Wed Jul  9 18:56:50 2014 - [info] -- Slave diff file generation on host SLAVE2.COM(192.168.186.146:3306) started, pid: 3135. Check tmp log /masterha/app1/SLAVE2.COM_3306_20140709185647.log if it takes time..
Wed Jul  9 18:56:50 2014 - [info] 
Wed Jul  9 18:56:50 2014 - [info] Log messages from SLAVE2.COM ...
Wed Jul  9 18:56:50 2014 - [info] 
Wed Jul  9 18:56:50 2014 - [info]  This server has all relay logs. No need to generate diff files from the latest slave.
Wed Jul  9 18:56:50 2014 - [info] End of log messages from SLAVE2.COM.
Wed Jul  9 18:56:50 2014 - [info] -- SLAVE2.COM(192.168.186.146:3306) has the latest relay log events.
Wed Jul  9 18:56:50 2014 - [info] Generating relay diff files from the latest slave succeeded.
Wed Jul  9 18:56:50 2014 - [info] 
Wed Jul  9 18:56:50 2014 - [info] * Phase 4.2: Starting Parallel Slave Log Apply Phase..
Wed Jul  9 18:56:50 2014 - [info] 
Wed Jul  9 18:56:50 2014 - [info] -- Slave recovery on host SLAVE2.COM(192.168.186.146:3306) started, pid: 3137. Check tmp log /masterha/app1/SLAVE2.COM_3306_20140709185647.log if it takes time..
Wed Jul  9 18:56:51 2014 - [info] 
Wed Jul  9 18:56:51 2014 - [info] Log messages from SLAVE2.COM ...
Wed Jul  9 18:56:51 2014 - [info] 
Wed Jul  9 18:56:50 2014 - [info] Sending binlog..
Wed Jul  9 18:56:51 2014 - [info] scp from local:/masterha/app1/saved_master_binlog_from_192.168.186.141_3306_20140709185647.binlog to root@SLAVE2.COM:/var/tmp/saved_master_binlog_from_192.168.186.141_3306_20140709185647.binlog succeeded.
Wed Jul  9 18:56:51 2014 - [info] Starting recovery on SLAVE2.COM(192.168.186.146:3306)..
Wed Jul  9 18:56:51 2014 - [info]  Generating diffs succeeded.
Wed Jul  9 18:56:51 2014 - [info] Waiting until all relay logs are applied.
Wed Jul  9 18:56:51 2014 - [info]  done.
Wed Jul  9 18:56:51 2014 - [info] Getting slave status..
Wed Jul  9 18:56:51 2014 - [info] This slave(SLAVE2.COM)'s Exec_Master_Log_Pos equals to Read_Master_Log_Pos(mysql-bin.000001:214). No need to recover from Exec_Master_Log_Pos.
Wed Jul  9 18:56:51 2014 - [info] Connecting to the target slave host SLAVE2.COM, running recover script..
Wed Jul  9 18:56:51 2014 - [info] Executing command: apply_diff_relay_logs --command=apply --slave_user=mha_mon --slave_host=SLAVE2.COM --slave_ip=192.168.186.146  --slave_port=3306 --apply_files=/var/tmp/saved_master_binlog_from_192.168.186.141_3306_20140709185647.binlog --workdir=/var/tmp --target_version=5.6.10-log --timestamp=20140709185647 --handle_raw_binlog=1 --disable_log_bin=0 --manager_version=0.53 --slave_pass=xxx
Wed Jul  9 18:56:51 2014 - [info] 
MySQL client version is 5.6.10. Using --binary-mode.
Applying differential binary/relay log files /var/tmp/saved_master_binlog_from_192.168.186.141_3306_20140709185647.binlog on SLAVE2.COM:3306. This may take long time...
Applying log files succeeded.
Wed Jul  9 18:56:51 2014 - [info]  All relay logs were successfully applied.
Wed Jul  9 18:56:51 2014 - [info]  Resetting slave SLAVE2.COM(192.168.186.146:3306) and starting replication from the new master 192.168.186.142(192.168.186.142:3306)..
Wed Jul  9 18:56:51 2014 - [info]  Executed CHANGE MASTER.
Wed Jul  9 18:56:51 2014 - [info]  Slave started.
Wed Jul  9 18:56:51 2014 - [info] End of log messages from SLAVE2.COM.
Wed Jul  9 18:56:51 2014 - [info] -- Slave recovery on host SLAVE2.COM(192.168.186.146:3306) succeeded.
Wed Jul  9 18:56:51 2014 - [info] All new slave servers recovered successfully.
Wed Jul  9 18:56:51 2014 - [info] 
Wed Jul  9 18:56:51 2014 - [info] * Phase 5: New master cleanup phease..
Wed Jul  9 18:56:51 2014 - [info] 
Wed Jul  9 18:56:51 2014 - [info] Resetting slave info on the new master..
Wed Jul  9 18:56:51 2014 - [info]  192.168.186.142: Resetting slave info succeeded.
Wed Jul  9 18:56:51 2014 - [info] Master failover to 192.168.186.142(192.168.186.142:3306) completed successfully.
Wed Jul  9 18:56:51 2014 - [info] 

----- Failover Report -----

app1: MySQL Master failover 192.168.186.141 to 192.168.186.142 succeeded

Master 192.168.186.141 is down!

Check MHA Manager logs at MANAGER.COM:/masterha/app1/manager.log for details.

Started automated(non-interactive) failover.
The latest slave 192.168.186.142(192.168.186.142:3306) has all relay logs for recovery.
Selected 192.168.186.142 as a new master.
192.168.186.142: OK: Applying all logs succeeded.
SLAVE2.COM: This host has the latest relay log events.
Generating relay diff files from the latest slave succeeded.
SLAVE2.COM: OK: Applying all logs succeeded. Slave started, replicating from 192.168.186.142.
192.168.186.142: Resetting slave info succeeded.
Master failover to 192.168.186.142(192.168.186.142:3306) completed successfully.  说明切换成功了


[root@slave2 ~]# mysql -e "show slave status\G"
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.186.142
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000007
          Read_Master_Log_Pos: 504
               Relay_Log_File: slave2-relay-bin.000002
                Relay_Log_Pos: 283
        Relay_Master_Log_File: mysql-bin.000007
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
```            
看到已经切换到和142同步了 本来是和141同步的 此时的SALVE1.COM已经变成主了 说明已然生效

重构

重构我想就不要我做了吧，就是这时候等于你的主挂了 切换在SLAVE1.COM 上变成了主 因此重构我提供一种方案（方案多种），拿出一台新的服务器重新加入以142为主做成从 再app1.conf配置文件中加入 
```
[root@MANAGER app1]# rm -rf app1.failover.complete 
```
删除该文件后 再次启动manager端即可

