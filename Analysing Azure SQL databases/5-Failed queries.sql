SELECT
   [qsq].[query_id],
  -- [qsp].[plan_id],
   [qst].query_sql_text,
   case  execution_type
     when 0 then 'successfully finished'
	 when 3 then '! Client initiated aborted execution'
	 when 4 then 'Exception aborted execution'
	 end
   execution_type,
 cast( [rsi].[start_time] as smalldatetime) as TimeUTC,
  --[rsi].[start_time] AT TIME ZONE 'INSERT TIME ZONE HERE' [EST StartTime],--local time
  sum([rs].[count_executions]) as count_executions
 
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
--[qsq].[query_id] =  -- get query id from portal or query store
--and
execution_type <>0
and
[rsi].[start_time] >= '2021-08-01 00:00:00.0000000 +00:00'--- and '2019-12-07 23:00:00.0000000 +00:00'
group by 
  [qsq].[query_id],
   [qst].query_sql_text,
   execution_type,
  [rsi].[start_time]

ORDER BY [rsi].[start_time]

