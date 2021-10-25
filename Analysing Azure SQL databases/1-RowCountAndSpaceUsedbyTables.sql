--Q1
SELECT 
getdate() as review_date,
db_name() as db,
SUM(CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0)/1024.0 AS UsedSpace,
SUM(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0)/1024.0 AS FreeSpace,
SUM(size/128.0)/1024.0 AS Allocated_DBSize_GB,
cast(DATABASEPROPERTYEX(db_name(), 'MaxSizeInBytes') as bigint)/(1024 *1024 *1024 ) AS DatabaseDataMaxSizeInGB
FROM sys.database_files GROUP BY type_desc HAVING type_desc = 'ROWS'


---export Q2 to to excel
--Q2
SELECT
t.Name AS TableName,
p.rows AS RowCounts,
CAST(ROUND((SUM(a.used_pages) / 128.00), 2) AS NUMERIC(36, 2)) AS Used_MB

FROM sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
GROUP BY t.Name, p.Rows
ORDER BY 2 desc



