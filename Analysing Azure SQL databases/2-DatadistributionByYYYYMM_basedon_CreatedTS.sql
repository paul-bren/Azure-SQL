/*
Important to avoid perfromance problem run on read-only copy of db

step 1
--If database is  set with Read scale-out Enabled (check from portal)
using addtional conencion parameters in SSMS open conenction with  ApplicationIntent=READONLY

step 2 
verify if conenction raed-only
select  @@servername as [@@servername] ,db_name() as [db_name],replica_id,DATABASEPROPERTYEX(DB_NAME(), 'Updateability') from sys.dm_database_replica_states

step 3 run script bellow and export result to excel
current conditioon 1M rows or 1 GB size 
having p.Rows > 1000000 or CAST(ROUND((SUM(a.used_pages) / 128.00), 2) AS NUMERIC(36, 2))  >= 1000
*/


SET NOCOUNT ON
declare 
@table_name nvarchar(200),
@SQL varchar(4000)

if OBJECT_ID('tempdb..##x') is not null
 drop table ##X

create table ##X(
tableName_ nvarchar(200),
Rows_ int,
year_ int,
Month_ int)


declare 
C1 cursor for 
 SELECT
t.Name AS TableName--,
--p.rows AS RowCounts,
--CAST(ROUND((SUM(a.used_pages) / 128.00), 2) AS NUMERIC(36, 2)) AS Used_MB

FROM sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
where t.Name in(
SELECT TABLE_NAME
          FROM   INFORMATION_SCHEMA.COLUMNS
          WHERE   COLUMN_NAME = 'COLUMN(S) NAME(S) HERE')
GROUP BY t.Name, p.Rows
having p.Rows > 1000000 or CAST(ROUND((SUM(a.used_pages) / 128.00), 2) AS NUMERIC(36, 2))  >= 1000
--ORDER BY 2 desc

open C1
fetch C1 into @table_name

while @@FETCH_STATUS = 0
begin

set @SQL= 

'insert into ##x(tableName_, rows_, year_, month_)
select '''+  @table_name + ''', count(*) as rows_,
year('COLUMN NAME) as year_,
Month(COLUMN NAME) as month_

from ' + @table_name + ' 
group by year(COLUMN NAME), Month(COLUMN NAME)
order by year_ asc, month_ '

--select @SQL
exec (@SQL)
fetch C1 into @table_name

end 
close C1
deallocate C1



Select * from ##X

--Read scale-out
--ApplicationIntent=READONLY

--READ_ONLY
--select  @@servername as [@@servername] ,db_name() as [db_name],replica_id,DATABASEPROPERTYEX(DB_NAME(), 'Updateability') from sys.dm_database_replica_states
