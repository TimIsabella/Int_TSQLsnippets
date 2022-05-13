-- =============================================
-- Author: Tim Isabella
-- Create date:
-- Description: Update snippet record in 'Snippets' table and batch insert or remove snippet members if alliance
-- Code Reviewer:
-- =============================================

ALTER PROC [dbo].[Snippets_Update]
			@Id INT
			,@Name NVARCHAR(200)
			,@Code NVARCHAR(50)
			,@Logo NVARCHAR(255)
			,@SiteUrl NVARCHAR(255)
			,@ColorHEX nchar(7)
			,@StatusId INT
			,@RegionTypeId INT
			,@LocationId INT
			,@IsAlliances BIT
			,@snippetCompositeUDT AS [dbo].[SnippetCompositeUDT] READONLY

AS

/*-----------Test Code-----------
DECLARE @Id INT							= 30
		,@Name NVARCHAR(200)			= 'Test Snippet'
		,@Code NVARCHAR(50)				= 'BP'
		,@Logo NVARCHAR(255)			= 'https://cdn.shopify.com/s/files/1/0271/9150/9091/files/snippetImage.png'
		,@SiteUrl NVARCHAR(255)			= 'https://siteUrl.com'
		,@ColorHEX nchar(7)				= '#f28500'
		,@StatusId INT					= 2
		,@RegionTypeId INT				= 1
		,@LocationId INT				= 3
		,@IsAlliance BIT				= 1
		,@snippetCompositeUDT AS [dbo].[SnippetCompositeUDT]
		INSERT INTO @snippetCompositeUDT (SnippetId) VALUES (15)
		INSERT INTO @snippetCompositeUDT (SnippetId) VALUES (16)
		INSERT INTO @snippetCompositeUDT (SnippetId) VALUES (17)
		INSERT INTO @snippetCompositeUDT (SnippetId) VALUES (18)
EXECUTE [dbo].[Snippets_Update]
		@Id
		,@Name
		,@Code
		,@Logo
		,@SiteUrl
		,@ColorHEX
		,@StatusId
		,@RegionTypeId
		,@LocationId
		,@IsAlliance
		,@snippetCompositeUDT
SELECT *
FROM [dbo].[Snippets]
SELECT *
FROM [dbo].[SnippetAlliances]
---------------------------------*/

BEGIN
	
	--Snippet id check
	IF NOT EXISTS (SELECT [Id] FROM [dbo].[Snippets] WHERE [Id] = @Id)
		BEGIN
			PRINT 'Alliance snippet Id#' + CONVERT(varchar(10), @Id) + ' does not exists -- Canceling update.'
			RETURN
		END
	
	BEGIN TRY
		BEGIN TRANSACTION;

			PRINT 'Updating alliance snippet...'

			UPDATE [dbo].[Snippets]
				SET [Name]			  = @Name
					,[Code]			    = @Code
					,[Logo]			    = @Logo
					,[SiteUrl]		  = @SiteUrl
					,[ColorHEX]		  = @ColorHEX
					,[StatusId]		  = @StatusId
					,[RegionTypeId]	= @RegionTypeId
					,[LocationId]	  = @LocationId
					,[IsAlliance]	  = @IsAlliance

			  WHERE [Id] = @Id

			--Alliance check for snippets batch insert and check for residual snippet records in composite table if not alliance
			IF(@IsAlliance = 1 OR EXISTS (SELECT [AllianceId] FROM [dbo].[SnippetAlliances] WHERE [AllianceId] = @Id))
				BEGIN
					PRINT 'Beginning composite table update...'

					--Remove all snippets from alliance snippet with matching alliance snippet Id
					DELETE 
					FROM [dbo].[SnippetAlliances]
					WHERE [AllianceId] = @Id

					DECLARE @fSnippetId INT = (SELECT TOP 1 [SnippetId] FROM @snippetCompositeUDT)

					--Insert all snippets into alliance snippet from UDT input if record #1 is greater than zero
					IF(@IsAlliance = 1 AND @fSnippetId > 0)
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
