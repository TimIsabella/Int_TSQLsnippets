-- =============================================
-- Author: Tim Isabella
-- Create date:
-- Description: Insert snippet into 'Snippets' table and batch insert snippet members if alliance
-- Code Reviewer:
-- =============================================

ALTER PROC [dbo].[Snippet_Insert]
			@Name NVARCHAR(200)
			,@Code NVARCHAR(50)
			,@Logo NVARCHAR(255)
			,@SiteUrl NVARCHAR(255)
			,@ColorHEX nchar(7)
			,@StatusId INT
			,@RegionTypeId INT
			,@LocationId INT
			,@IsAlliance BIT
			,@snippetCompositeUDT AS [dbo].[SnippetCompositeUDT] READONLY
			,@Id INT OUTPUT
			
AS

/*-----------Test Code-----------
DECLARE @Name NVARCHAR(200)					= 'Test Snippet'
		,@Code NVARCHAR(50)				= 'BP'
		,@Logo NVARCHAR(255)				= 'https://SnippetLogo.url'
		,@SiteUrl NVARCHAR(255)				= 'https://SnippetSiteUrl.com'
		,@ColorHEX nchar(7)				= '#f28500'
		,@StatusId INT					= 2
		,@RegionTypeId INT				= 1
		,@LocationId INT				= 3
		,@IsAlliance BIT				= 1
		,@snippetCompositeUDT AS [dbo].[SnippetCompositeUDT]
		,@Id INT

		INSERT INTO @snippetCompositeUDT (SnippetId) VALUES (1)
		INSERT INTO @snippetCompositeUDT (SnippetId) VALUES (2)
		INSERT INTO @snippetCompositeUDT (SnippetId) VALUES (3)
		INSERT INTO @snippetCompositeUDT (SnippetId) VALUES (4)

EXECUTE [dbo].[Snippets_Insert]
		@Name
		,@Code
		,@Logo
		,@SiteUrl
		,@ColorHEX
		,@StatusId
		,@RegionTypeId
		,@LocationId
		,@IsAlliance
		,@snippetCompositeUDT
		,@Id

SELECT *
FROM [dbo].[Snippets]
---------------------------------*/

BEGIN
	
	--Snippet name check
	IF EXISTS (SELECT [Name] FROM [dbo].[Snippets] WHERE [Name] = @Name)
		BEGIN
			PRINT '"' + CONVERT(varchar(200), @Name) + '" already exists -- Canceling insert.'
			RETURN
		END

	BEGIN TRY
		BEGIN TRANSACTION;
			
			PRINT 'Inserting snippet...'

			DECLARE @RegistrationDate DATETIME2(7) = GETUTCDATE()

			INSERT INTO
			[dbo].[Snippets] (
							[Name]
							,[Code]
							,[Logo]
							,[SiteUrl]
							,[ColorHEX]
							,[StatusId]
							,[RegionTypeId]
							,[LocationId]
							,[IsAlliance]
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
							,@IsAlliance
							,@RegistrationDate
							)
			SET @Id = SCOPE_IDENTITY()

			--Alliance check for snippets batch insert
			IF(@IsAlliance = 1)
				BEGIN
					PRINT 'Beginning composite table update...'

					--Remove all snippets from coaliton snippet with matching alliance snippet Id
					DELETE 
					FROM [dbo].[SnippetAlliances]
					WHERE [AllianceId] = @Id

					DECLARE @fSnippetId INT = (SELECT TOP 1 [SnippetId] FROM @snippetCompositeUDT)

					--Insert all snippets into alliance snippet from UDT input if record #1 is greater than zero
					IF(@fSnippetId > 0)
						BEGIN
							--Combine current Id and batch UDT snippets columns together, then input batch results into composite table
							PRINT 'Batch inserting into composite table...'
							
							INSERT INTO [dbo].[SnippetAlliances] (
																 [AllianceId]
																 ,[SnippetId]
																)
							SELECT AllianceId = @Id
								   ,pCUDT.[SnippetId]
							FROM @snippetCompositeUDT AS pCUDT
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
