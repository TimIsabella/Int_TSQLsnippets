-- =============================================
-- Author: Tim Isabella
-- Create date:
-- Description: Select all Parties by query -- output JSON of parties assigned to party coalition through composite table
-- Code Reviewer:
-- =============================================

ALTER PROC [dbo].[Parties_Search_All]
			@Index INT
			,@PageSize INT
			,@Query NVARCHAR(200)
AS

/*-----------Test Code-----------
DECLARE @Index INT = 0
		,@PageSize INT = 300
		,@Query NVARCHAR(200) = 'z'

EXECUTE [dbo].[Parties_Search_All]
		@Index
		,@PageSize
		,@Query

SELECT *
FROM [dbo].[Parties]
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
						   WHERE [StatusType].[Id] = [Parties].StatusId
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
			,[IsCoalition]
			,[RegistrationDate]
			,Members = (
						CASE WHEN [Parties].[IsCoalition] = 1
						THEN (
							  SELECT 
									Name = (
											SELECT [Name] 
											FROM [dbo].[Parties] 
											WHERE [PartyId] = [Parties].Id
										   )
									,Id = (
										   SELECT [Id]
										   FROM [dbo].[Parties] 
										   WHERE [PartyId] = [Parties].Id
										  )
									,Logo = (
											 SELECT [Logo]
											 FROM [dbo].[Parties] 
											 WHERE [PartyId] = [Parties].Id
											)
							  
							  FROM [dbo].[PartyCoalitions]
							  WHERE [PartyCoalitions].CoalitionId = [Id]
							  FOR JSON AUTO
							 ) 
						END
					   )
			,TotalCount = COUNT(1) OVER()

	FROM [dbo].[Parties]
	WHERE ([dbo].[Parties].[Name] LIKE '%' + @Query + '%')
	ORDER BY [Id]

	OFFSET @Index ROW
	FETCH NEXT @PageSize ROWS ONLY
END
