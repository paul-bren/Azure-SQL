--Script to find all dml statements ran between times specified below

declare @UTC_FROM  varchar(35) = '2021-04-15 10:00:00.0000000 +00:00',
        @UTC_UPTO  varchar(35) = '2021-04-15 12:00:00.0000000 +00:00'

SELECT
   [qsq].[query_id],
   [qst].query_sql_text
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
[rsi].[start_time] >= @UTC_FROM
and
[rsi].[start_time] < @UTC_UPTO
group by [qsq].[query_id], [qst].query_sql_text