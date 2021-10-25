declare 
 @query_id int 

 set @query_id = 

SELECT
  [qsq].[query_id],
  [qsp].[plan_id],
  CONVERT(varchar(20),[rsi].[start_time],120) as StartHourUTC,
  sum([rs].[count_executions]) as count_executions ,
   
   sum([rs].[count_executions] * round([rs].[avg_cpu_time]/1000,2)) as total_cpu_time_ms_sec,
   sum([rs].[count_executions] * round([rs].[avg_duration]/1000,2)) as total_duration_ms_sec,

   round(avg([rs].[avg_duration])/1000,2)as avg_duration_ms_sec,
   round(avg([rs].[avg_cpu_time])/1000,2)as avg_cpu_time_ms_sec,
   round(avg([rs].[avg_logical_io_reads]),0)as avg_logical_io_reads,
   avg([rs].avg_rowcount) as avg_rowcount,
   max([rs].max_rowcount) as max_rowcount
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
[qsq].[query_id] = @query_id -- get query id from portal or query store
and
[rsi].[start_time] >= getdate()-1 --stats for last 24 hours
group by 
 [qsq].[query_id],
  [qsp].[plan_id],
  CONVERT(varchar(20),[rsi].[start_time],120)
ORDER BY 3--[rs].[runtime_stats_interval_id];



