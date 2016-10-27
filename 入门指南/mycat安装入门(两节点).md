## һ.��������

### 1.1. mysql�ڵ�1����
 
- ����ϵͳ�汾  : centos6.5 x64
- ���ݿ�汾    : mysql-5.7.4
- mycat�汾    ��1.3 release
- ���ݿ���      : db1
- hostname:c1
- ip:192.168.58.11

### 1.2. mysql�ڵ�2����

- ����ϵͳ�汾  : centos6.5 x64
- ���ݿ�汾    : mysql-5.7.4
- mycat�汾    ��1.3 release
- ���ݿ���     : db2
- hostname:c2
- ip:192.168.58.12

### 1.3.mycat����
   
     ��װ��c1
    
### 1.4. ǰ������
   �����ڵ㶼��װ��mysql5.7.4
## ��.��װmycat

### 2.1.�����û�����
root >

����һ���µ�group
 ``` 
 groupadd dba
 ```
����һ���µ��û���������group
```
  useradd -g dba mycat
```
�����û��������룬
```
  passwd mycat
```

### 2.2.��ѹ
mycat >
```
tar -xzvf Mycat-server-1.3.0.3-release-20150527095523-linux.tar.gz
mkdri /home/mycat/app
mv mycat /home/mycat/app/mycat
```
### 2.3.���û�������
 vim /home/mycat/.bash_profile
```
export MYCAT_HOME=/home/mycat/app/mycat
PATH=$PATH:$MYCAT_HOME/bin
```
���޸���Ч
```
[mycat@c1 ~]$ source .bash_profile
```
**�����Ƿ����óɹ�**
```
[mycat@c1 ~]$ echo $MYCAT_HOME
/home/mycat/app/mycat
```
### 2.4.�޸�wrapper.conf�ļ�
cd /usr/local/mycat/conf
vim wrapper.conf
```
# Java Application
wrapper.java.command=wrapper.java.command=/usr/local/java/jdk1.7.0_67/bin/java
```
### 2.5.����mycat
**����:**
mycat start
mycat ���Ѿ������� �˿�8066
**�ر�mycat:**
mycat stop

## ��������mycat
### 3.1 my.cnf׷��һ��
vim /etc/my.cnf
```
lower_case_table_names = 1
```
����Ҳ���my.cnf�ļ���copyһ����
cp /usr/share/mysql/my-default.cnf /etc/my.cnf
### 3.2����schema
vim $MYCAT_HOME/conf/schema.xml
ÿ�����Եĺ�����ο�Ȩ��ָ��,�������������

```
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://org.opencloudb/">

	<schema name="JamesMycatSchema" checkSQLschema="false" sqlMaxLimit="100">
		<!-- ��Ҫ��Ƭ�ı��ڽڵ�dn1,dn2�Ϸ�Ƭ����Ƭ������auto-sharding-long -->
		<table name="travelrecord" dataNode="dn1,dn2" rule="auto-sharding-long" />
        <table name="company" primaryKey="ID" type="global" dataNode="dn1,dn2" />
		<table name="goods" primaryKey="ID" type="global" dataNode="dn1,dn2" />
        <table name="hotnews" primaryKey="ID" dataNode="dn1,dn2"
			rule="mod-long" />
		<table name="employee" primaryKey="ID" dataNode="dn1,dn2"
			rule="sharding-by-intfile" />
	</schema>
	<!--���ݽڵ�dn1����Ӧ������c1,��Ӧ�����ݿ�db1 -->
    <dataNode name="dn1" dataHost="c1" database="db1" />
	<dataNode name="dn2" dataHost="c2" database="db2" />
	<!-- ����C1-->
	<dataHost name="c1" maxCon="1000" minCon="10" balance="0"
		writeType="0" dbType="mysql" dbDriver="native">
		<heartbeat>select user()</heartbeat>
		<!--mysql���ݿ�����Ӵ� -->
		<writeHost host="hostM1" url="c1:3306" user="mycat"
			password="mycat">
		</writeHost>
	</dataHost>
	<!-- ����C2-->
	<dataHost name="c2" maxCon="1000" minCon="10" balance="0"
		writeType="0" dbType="mysql" dbDriver="native">
		<heartbeat>select user()</heartbeat>

		<writeHost host="hostM2" url="c2:3306" user="mycat"
			password="mycat">
		</writeHost>
	</dataHost>
</mycat:schema>

```
3.3 ����server.xml
׷�ӣ�
```
<!-- Ϊmycat����һ���û� -->
<user name="cat">
		<property name="password">cat</property>
		<property name="schemas">JamesMycatSchema</property>
	</user>
```
## ��.����
����ʹ��mycat�Դ��ı�������
����mycat:
mycat start
ʹ��Navicat for MySQL����mycat:
cat/cat@192.168.58.11

����
```
create table employee (id int not null primary key,name varchar(100),sharding_id int not null);
```
�������ݣ�
```
insert into employee(id,name,sharding_id) values(1,'leader us',10000);
insert into employee(id,name,sharding_id) values(2, 'me',10010);
insert into employee(id,name,sharding_id) values(3, 'mycat',10000);
insert into employee(id,name,sharding_id) values(4, 'mydog',10010);
```
�ֱ�����DB1,DB2�鿴�����Կ�����DB1���У�
1	leader us	10000
3	mycat	10000
DB2���У�
2	me	10010
4	mydog	10010

��˵����Ƭ�ɹ���