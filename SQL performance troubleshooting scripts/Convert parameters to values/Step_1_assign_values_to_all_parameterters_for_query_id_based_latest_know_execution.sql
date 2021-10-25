declare @query_id int 

set @query_id =  --query id taken from query store 


IF OBJECT_ID('tempdb..#compiledValue') IS NOT NULL
    DROP TABLE #compiledValue


SELECT 
   TRY_CONVERT(XML,SUBSTRING(etqp.query_plan,CHARINDEX('<ParameterList>',etqp.query_plan), CHARINDEX('</ParameterList>',etqp.query_plan) + LEN('</ParameterList>') - CHARINDEX('<ParameterList>',etqp.query_plan) )) AS Parameters
INTO #compiledValue
FROM sys.dm_exec_query_stats eqs
      join [sys].[query_store_query] [qsq] on  [qsq].[query_hash] =eqs.query_hash 
     CROSS APPLY sys.dm_exec_sql_text(eqs.sql_handle) est
     CROSS APPLY sys.dm_exec_text_query_plan(eqs.plan_handle, eqs.statement_start_offset, eqs.statement_end_offset) etqp
WHERE est.ENCRYPTED <> 1
and
[qsq].[query_id] = @query_id



SELECT 
'SET ' + pc.compiled.value('@Column', 'nvarchar(128)') + '  = '  + pc.compiled.value('@ParameterCompiledValue', 'nvarchar(128)') AS [compiled Value]--,

FROM #compiledValue cvalue
OUTER APPLY cvalue.parameters.nodes('//ParameterList/ColumnReference') AS pc(compiled)
where 
pc.compiled.value('@Column', 'nvarchar(128)') is not null


