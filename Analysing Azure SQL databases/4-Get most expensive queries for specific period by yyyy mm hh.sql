SET NOCOUNT ON
declare @CNT INT = 1
declare @UTC_FROM  varchar(35) = '2021-08-04 00:00:00'
declare @UTC_UPTO  varchar(35) = dateadd(hh,1,cast(@UTC_FROM as datetime) ) 

if object_id('tempdb..#topqueries') is not null
drop table #topqueries

create table #topqueries
(
query_id int,
start_time datetime,
 count_executions int,
 total_duration_ms_sec numeric(16,2),
 total_cpu_time_ms_sec numeric(16,2),
 avg_duration_ms_sec numeric(16,2),
 avg_cpu_time_ms_sec numeric(16,2),
 max_duration_ms_sec numeric(16,2),
 max_cpu_time_ms_sec numeric(16,2),
 avg_rowcount numeric(16,2),
 max_rowcount numeric(16,2),
 num_plans1 int
)



--select @UTC_UPTO

while @UTC_UPTO <  getdate()
begin


insert into #topqueries(query_id ,
start_time ,
 count_executions ,
 total_duration_ms_sec ,
 total_cpu_time_ms_sec ,
 avg_duration_ms_sec ,
 avg_cpu_time_ms_sec ,
 max_duration_ms_sec ,
 max_cpu_time_ms_sec,
 avg_rowcount ,
 max_rowcount ,
 num_plans1)

SELECT TOP 10
    p.query_id as query_id,
     cast(@UTC_FROM as datetime) as start_time,
	 SUM(rs.count_executions) count_executions,
	 sum([rs].[count_executions] * round([rs].[avg_duration]/1000,2)) as total_duration_ms_sec,
   sum([rs].[count_executions] * round([rs].[avg_cpu_time]/1000,2)) as total_cpu_time_ms_sec,
    avg(round([rs].[avg_duration]/1000,2))as avg_duration_ms_sec,
   avg(round([rs].[avg_cpu_time]/1000,2))as avg_cpu_time_ms_sec,
   max(round([rs].[max_duration]/1000,2))as max_duration_ms_sec,
   max(round([rs].[max_cpu_time]/1000,2))as max_cpu_time_ms_sec,
   avg(round([rs].avg_rowcount,2)) as avg_rowcount,
   max(round([rs].max_rowcount,2)) as max_rowcount,
  COUNT(distinct p.plan_id) num_plans
FROM sys.query_store_runtime_stats rs
    JOIN sys.query_store_plan p ON p.plan_id = rs.plan_id
    JOIN sys.query_store_query q ON q.query_id = p.query_id
    JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
WHERE NOT (rs.first_execution_time >  @UTC_UPTO  OR rs.last_execution_time <@UTC_FROM  )
GROUP BY p.query_id--, qt.query_sql_text, q.object_id
HAVING COUNT(distinct p.plan_id) >= 1
ORDER BY total_duration_ms_sec DESC

--SET @CNT = @CNT+1 
SET @UTC_FROM = dateadd(hh,1,cast(@UTC_FROM as datetime) ) 
SET @UTC_UPTO = dateadd(hh,1,cast(@UTC_FROM as datetime) ) 

--select @UTC_UPTO
end


select * from #topqueries




SELECT
   [qsq].[query_id],
   [qst].query_sql_text
 FROM [sys].[query_store_query] [qsq]
JOIN [sys].[query_store_query_text] [qst]    ON [qsq].[query_text_id] = [qst].[query_text_id]

WHERE 
[qsq].[query_id] in(select query_id from #topqueries)

group by [qsq].[query_id], [qst].query_sql_text