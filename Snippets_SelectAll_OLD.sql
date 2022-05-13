-- =============================================
-- Author: Tim Isabella
-- Create date:
-- Description: Select all Snippets -- output JSON of snippets assigned to snippet alliance through composite table
-- Code Reviewer:
-- =============================================

ALTER PROC [dbo].[Snippets_SelectAll]
			@Index INT
			,@PageSize INT
AS

/*-----------Test Code-----------
DECLARE @Index INT = 0
		,@PageSize INT = 300

EXECUTE [dbo].[Snippets_SelectAll]
		@Index
		,@PageSize

SELECT *
FROM [dbo].[Snippets]
---------------------------------*/

BEGIN

	SELECT	[Id]
			,[RegionTypeId]
			,RegionName = (
						   SELECT [Name]
						   FROM [dbo].[RegionTypes]
						   WHERE [RegionTypes].[Id] = [RegionTypeId]
						  )
			,[Name]
			,[Logo]
			,[Code]
			,[LocationId]
			--Working JSON output for Locations
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
			,[SiteUrl]
			,[RegistrationDate]
			,[StatusId]
			,StatusName = (
						   SELECT [Name]
						   FROM [dbo].[StatusType]
						   WHERE [StatusType].[Id] = [Snippets].StatusId
						  )
			,[IsAlliance]
			,AssignedAlliances = (
								   CASE WHEN [Snippets].[IsAlliance] = 0
								   THEN (
								  	     SELECT 
												AllianceName = (
								  							     SELECT [Name] 
								  							     FROM [dbo].[Snippets]
								  							     WHERE [AllianceId] = [Snippets].Id
								  							    )
								  			    ,AllianceLogoUrl = (
								  								     SELECT [Logo] 
								  								     FROM [dbo].[Snippets]
								  								     WHERE [AllianceId] = [Snippets].Id
								  								    )
												,CompositeRef = (SELECT [AllianceId], [Id] AS SnippetId FOR JSON PATH)

								  	     FROM [dbo].[SnippetAlliances]
								  	     WHERE [SnippetAlliances].SnippetId = [Id]
								  	     FOR JSON AUTO
								  	    )
								   END
								  )
			,AllianceMembers = (
								 CASE WHEN [Snippets].[IsAlliance] = 1
								 THEN (
								 	   SELECT 
											  SnippetName = (
														    SELECT [Name] 
														    FROM [dbo].[Snippets] 
														    WHERE [SnippetId] = [Snippets].Id
														    )
											  ,SnippetLogoUrl = (
															   SELECT [Logo]
															   FROM [dbo].[Snippets] 
															   WHERE [SnippetId] = [Snippets].Id
															  )
											  ,CompositeRef = (SELECT [Id] AS AllianceId, [SnippetId] FOR JSON PATH)

									   FROM [dbo].[SnippetAlliances]
									   WHERE [SnippetAlliances].AllianceId = [Id]
									   FOR JSON AUTO
								 	  ) 
								 END
								)

			,TotalCount = COUNT(1) OVER()
	FROM [dbo].[Snippets]		
	ORDER BY [Id]

	OFFSET @Index ROW
	FETCH NEXT @PageSize ROWS ONLY

END
