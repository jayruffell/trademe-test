
/*
This script makes use of an SQL Server database called TradeMeTest, which I created for this project: 
-- First, the script creates a function in this database that takes a single row of input data and expands it to one row per session ID. 
-- Second, the script applies this function to the 'dataAggregated' table, which is the input csv file saved as a database table.
*/

USE TradeMeTest;
GO

-----------------------
-- 1. Create function
-----------------------

CREATE FUNCTION dbo.ExpandSingleRow
(
    @date_id VARCHAR(10),
    @group_id VARCHAR(1),
    @session_result INT,
    @session_count INT
)
RETURNS @ExpandedSessions TABLE
(
    date_id VARCHAR(10),
    group_id VARCHAR(1),
    session_result INT,
    session_id INT
)
AS
BEGIN
    DECLARE @i INT = 1;

    -- Insert each individual session into the result table
    WHILE @i <= @session_count
    BEGIN
        INSERT INTO @ExpandedSessions (date_id, group_id, session_result, session_id)
        VALUES (@date_id, @group_id, @session_result, @i);
        SET @i = @i + 1;
    END

    RETURN;
END;
GO
-- TEST FUNCTION
SELECT * 
FROM dbo.ExpandSingleRow('25/06/2018', 'A', 0, 3);

-----------------------
-- 2. Apply function to each row of dataAggregated
-----------------------

SELECT expanded.date_id,
       expanded.group_id,
       expanded.session_result,
       expanded.session_id
FROM [dbo].[dataAggregated] AS agg
CROSS APPLY [dbo].[ExpandSingleRow](agg.date_id, agg.group_id, agg.session_result, agg.session_count) AS expanded;
GO
