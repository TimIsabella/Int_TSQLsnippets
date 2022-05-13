-- =============================================
-- Author: Tim Isabella
-- Create date:
-- Description: Select all Snippets by query -- output JSON of snippets assigned to snippet alliance through composite table
-- Code Reviewer:
-- =============================================

ALTER PROC [dbo].[Snippets_Search_All]
			@Index INT
			,@PageSize INT
			,@Query NVARCHAR(200)
AS

/*-----------Test Code-----------
DECLARE @Index INT = 0
		,@PageSize INT = 300
		,@Query NVARCHAR(200) = 'z'

EXECUTE [dbo].[Snippets_Search_All]
		@Index
		,@PageSize
		,@Query

SELECT *
FROM [dbo].[Snippets]
---------------------------------*/

BEGIN
	
	SELECT	[Id]
			,[Name]
			,[Code]
			,[Logo]
			,[SiteUrl]
			,[ColorHEX]
			,[StatusId]
			,StatusName = (
						   SELECT [Name]
						   FROM [dbo].[StatusType]
						   WHERE [StatusType].[Id] = [Snippets].StatusId
						  )
			,[RegionTypeId]
			,RegionName = (
						   SELECT [Name]
						   FROM [dbo].[RegionTypes]
						   WHERE [RegionTypes].[Id] = [RegionTypeId]
						  )
			,[LocationId]
			,LocationLineOne = (
							    SELECT [LineOne]
							    FROM [dbo].[Locations]
							    WHERE [Locations].[Id] = [LocationId]
							   )
			--Working JSON output for Locations. Not sure what we need from this at this time.
			--,LocationDetails = (
			--			        SELECT [Name]
			--						   ,[LocationTypeId]
			--						   ,[LineOne]
			--						   ,[LineTwo]
			--						   ,[City]
			--						   ,[Zip]
			--						   ,[StateId]
			--						   ,[Latitude]
			--						   ,[Longitude]
			--						   ,[DateCreated]
			--						   ,[DateModified]
			--			        FROM [dbo].[Locations]
			--			        WHERE [Locations].[Id] = [LocationId]
			--					FOR JSON AUTO
			--			       )
			,[IsAlliance]
			,[RegistrationDate]
			,Members = (
						CASE WHEN [Snippets].[IsAlliance] = 1
						THEN (
							  SELECT 
									Name = (
											SELECT [Name] 
											FROM [dbo].[Snippets] 
											WHERE [SnippetId] = [Snippets].Id
										   )
									,Id = (
										   SELECT [Id]
										   FROM [dbo].[Snippets] 
										   WHERE [SnippetId] = [Snippets].Id
										  )
									,Logo = (
											 SELECT [Logo]
											 FROM [dbo].[Snippets] 
											 WHERE [SnippetId] = [Snippets].Id
											)
							  
							  FROM [dbo].[SnippetAlliances]
							  WHERE [SnippetAlliances].AllianceId = [Id]
							  FOR JSON AUTO
							 ) 
						END
					   )
			,TotalCount = COUNT(1) OVER()

	FROM [dbo].[Snippets]
	WHERE ([dbo].[Snippets].[Name] LIKE '%' + @Query + '%')
	ORDER BY [Id]

	OFFSET @Index ROW
	FETCH NEXT @PageSize ROWS ONLY
END
