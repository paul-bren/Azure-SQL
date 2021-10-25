
DECLARE @start_time VARCHAR(16), @end_time VARCHAR(16), @DBNAME VARCHAR(100), @DBID VARCHAR(3), @SQL NVARCHAR(MAX),@Interval VARCHAR(3)


SELECT @start_time = '2021/08/01 00:00:00'

SELECT @end_time =   '2022/06/09 23:59:00'

select @Interval ='10' --10 id Defined in dpa

SELECT @DBNAME =''--'INSTANCE NAME HERE

SELECT @DBID = ID FROM ignite.COND WHERE lower(CONN_DATABASE) like LOWER(@DBNAME)

--select * FROM ignite.COND WHERE CONN_DATABASE = ''

SET @SQL = 'SELECT 
[Blocker_session_id],
[Blocked_session_id],
[time_interval_'+@Interval+'_min],
x.BLOCKER AS [BLOCKER HASH], 
x.BLOCKED AS [BLOCKEE HASH], 
x.DURATION AS [DURATION (sec)],
isNull(st.ST,''Transaction  Teminated But not Commited OR Goes external to do a piece of work'') AS [BLOCKER SQL], st2.ST as [BLOCKEE SQL] ' +

'FROM ' +

'(' +

'( ' +

'SELECT 
 sw.BLEE AS [Blocker_session_id],
 sw2.vdsi AS [Blocked_session_id],
 dateadd(minute, (datediff(minute, 0, sw.D)/'+@Interval+')*'+@Interval+',0)as [time_interval_'+@Interval+'_min],
 sw.IZHO AS [BLOCKER], 
 sw2.IZHO AS [BLOCKED],
 ISNULL(SUM(sw2.QP)/100,0) AS [DURATION] ' +

' FROM ignite.CONSW_' + @DBID + ' sw ' +

'INNER JOIN ignite.CONSW_' + @DBID + ' sw2 ON sw.BLER = sw2.BLEE ' +

'WHERE sw.D BETWEEN ''' + @start_time + ''' AND ''' + @end_time + ''' ' +

'AND sw2.D BETWEEN ''' + @start_time + ''' AND ''' + @end_time + ''' ' +

'GROUP BY sw.BLEE, sw2.vdsi, dateadd(minute, (datediff(minute, 0, sw.D)/'+@Interval+')*'+@Interval+',0), sw.IZHO, sw2.IZHO ' +

') ' +

'UNION ' +

'( ' +

'SELECT 
sw2.BLEE AS [Blocker_session_id],
sw2.vdsi AS [Blocked_session_id],
dateadd(minute, (datediff(minute, 0, sw2.D)/'+@Interval+')*'+@Interval+',0)as [time_interval_'+@Interval+'_min],
null [BLOCKER], 
sw2.IZHO AS [BLOCKED], 
ISNULL(SUM(sw2.QP)/100,0) AS [DURATION] ' +

' FROM ignite.CONSW_' + @DBID + ' sw2 ' +

'WHERE sw2.D BETWEEN ''' + @start_time + ''' AND ''' + @end_time + ''' ' +

'AND sw2.BLEE < 0 ' +

'GROUP BY sw2.BLEE, sw2.vdsi,dateadd(minute, (datediff(minute, 0, sw2.D)/'+@Interval+')*'+@Interval+',0),	sw2.IZHO ' +

') ' +

') x ' +

'LEFT JOIN ignite.CONST_' + @DBID + ' st ON x.BLOCKER = st.H AND st.P = 0 ' +

'LEFT JOIN ignite.CONST_' + @DBID + ' st2 ON x.BLOCKED = st2.H AND st2.P = 0 ' +
--'where Blocker_session_id = -427'+
'order by x.DURATION desc,[time_interval_'+@Interval+'_min] asc ,[Blocker_session_id]'
--'order by [time_interval_'+@Interval+'_min] asc '

--print @SQL
EXEC (@SQL)