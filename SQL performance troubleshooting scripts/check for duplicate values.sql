--this is specific to columns. Will need to modify this based on what you need to find

select count(*) as rec_no,
column1, column2...
from
<table name>
group by [column1], [column2]
having count(*) >1