# MHA
## ǰ    ��  
MHA �ǵ� master ���ֹ��ϣ���ѡһ�� slave ��Ϊ�µ� master ���������µ����Ӽܹ��Ĺ����ߡ�<br/>
�� master ���ֹ��ϵ��������µ����Ӽܹ�ʱ���� 10-30�롣<br/>
�� master ���ֹ���ʱ���ܻ���� slave ͬ�������ݲ�һ�µ����󣬴˹��߿����Զ�Ӧ�ò�����м���־������ slave �ϱ�֤���ݵ�һ���ԡ�<br/>
## Mha �ŵ�
### Master crash ʱ���Կ��ٵĽ��й����л���<br/>
9-12 ���ڿ��Լ�⵽ master ���ϣ� 7-10 ���ڿ��Թر� master �����������ѣ��ڼ����ڿ���Ӧ�ò�����־���������µ����Ӽܹ����������̴�Լ�� 10-30���ڿ�����ɣ���󻯵ļ��ٹ����޸�ʱ�䡣<br/>
### Master crash ʱ������󻯵ļ������ݶ�ʧ
�� master crash ʱ MHA �Զ����ѡ������ͬ����ȫ�� slave�����Ѳ�����־Ӧ�õ����� slave �ϣ� �Ա������ݵ�һ���ԡ����ʹ�� mysql 
### Semi-Synchronous Replication ������󻯵ļ������ݵĶ�ʧ��<br/>
MHA �ĸ����������õȲ�Ӱ�������������е����ݿ�ʹ�� mha ����Ҫ����̫��ķ�����MHA �� MHA Manager �� MHA Node ��ɡ� MHA Node ������ MYSQL �������ϣ����Բ�����Ϊ MHA node �����µķ�������MHA Manager ͨ����Ҫ����������һ̨�������ϣ���������Ҫ����һ̨���������ڼ�ع������� MHA Manager������һ̨�������ϵ� MHA Manager ����ͬʱ��ع������̨ master�������ܵ���˵���������Ӳ���̫�ࡣ<br/>
MHA Manger Ҳ����������һ̨ slave �ϣ������ܵķ�������Ҳ�������ӡ�
### ԭ��Ӧ��ϵͳ�������ܲ��ή��̫��
MHA �������첽���ͬ�������Ӽܹ��ϡ������ master ʱ��MHA ��ÿ�� 5 �� ��Ĭ�� 3 �룩 �� master ���� ping �����Ҳ���Ҫ��� sql ������ڼ�� master�Ľ���״����<br/>
Slave ��Ҫ���� binlog���������ܲ�����̫��Ľ��͡�MHA �ʺ��κδ洢����
ֻҪ�����Ӹ��ƵĴ洢��������֧�֣�������֧������� innodb ���档
## Mha ��������ĵ� 
## ��  װ
���� 4 ̨�������� һ�������������һ�� master ������������ slave ��������
����ϵͳ Centos 6.4 64 bit ��
192.168.186.141 MYSQL.COM
192.168.186.142 SLAVE1.COM
192.168.186.146 SLAVE2.COM
192.168.186.144 MANAGER.COM
���ݿ�汾mysql-5.6.10
### 1.��������̨������װ���밲װMYSQL-5.6.10
�ر�selinux iptables �����Ա��������ͬ��������
```shell
[root@MYSQL ~]# cd /usr/local/src/
[root@MYSQL src]# ls
installmysql5.sh  mysql-5.6.10  mysql-5.6.10.tar.gz
[root@MYSQL src]# sh installmysql5.sh 
please enter you mysql version (eg:/mysql-5.5.34):mysql-5.6.10
please enter you mysql datadir (eg:/data/mysql/data):/home/mysql/data 
```        
 
### 2.����HOSTS����
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
 
### 3.��װMYSQL ���Ӱ�ͬ��
```
# ����mysql���ݿ����������װ��ͬ�����(semisync_master.so,semisync_slave.so)  
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
��̨��������ȫ������ ����server-id��ͬ


mysql> show variables like '%sync%';  
# �鿴��ͬ��״̬��  
mysql> show status like '%sync%';  
# �м���״̬����ֵ�ù�ע�ģ�  
rpl_semi_sync_master_status����ʾ���������첽����ģʽ���ǰ�ͬ������ģʽ  
rpl_semi_sync_master_clients����ʾ�ж��ٸ��ӷ���������Ϊ��ͬ������ģʽ  
rpl_semi_sync_master_yes_tx����ʾ�ӷ�����ȷ�ϳɹ��ύ������  
rpl_semi_sync_master_no_tx����ʾ�ӷ�����ȷ�ϲ��ɹ��ύ������  
rpl_semi_sync_master_tx_avg_wait_time����������semi_sync��ƽ����Ҫ����ȴ���ʱ��  
rpl_semi_sync_master_net_avg_wait_time���������ȴ����к󣬵�����ƽ���ȴ�ʱ��  

 [root@MYSQL src]# service mysqld restart ÿ̨��������
```
ÿһ̨�������û����޽���
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
����̨���÷���������һ�� ��֤ÿ̨�����޽���
������ɺ�ÿһ������¼һ��
```
[root@MYSQL ~]# ssh MANAGER.COM
[root@MYSQL ~]# ssh SLAVE1.COM
[root@MYSQL ~]# ssh SALVE2.COM
```
�����״�������Ҫ����һ��YES ��know-hosts�ʼۼ�¼������޽���
��������
ִ�����ӽű�
�����Լ��� ������ű�Ҫ�Ǻ��ڴ������ֲ��� ��Ҫ����

