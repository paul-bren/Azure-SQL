--Current db size in GB

SELECT
       SUM(CAST (FILEPROPERTY (name, 'SpaceUsed') AS BIGINT) * 8192.) / 1024 / 1024 / 1024  as [Database Size In GBs]
FROM sys.database_files
WHERE type_desc = 'ROWS';

--Total DB size in GB

SELECT SUM (CAST(DATABASEPROPERTYEX(DB_NAME(), 'MaxSizeinBytes') as BIGINT)) /1024.0/1024.0/1024.0

--Both of the above combined

SELECT 
getdate() as review_date,
db_name() as db,
SUM(CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0)/1024.0 AS UsedSpace,
SUM(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0)/1024.0 AS FreeSpace,
SUM(size/128.0)/1024.0 AS Allocated_DBSize_GB,
cast(DATABASEPROPERTYEX(db_name(), 'MaxSizeInBytes') as bigint)/(1024 *1024 *1024 ) AS DatabaseDataMaxSizeInGB
FROM sys.database_files GROUP BY type_desc HAVING type_desc = 'ROWS'