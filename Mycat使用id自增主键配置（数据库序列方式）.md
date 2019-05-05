# Mycat使用id自增主键配置（数据库序列方式）

##### 基于 Mycat-1.6.7.1  Mysql-5.7
1. 创建表测试并设置id主键自增
  a. 测试分为两个数据库`test_db1`,`test_db2`,测试表名为`table1`，分别对应dn1、dn2节点。
  b. 在两个数据库中创建`table1`,设置id主键、自增
  ```sql
CREATE TABLE `table1` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL,
      `age` int(11) NULL DEFAULT NULL,
      PRIMARY KEY (`id`) USING BTREE
    ) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_unicode_ci ROW_FORMAT = Dynamic;
```

2. 修改mycat数据库节点配置`schema.xml`
注：table节点需设置`primaryKey="id" autoIncrement="true"`
  ```xml
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">
	<schema name="TESTDB" checkSQLschema="true" sqlMaxLimit="10000">
		<table name="table1" primaryKey="id" autoIncrement="true" dataNode="dn1,dn2" rule="sharding-by-murmur" />
	</schema>
	<dataNode name="dn1" dataHost="localhost1" database="test_db1" />
	<dataNode name="dn2" dataHost="localhost2" database="test_db2" />
	<dataHost name="localhost1" maxCon="1000" minCon="10" balance="0" writeType="0" dbType="mysql" dbDriver="native" >
		<heartbeat>select user()</heartbeat> 
		<writeHost host="hostM1" url="localhost:13306" user="root" password="password" />
	</dataHost>
	<dataHost name="localhost2" maxCon="1000" minCon="10" balance="0" writeType="0" dbType="mysql" dbDriver="native" >
		<heartbeat>select user()</heartbeat>
		<writeHost host="hostM2" url="localhost:23306" user="root" password="password" />
	</dataHost>
</mycat:schema>
```

3. 修改mycat主键策略`server.xml`
  ```
0 表示是表示使用本地文件方式
1 表示的是根据数据库来生成（此示例选用值）
2 表示时间戳的方式
```
  ```xml
<property name="sequnceHandlerType">1</property>
```

4. 增加自增序列表，及所需的函数
  a. 连接其中一个数据节点对应的数据库（注：不是连接Mycat，是连接配置中的其中一个数据库，此示例中使用`dn1`节点对应的数据库）
  b. 插入自增序列表，及所需函数（一个表及三个函数需在同一数据库中建立；表和函数的名称为固定值，无需修改）
  ```sql
-- 表:MYCAT_SEQUENCE
CREATE TABLE MYCAT_SEQUENCE (
`name` VARCHAR(50) NOT NULL, -- name sequence名称
current_value INT NOT NULL, -- current_value 当前value
increment INT NOT NULL DEFAULT 1, -- increment增长步长。可理解为mycat在数据库中一次读取多少个sequence，当这些用完后, 下次再从数据库中读取，若此次取出了1-100，仅使用了50个，重启Mycat后，下一序列从101开始。
PRIMARY KEY(name)) ENGINE=InnoDB;
-- 函数:获取当前sequence的值
CREATE FUNCTION `mycat_seq_currval`(seq_name VARCHAR(50)) RETURNS varchar(64) CHARSET latin1
DETERMINISTIC
BEGIN
DECLARE retval VARCHAR(64);
SET retval="-999999999,null";
SELECT concat(CAST(current_value AS CHAR),",",CAST(increment AS CHAR) ) INTO retval FROM MYCAT_SEQUENCE WHERE name = seq_name;
RETURN retval;
END;
DELIMITER;
-- 函数:获取下一个sequence值
CREATE FUNCTION `mycat_seq_nextval`(seq_name VARCHAR(50)) RETURNS varchar(64) CHARSET latin1
DETERMINISTIC
BEGIN
UPDATE MYCAT_SEQUENCE SET current_value = current_value + increment WHERE name = seq_name;
RETURN mycat_seq_currval(seq_name);
END;
DELIMITER;
-- 函数:设置sequence值
CREATE FUNCTION `mycat_seq_setval`(seq_name VARCHAR(50), value INTEGER) RETURNS varchar(64) CHARSET latin1
DETERMINISTIC
BEGIN
UPDATE MYCAT_SEQUENCE SET current_value = value WHERE name = seq_name;
RETURN mycat_seq_currval(seq_name);
END;
DELIMITER;
```

5. 于MYCAT_SEQUENCE表中插入序列信息
  ```sql
INSERT INTO MYCAT_SEQUENCE(name,current_value,increment) VALUES ('table1', 1, 100);
```
  其中`table1`对应数据库表名
6. 修改Mycat数据库主键生成配置`sequence_db_conf.properties`
  ```
TABLE1=dn1
```
  其中`TABLE1`对应数据库表名（配置文件中的表名必须大写，否则Mycat找不到表报错），`dn1`为配置了自增序列及函数的节点名。

7. 启动Mycat连接测试，dn1,dn2均会使用此序列生成自增id
  ```sql
insert into table1 (name,age) values ('name1',22);
```
