-- =============================================
-- Author: Tim Isabella
-- Create date:
-- Description: Insert party into 'Parties' table and batch insert party members if coalition
-- Code Reviewer:
-- =============================================

ALTER PROC [dbo].[Parties_Insert]
			@Name NVARCHAR(200)
			,@Code NVARCHAR(50)
			,@Logo NVARCHAR(255)
			,@SiteUrl NVARCHAR(255)
			,@ColorHEX nchar(7)
			,@StatusId INT
			,@RegionTypeId INT
			,@LocationId INT
			,@IsCoalition BIT
			,@partyCompositeUDT AS [dbo].[PartyCompositeUDT] READONLY
			,@Id INT OUTPUT
			
AS

/*-----------Test Code-----------
DECLARE @Name NVARCHAR(200)				= 'Test Party'
		,@Code NVARCHAR(50)				= 'BP'
		,@Logo NVARCHAR(255)			= 'https://PartyLogo.url'
		,@SiteUrl NVARCHAR(255)			= 'https://PartySiteUrl.com'
		,@ColorHEX nchar(7)				= '#f28500'
		,@StatusId INT					= 2
		,@RegionTypeId INT				= 1
		,@LocationId INT				= 3
		,@IsCoalition BIT				= 1
		,@partyCompositeUDT AS [dbo].[PartyCompositeUDT]
		,@Id INT

		INSERT INTO @partyCompositeUDT (PartyId) VALUES (1)
		INSERT INTO @partyCompositeUDT (PartyId) VALUES (2)
		INSERT INTO @partyCompositeUDT (PartyId) VALUES (3)
		INSERT INTO @partyCompositeUDT (PartyId) VALUES (4)

EXECUTE [dbo].[Parties_Insert]
		@Name
		,@Code
		,@Logo
		,@SiteUrl
		,@ColorHEX
		,@StatusId
		,@RegionTypeId
		,@LocationId
		,@IsCoalition
		,@partyCompositeUDT
		,@Id

SELECT *
FROM [dbo].[Parties]
---------------------------------*/

BEGIN
	
	--Party name check
	IF EXISTS (SELECT [Name] FROM [dbo].[Parties] WHERE [Name] = @Name)
		BEGIN
			PRINT '"' + CONVERT(varchar(200), @Name) + '" already exists -- Canceling insert.'
			RETURN
		END

	BEGIN TRY
		BEGIN TRANSACTION;
			
			PRINT 'Inserting party...'

			DECLARE @RegistrationDate DATETIME2(7) = GETUTCDATE()

			INSERT INTO
			[dbo].[Parties] (
							[Name]
							,[Code]
							,[Logo]
							,[SiteUrl]
							,[ColorHEX]
							,[StatusId]
							,[RegionTypeId]
							,[LocationId]
							,[IsCoalition]
							,RegistrationDate
							)
					 VALUES(
							@Name
							,@Code
							,@Logo
							,@SiteUrl
							,@ColorHEX
							,@StatusId
							,@RegionTypeId
							,@LocationId
							,@IsCoalition
							,@RegistrationDate
							)
			SET @Id = SCOPE_IDENTITY()

			--Coalition check for parties batch insert
			IF(@IsCoalition = 1)
				BEGIN
					PRINT 'Beginning composite table update...'

					--Remove all parties from coaliton party with matching coalition party Id
					DELETE 
					FROM [dbo].[PartyCoalitions]
					WHERE [CoalitionId] = @Id

					DECLARE @fPartyId INT = (SELECT TOP 1 [PartyId] FROM @partyCompositeUDT)

					--Insert all parties into coaliton party from UDT input if record #1 is greater than zero
					IF(@fPartyId > 0)
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
		DECLARE @Success INT = 1
	END TRY

	BEGIN CATCH
		PRINT 'Error! Rolling back transaction -- ' + ERROR_MESSAGE()
		ROLLBACK TRANSACTION; 
		SET @Success = 0
	END CATCH

	IF(@Success = 1)
		BEGIN
			PRINT '"' + CONVERT(varchar(200), @Name) + '" has been successfully inserted!'
		END
END
