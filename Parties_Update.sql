-- =============================================
-- Author: Tim Isabella
-- Create date:
-- Description: Update party record in 'Parties' table and batch insert or remove party members if coalition
-- Code Reviewer:
-- =============================================

ALTER PROC [dbo].[Parties_Update]
			@Id INT
			,@Name NVARCHAR(200)
			,@Code NVARCHAR(50)
			,@Logo NVARCHAR(255)
			,@SiteUrl NVARCHAR(255)
			,@ColorHEX nchar(7)
			,@StatusId INT
			,@RegionTypeId INT
			,@LocationId INT
			,@IsCoalition BIT
			,@partyCompositeUDT AS [dbo].[PartyCompositeUDT] READONLY

AS

/*-----------Test Code-----------
DECLARE @Id INT							= 30
		,@Name NVARCHAR(200)			= 'Test Party'
		,@Code NVARCHAR(50)				= 'BP'
		,@Logo NVARCHAR(255)			= 'https://cdn.shopify.com/s/files/1/0271/9150/9091/files/5d01ce49-4ec8-484a-bf5c-ada602950267_800x.png'
		,@SiteUrl NVARCHAR(255)			= 'https://siteUrl.com'
		,@ColorHEX nchar(7)				= '#f28500'
		,@StatusId INT					= 2
		,@RegionTypeId INT				= 1
		,@LocationId INT				= 3
		,@IsCoalition BIT				= 1
		,@partyCompositeUDT AS [dbo].[PartyCompositeUDT]

		INSERT INTO @partyCompositeUDT (PartyId) VALUES (15)
		INSERT INTO @partyCompositeUDT (PartyId) VALUES (16)
		INSERT INTO @partyCompositeUDT (PartyId) VALUES (17)
		INSERT INTO @partyCompositeUDT (PartyId) VALUES (18)

EXECUTE [dbo].[Parties_Update]
		@Id
		,@Name
		,@Code
		,@Logo
		,@SiteUrl
		,@ColorHEX
		,@StatusId
		,@RegionTypeId
		,@LocationId
		,@IsCoalition
		,@partyCompositeUDT

SELECT *
FROM [dbo].[Parties]
SELECT *
FROM [dbo].[PartyCoalitions]
---------------------------------*/

BEGIN
	
	--Party id check
	IF NOT EXISTS (SELECT [Id] FROM [dbo].[Parties] WHERE [Id] = @Id)
		BEGIN
			PRINT 'Coalition party Id#' + CONVERT(varchar(10), @Id) + ' does not exists -- Canceling update.'
			RETURN
		END
	
	BEGIN TRY
		BEGIN TRANSACTION;

			PRINT 'Updating coalition party...'

			UPDATE [dbo].[Parties]
				SET [Name]			= @Name
					,[Code]			= @Code
					,[Logo]			= @Logo
					,[SiteUrl]		= @SiteUrl
					,[ColorHEX]		= @ColorHEX
					,[StatusId]		= @StatusId
					,[RegionTypeId]	= @RegionTypeId
					,[LocationId]	= @LocationId
					,[IsCoalition]	= @IsCoalition

			  WHERE [Id] = @Id

			--Coalition check for parties batch insert and check for residual party records in composite table if not coalition
			IF(@IsCoalition = 1 OR EXISTS (SELECT [CoalitionId] FROM [dbo].[PartyCoalitions] WHERE [CoalitionId] = @Id))
				BEGIN
					PRINT 'Beginning composite table update...'

					--Remove all parties from coaliton party with matching coalition party Id
					DELETE 
					FROM [dbo].[PartyCoalitions]
					WHERE [CoalitionId] = @Id

					DECLARE @fPartyId INT = (SELECT TOP 1 [PartyId] FROM @partyCompositeUDT)

					--Insert all parties into coaliton party from UDT input if record #1 is greater than zero
					IF(@IsCoalition = 1 AND @fPartyId > 0)
						BEGIN
							--Combine current Id and batch UDT parties columns together, then input batch results into composite table
							PRINT 'Batch inserting into composite table...'
							
							INSERT INTO [dbo].[PartyCoalitions] (
																 [CoalitionId]
																 ,[PartyId]
																)
							SELECT CoalitionId = @Id
								   ,pCUDT.[PartyId]
							FROM @partyCompositeUDT AS pCUDT
						END
			
					ELSE PRINT 'Empty batch and no insert.'
				END

		COMMIT TRANSACTION;
		DECLARE @Success BIT = 1
	END TRY

	BEGIN CATCH
		PRINT 'Error! Rolling back transaction -- ' + ERROR_MESSAGE()
		ROLLBACK TRANSACTION; 
		SET @Success = 0
	END CATCH

	IF(@Success = 1)
		BEGIN
			PRINT @Name + ' has been successfully updated!'
		END
END
