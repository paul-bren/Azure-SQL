declare 
        @interval_start_time datetimeoffset(7),
		@interval_end_time datetimeoffset(7)


--case 1
		set @interval_start_time ='2021-08-27 19:30:00 +00:00'
		set @interval_end_time   ='2021-08-27 19:40:00 +00:00'


SELECT TOP 3
    p.query_id query_id,
   -- q.object_id object_id,
    --ISNULL(OBJECT_NAME(q.object_id),'''') object_name,
  --  qt.query_sql_text query_sql_text,
    ROUND(CONVERT(float, SUM(rs.avg_duration*rs.count_executions))*0.001,2) total_duration,
    SUM(rs.count_executions) count_executions,
    COUNT(distinct p.plan_id) num_plans
FROM sys.query_store_runtime_stats rs
    JOIN sys.query_store_plan p ON p.plan_id = rs.plan_id
    JOIN sys.query_store_query q ON q.query_id = p.query_id
    JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
WHERE NOT (rs.first_execution_time > @interval_end_time OR rs.last_execution_time < @interval_start_time)
GROUP BY p.query_id, qt.query_sql_text, q.object_id
HAVING COUNT(distinct p.plan_id) >= 1
ORDER BY total_duration DESC

