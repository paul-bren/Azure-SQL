--https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-query-store-runtime-stats-transact-sql?view=sql-server-ver15

SELECT
   [qsq].[query_id],
   [qsp].[plan_id],
   [qst].query_sql_text,
   case  execution_type
     when 0 then 'successfully finished'
	 when 3 then '! Client initiated aborted execution'
	 when 4 then 'Exception aborted execution'
	 end
   execution_type,
  [rsi].[start_time] as TimeUTC,
  [rsi].[start_time] AT TIME ZONE 'Eastern Standard Time' [EST StartTime],--local time
  [rs].[count_executions],
   
   [rs].[count_executions] * round([rs].[avg_cpu_time]/1000,2) as total_cpu_time_ms_sec,
   [rs].[count_executions] * round([rs].[avg_duration]/1000,2) as total_duration_ms_sec,

   round([rs].[avg_duration]/1000,2)as avg_duration_ms_sec,
   --round([rs].[max_duration]/1000,2)as max_duration_ms_sec,
   round([rs].[avg_cpu_time]/1000,2)as avg_cpu_time_ms_sec,
  -- round([rs].[max_cpu_time]/1000,2)as max_cpu_time_ms_sec,
   round([rs].[avg_logical_io_reads],0)as avg_logical_io_reads,

   [rs].avg_dop,
   [rs].avg_rowcount,
   [rs].max_rowcount
FROM [sys].[query_store_query] [qsq]
JOIN [sys].[query_store_query_text] [qst]
   ON [qsq].[query_text_id] = [qst].[query_text_id]
JOIN [sys].[query_store_plan] [qsp]
   ON [qsq].[query_id] = [qsp].[query_id]
JOIN [sys].[query_store_runtime_stats] [rs]
   ON [qsp].[plan_id] = [rs].[plan_id]
JOIN [sys].[query_store_runtime_stats_interval] [rsi]
   ON [rs].[runtime_stats_interval_id] = [rsi].[runtime_stats_interval_id]
WHERE 
[qsq].[query_id] =  -- get query id from query store
and

[rsi].[start_time] >= '2020-01-14 14:00:00.0000000 +00:00'--- and '2019-12-07 23:00:00.0000000 +00:00'




ORDER BY [rs].[runtime_stats_interval_id];

