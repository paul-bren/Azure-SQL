SELECT
   c.session_id,s.STATUS, c.net_transport, c.encrypt_option,
   c.auth_scheme, s.host_name, s.program_name,
   s.client_interface_name, s.login_name, s.nt_domain,
   s.nt_user_name, s.original_login_name, c.connect_time,
   s.login_time,  t.text
FROM sys.dm_exec_connections AS c
JOIN sys.dm_exec_sessions AS s
   ON c.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text (c.most_recent_sql_handle) t
where s.STATUS = 'running' order by HOST_NAME