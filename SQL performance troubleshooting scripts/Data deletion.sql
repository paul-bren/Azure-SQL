--Data DELETION format template 1

DECLARE @Counter INT
SET @Counter=1
WHILE ( @Counter <= 100)
BEGIN
BEGIN TRANSACTION
--try different values for top ...start with 1000 
DELETE TOP (1000) from <table> WHERE <column with date> < 'provide date value'
SET @Counter = @Counter + 1
COMMIT TRANSACTION
END

 