```shell
[root@MYSQL src]# sh mslave.sh 
please enter you mysql SLAVEIP  (eg:192.168.152.138):192.168.186.142
please enter you master mysql password  (eg:yunwei123):123
please enter you slave mysql password  (eg:yunwei123):123
please enter you master mysql binlog  (eg:mysql-bin.000001):mysql-bin.000001

[root@MYSQL src]# sh mslave.sh 
please enter you mysql SLAVEIP  (eg:192.168.152.138):192.168.186.146
please enter you master mysql password  (eg:yunwei123):123  ����������MYSQL ��¼����
please enter you slave mysql password  (eg:yunwei123):123    �������Ĵӵ�MYSQL��¼����
please enter you master mysql binlog  (eg:mysql-bin.000001):mysql-bin.000001
```
����MYSQL ��װ���Ӱ�ͬ���������


��װMHA
ÿ̨���������²���
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
 ����ٶ��ĵ�û�е�����Ȼ��Ҫװ��
���²�������ڵ���Ҫ��������װ����3̨���ݿ�ڵ�ֻҪ��װMHA��node�ڵ㣺
* 1	# �����װ���������������ϵ�����Ȱ�װmysql-share-compat��  
* 2	# �Ȱ�װ����� perl-dbd-mysql��  
* 3	# ������ִ��perlʱ��������ֱ�����Ҫ��װ�����⼸��perl���� perl-devel perl-CPAN  
```
[root@MANAGER src]# tar -xf mha4mysql-node-0.53.tar.gz 
[root@MANAGER src]# cd mha4mysql-node-0.53
[root@MANAGER mha4mysql-node-0.53]# perl Makefile.PL          
[root@MANAGER mha4mysql-node-0.53]# make && make install      ��ɫ�����ⲿ����ÿһ̨�ڵ㶼Ҫ����

[root@MANAGER src]# tar -xf  mha4mysql-manager-0.53.tar.gz
[root@MANAGER src]# cd mha4mysql-manager-0.53
[root@MANAGER mha4mysql-manager-0.53]# perl Makefile.PL 
[root@MANAGER mha4mysql-manager-0.53]# make && make install
```
������ʾ���� ����м��п������� ֱ��crtl+c Ȼ�������������صĽ�������˵����������
```
[root@MANAGER src]# mkdir /etc/masterha
[root@MANAGER mha]# mkdir -p /master/app1
[root@MANAGERmha]# mkdir -p /scripts
[root@MANAGER mha]# cp samples/conf/* /etc/masterha/
[root@MANAGERmha]# cp samples/scripts/*  /scripts
[root@MANAGER mha4mysql-manager-0.53]#  cp samples/conf/* /etc/masterha/
[root@MANAGER masterha]# vi app1.cnf 
```
��������;
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
�����˳���
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

����ÿ̨���ݿ�
```
mysql> grant all privileges on *.* to mha_mon@'%' identified by '123';
Query OK, 0 rows affected (1.00 sec)

mysql> flush privileges;
Query OK, 0 rows affected (0.01 sec)

[root@SLAVE1 ~]# ln -s /usr/local/mysql/bin/* /usr/bin ��ÿ̨MYSQL ����������������� ������ҪŶ

mysql>set global read_only=1;  set  global  relay_log_purge=0;  �ڴ���ִ�� ���߸ɴ�д��my.cnf�ļ��������

[root@SLAVE1 ~]# vi /etc/my.cnf
read_only=1
slave-skip-errors=1396
```
ΪʲôҪ������������� ��Ϊ����������ɾ���û���ʱ�� �ӻᱨ��˵û������û�����������������


������ݿ���ڿյ��û� �������û� һ��Ҫɾ������MHA  ����MYSQL �ᱨ�������� һ��ֻҪ�ڴ�����ɾ�� ���ֱ��ûɾ��ҲOK �Ǿ�OK ����������¼���˾�ɾ������ ��������������������������Ȩ��ʱ��ǵ�Ҳ��Ȩ�����ȵȷ�������
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

����˵�����MHA �Ѿ����ú���

```
[root@MANAGER ~]# nohup masterha_manager --conf=/etc/mastermha/app1.cnf > /tmp/mha_manager.log  </dev/null 2>&1 &   ����MHA 
``` 
 

�����ع�
����
���� ��MYSQL.COM�����ϵ�MYSQL����ر� ��ע��۲� manager.log  ��־�ᷢ�� �л�����SLAVE1.COM ����SLAVE1.COM�������  ��SLAVE2.COM ������SLAVE1.COM �Ĵ�
```
[root@MANAGER app1]# tail -f manager.log   ����������û�ر������ݿ����־����
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


[root@MANAGER app1]# tail -f manager.log   ��Ҫ������� ��֪����û���л��ɹ�
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
Master failover to 192.168.186.142(192.168.186.142:3306) completed successfully.  ˵���л��ɹ���


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
�����Ѿ��л�����142ͬ���� �����Ǻ�141ͬ���� ��ʱ��SALVE1.COM�Ѿ�������� ˵����Ȼ��Ч

�ع�

�ع�����Ͳ�Ҫ�����˰ɣ�������ʱ�������������� �л���SLAVE1.COM �ϱ������ ����ع����ṩһ�ַ������������֣����ó�һ̨�µķ��������¼�����142Ϊ�����ɴ� ��app1.conf�����ļ��м��� 
```
[root@MANAGER app1]# rm -rf app1.failover.complete 
```
ɾ�����ļ��� �ٴ�����manager�˼���

