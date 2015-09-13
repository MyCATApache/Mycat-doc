## 一.环境介绍

### 1.1. mysql节点1环境
 
- 操作系统版本  : centos6.5 x64
- 数据库版本    : mysql-5.7.4
- mycat版本    ：1.3 release
- 数据库名      : db1
- hostname:c1
- ip:192.168.58.11

### 1.2. mysql节点2环境

- 操作系统版本  : centos6.5 x64
- 数据库版本    : mysql-5.7.4
- mycat版本    ：1.3 release
- 数据库名     : db2
- hostname:c2
- ip:192.168.58.12

### 1.3.mycat环境
   
     安装在c1
    
### 1.4. 前提条件
   两个节点都安装好mysql5.7.4
## 二.安装mycat

### 2.1.创建用户及组
root >

创建一个新的group
 ``` 
 groupadd dba
 ```
创建一个新的用户，并加入group
```
  useradd -g dba mycat
```
给新用户设置密码，
```
  passwd mycat
```

### 2.2.解压
mycat >
```
tar -xzvf Mycat-server-1.3.0.3-release-20150527095523-linux.tar.gz
mkdri /home/mycat/app
mv mycat /home/mycat/app/mycat
```
### 2.3.设置环境变量
 vim /home/mycat/.bash_profile
```
export MYCAT_HOME=/home/mycat/app/mycat
PATH=$PATH:$MYCAT_HOME/bin
```
令修改生效
```
[mycat@c1 ~]$ source .bash_profile
```
**测试是否配置成功**
```
[mycat@c1 ~]$ echo $MYCAT_HOME
/home/mycat/app/mycat
```
### 2.4.修改wrapper.conf文件
cd /usr/local/mycat/conf
vim wrapper.conf
```
# Java Application
wrapper.java.command=wrapper.java.command=/usr/local/java/jdk1.7.0_67/bin/java
```
### 2.5.启动mycat
**启动:**
mycat start
mycat 就已经启动了 端口8066
**关闭mycat:**
mycat stop

## 三、配置mycat
### 3.1 my.cnf追加一行
vim /etc/my.cnf
```
lower_case_table_names = 1
```
如果找不到my.cnf文件，copy一个：
cp /usr/share/mysql/my-default.cnf /etc/my.cnf
### 3.2配置schema
vim $MYCAT_HOME/conf/schema.xml
每个属性的含义请参考权威指南,这里给出基本的

```
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://org.opencloudb/">

	<schema name="JamesMycatSchema" checkSQLschema="false" sqlMaxLimit="100">
		<!-- 需要分片的表，在节点dn1,dn2上分片，分片规则是auto-sharding-long -->
		<table name="travelrecord" dataNode="dn1,dn2" rule="auto-sharding-long" />
        <table name="company" primaryKey="ID" type="global" dataNode="dn1,dn2" />
		<table name="goods" primaryKey="ID" type="global" dataNode="dn1,dn2" />
        <table name="hotnews" primaryKey="ID" dataNode="dn1,dn2"
			rule="mod-long" />
		<table name="employee" primaryKey="ID" dataNode="dn1,dn2"
			rule="sharding-by-intfile" />
	</schema>
	<!--数据节点dn1，对应的主机c1,对应是数据库db1 -->
    <dataNode name="dn1" dataHost="c1" database="db1" />
	<dataNode name="dn2" dataHost="c2" database="db2" />
	<!-- 主机C1-->
	<dataHost name="c1" maxCon="1000" minCon="10" balance="0"
		writeType="0" dbType="mysql" dbDriver="native">
		<heartbeat>select user()</heartbeat>
		<!--mysql数据库的连接串 -->
		<writeHost host="hostM1" url="c1:3306" user="mycat"
			password="mycat">
		</writeHost>
	</dataHost>
	<!-- 主机C2-->
	<dataHost name="c2" maxCon="1000" minCon="10" balance="0"
		writeType="0" dbType="mysql" dbDriver="native">
		<heartbeat>select user()</heartbeat>

		<writeHost host="hostM2" url="c2:3306" user="mycat"
			password="mycat">
		</writeHost>
	</dataHost>
</mycat:schema>

```
3.3 配置server.xml
追加：
```
<!-- 为mycat配置一个用户 -->
<user name="cat">
		<property name="password">cat</property>
		<property name="schemas">JamesMycatSchema</property>
	</user>
```
## 四.测试
这里使用mycat自带的表来测试
启动mycat:
mycat start
使用Navicat for MySQL连接mycat:
cat/cat@192.168.58.11

建表：
```
create table employee (id int not null primary key,name varchar(100),sharding_id int not null);
```
插入数据：
```
insert into employee(id,name,sharding_id) values(1,'leader us',10000);
insert into employee(id,name,sharding_id) values(2, 'me',10010);
insert into employee(id,name,sharding_id) values(3, 'mycat',10000);
insert into employee(id,name,sharding_id) values(4, 'mydog',10010);
```
分别到数据DB1,DB2查看，可以看到在DB1中有：
1	leader us	10000
3	mycat	10000
DB2中有：
2	me	10010
4	mydog	10010

这说明分片成功了