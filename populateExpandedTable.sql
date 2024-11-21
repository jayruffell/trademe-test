USE TradeMeTest;
GO
INSERT INTO [dbo].[dataExpanded] (date_id, group_id, session_result, session_id)
SELECT expanded.date_id,
       expanded.group_id,
       expanded.session_result,
       expanded.session_id
FROM [dbo].[dataAggregated] AS agg
CROSS APPLY [dbo].[ExpandSingleRow](agg.date_id, agg.group_id, agg.session_result, agg.session_count) AS expanded
