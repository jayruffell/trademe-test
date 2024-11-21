USE TradeMeTest;
GO

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

-- -- TEST FUNCTION
-- SELECT * 
-- FROM dbo.ExpandSingleRow('25/06/2018', 'A', 0, 3);
