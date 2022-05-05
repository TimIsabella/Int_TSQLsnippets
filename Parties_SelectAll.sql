-- =============================================
-- Author: Tim Isabella
-- Create date:
-- Description: Select all Parties -- output JSON of parties assigned to party coalition through composite table
-- Code Reviewer:
-- =============================================

ALTER PROC [dbo].[Parties_SelectAll]
			@Index INT
			,@PageSize INT
AS

/*-----------Test Code-----------
DECLARE @Index INT = 0
		,@PageSize INT = 300

EXECUTE [dbo].[Parties_SelectAll]
		@Index
		,@PageSize

SELECT *
FROM [dbo].[Parties]
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
						   WHERE [StatusType].[Id] = [Parties].StatusId
						  )
			,[IsCoalition]
			,AssignedCoalitions = (
								   CASE WHEN [Parties].[IsCoalition] = 0
								   THEN (
								  	     SELECT 
												CoalitionName = (
								  							     SELECT [Name] 
								  							     FROM [dbo].[Parties]
								  							     WHERE [CoalitionId] = [Parties].Id
								  							    )
								  			    ,CoalitionLogoUrl = (
								  								     SELECT [Logo] 
								  								     FROM [dbo].[Parties]
								  								     WHERE [CoalitionId] = [Parties].Id
								  								    )
												,CompositeRef = (SELECT [CoalitionId], [Id] AS PartyId FOR JSON PATH)

								  	     FROM [dbo].[PartyCoalitions]
								  	     WHERE [PartyCoalitions].PartyId = [Id]
								  	     FOR JSON AUTO
								  	    )
								   END
								  )
			,CoalitionMembers = (
								 CASE WHEN [Parties].[IsCoalition] = 1
								 THEN (
								 	   SELECT 
											  PartyName = (
														    SELECT [Name] 
														    FROM [dbo].[Parties] 
														    WHERE [PartyId] = [Parties].Id
														    )
											  ,PartyLogoUrl = (
															   SELECT [Logo]
															   FROM [dbo].[Parties] 
															   WHERE [PartyId] = [Parties].Id
															  )
											  ,CompositeRef = (SELECT [Id] AS CoalitionId, [PartyId] FOR JSON PATH)

									   FROM [dbo].[PartyCoalitions]
									   WHERE [PartyCoalitions].CoalitionId = [Id]
									   FOR JSON AUTO
								 	  ) 
								 END
								)

			,TotalCount = COUNT(1) OVER()
	FROM [dbo].[Parties]		
	ORDER BY [Id]

	OFFSET @Index ROW
	FETCH NEXT @PageSize ROWS ONLY

END
