declare @idxIdentifierBegin char(1), @idxIdentifierEnd char(1);
declare @statsIdentifierBegin char(1), @statsIdentifierEnd char(1);
declare @TableUsedInQuery nvarchar(200)

--Step 1
--review query with perfromance problem and list all the tables used by query
--add table name to @TableUsedInQuery

set @TableUsedInQuery= ''


drop table if exists #statsBefore
drop table if exists #IndexStats

SELECT OBJECT_NAME(IX.OBJECT_ID) Table_Name
	   ,IX.name AS Index_Name
	   ,IX.type_desc Index_Type
	   ,SUM(PS.[used_page_count]) * 8 IndexSizeKB
	   ,IXUS.user_seeks AS NumOfSeeks
	   ,IXUS.user_scans AS NumOfScans
	   ,IXUS.user_lookups AS NumOfLookups
	   ,IXUS.user_updates AS NumOfUpdates
	   ,IXUS.last_user_seek AS LastSeek
	   ,IXUS.last_user_scan AS LastScan
	   ,IXUS.last_user_lookup AS LastLookup
	   ,IXUS.last_user_update AS LastUpdate
into #IndexStats

FROM sys.indexes IX
INNER JOIN sys.dm_db_index_usage_stats IXUS ON IXUS.index_id = IX.index_id AND IXUS.OBJECT_ID = IX.OBJECT_ID
INNER JOIN sys.dm_db_partition_stats PS on PS.object_id=IX.object_id  and ps.[index_id] = ix.[index_id]
WHERE OBJECT_NAME(IX.OBJECT_ID) = @TableUsedInQuery
GROUP BY OBJECT_NAME(IX.OBJECT_ID) ,IX.name ,IX.type_desc ,IXUS.user_seeks ,IXUS.user_scans ,IXUS.user_lookups,IXUS.user_updates ,IXUS.last_user_seek ,IXUS.last_user_scan ,IXUS.last_user_lookup ,IXUS.last_user_update






SELECT INX.[name] AS [Index Name]
      --,TBL.[name] AS [Table Name]
      ,DS1.[IndexColumnsNames]
      ,DS2.[IncludedColumnsNames]
	  ,case 
	    when INX.is_disabled = 1 then 'index disabled'
		else 'index enabled' 
       end  as index_status,
	   IndexSizeKB,
	   NumOfSeeks,
	   NumOfScans,
	   NumOfLookups,
	   NumOfUpdates,
	   LastSeek,
	   LastScan,
	   LastLookup,
	   LastUpdate
FROM [sys].[indexes] INX
INNER JOIN [sys].[tables] TBL  ON INX.[object_id] = TBL.[object_id]
INNER JOIN #IndexStats as IDX_St ON IDX_St.Index_Name  = INX.[name]
CROSS APPLY 
(
    SELECT STUFF
    (
        (
            SELECT ' [' + CLS.[name] + ']'
            FROM [sys].[index_columns] INXCLS
            INNER JOIN [sys].[columns] CLS 
                ON INXCLS.[object_id] = CLS.[object_id] 
                AND INXCLS.[column_id] = CLS.[column_id]
            WHERE INX.[object_id] = INXCLS.[object_id] 
                AND INX.[index_id] = INXCLS.[index_id]
                AND INXCLS.[is_included_column] = 0
            FOR XML PATH('')
        )
        ,1
        ,1
        ,''
    ) 
) DS1 ([IndexColumnsNames])
CROSS APPLY 
(
    SELECT STUFF
    (
        (
            SELECT ' [' + CLS.[name] + ']'
            FROM [sys].[index_columns] INXCLS
            INNER JOIN [sys].[columns] CLS 
                ON INXCLS.[object_id] = CLS.[object_id] 
                AND INXCLS.[column_id] = CLS.[column_id]
            WHERE INX.[object_id] = INXCLS.[object_id] 
                AND INX.[index_id] = INXCLS.[index_id]
                AND INXCLS.[is_included_column] = 1
            FOR XML PATH('')
        )
        ,1
        ,1
        ,''
    ) 
) DS2 ([IncludedColumnsNames])

where 
TBL.[name] = @TableUsedInQuery

---Before making any changes to query

		select 
			ObjectSchema = OBJECT_SCHEMA_NAME(s.object_id)
			,ObjectName = object_name(s.object_id) 
			,s.object_id
			,s.stats_id
			,StatsName = s.name
			,sp.last_updated
			,sp.rows
			,sp.rows_sampled
			,sp.modification_counter
			, i.type
			, i.type_desc
			,0 as SkipStatistics
		into #statsBefore
		from sys.stats s cross apply sys.dm_db_stats_properties(s.object_id,s.stats_id) sp 
		left join sys.indexes i on sp.object_id = i.object_id and sp.stats_id = i.index_id
		where OBJECT_SCHEMA_NAME(s.object_id) != 'sys' and /*Modified stats or Dummy mode*/(isnull(sp.modification_counter,0)>=0 )--or @mode='dummy')
		and 
		s.object_id = OBJECT_ID(@TableUsedInQuery)
		order by sp.last_updated asc

	if exists(
			select 1
			from #statsBefore 
			where StatsName like '%[%' or StatsName like '%]%'
			or ObjectSchema like '%[%' or ObjectSchema like '%]%'
			or ObjectName like '%[%' or ObjectName like '%]%'
			)
		begin
			set @statsIdentifierBegin = '"'
			set @statsIdentifierEnd = '"'
		end
		else 
		begin
			set @statsIdentifierBegin = '['
			set @statsIdentifierEnd = ']'
		end

				select 'UPDATE STATISTICS '+ @statsIdentifierBegin + ObjectSchema + +@statsIdentifierEnd + '.'+@statsIdentifierBegin + ObjectName + @statsIdentifierEnd +' (' + @statsIdentifierBegin + StatsName + @statsIdentifierEnd + ') WITH FULLSCAN;'
		, 
		last_updated,
		CurrentStatInfo = '#rows:' + cast([rows] as varchar(100)) + ' #modifications:' + cast(modification_counter as varchar(100)) + ' modification percent: ' + format((1.0 * modification_counter/ rows ),'p')
		from #statsBefore
		order by modification_counter desc