USE [Fresh_3.5]
GO
/****** Object:  StoredProcedure [dbo].[AjaxProductLoadAllPaged]    Script Date: 08-08-2016 09:22:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



alter PROCEDURE [dbo].[TestAjaxProductLoadAllPaged]
(
	@FilteredProductAttribute nvarchar(MAX) = null	--filter by ProductAttribute (comma-separated list). e.g. 14,15,16
)
AS
BEGIN
	
	
	DECLARE
		@SearchKeywords bit,
		@sql nvarchar(max),
		@sql_orderby nvarchar(max)

	SET NOCOUNT ON
	
	
		SET @SearchKeywords = 0
	

		--filter by ProductattributesValue
	SET @FilteredProductAttribute = isnull(@FilteredProductAttribute, '')	
		CREATE TABLE #FilteredProductattributesTemp
	(
		ProductAttributeIdValue nvarchar(50) not null
	)
	INSERT INTO #FilteredProductattributesTemp (ProductAttributeIdValue)
	SELECT CAST(data as nvarchar(50)) FROM [nop_splitstring_to_table](@FilteredProductAttribute, '|')

	
	CREATE TABLE #FilteredProductattributes
	(
		ProductAttributeId int not null,
		ProductAttributeValue nvarchar(50) not null
	)
	
	
	DECLARE @PAttributeIdvalue nvarchar(50)	
	DECLARE @id int 
	DECLARE @attribute nvarchar(50)	

DECLARE cur_spliteattribute CURSOR FOR
SELECT [ProductAttributeIdValue]
FROM #FilteredProductattributesTemp
OPEN cur_spliteattribute
FETCH NEXT FROM cur_spliteattribute INTO @PAttributeIdvalue
WHILE @@FETCH_STATUS = 0
BEGIN	

 Set @id=CAST(SUBSTRING(@PAttributeIdvalue , 0, CHARINDEX('_',@PAttributeIdvalue))as int)
 Set @attribute = SUBSTRING(@PAttributeIdvalue ,CHARINDEX('_',@PAttributeIdvalue)+1,LEN(@PAttributeIdvalue))	
 INSERT INTO #FilteredProductattributes (ProductAttributeId,ProductAttributeValue) values(@id,@attribute)
  FETCH NEXT FROM cur_spliteattribute INTO @PAttributeIdvalue
End
CLOSE cur_spliteattribute
DEALLOCATE cur_spliteattribute

	CREATE TABLE #DisplayOrderTmp 
	(
		[Id] int IDENTITY (1, 1) NOT NULL,
		[ProductId] int NOT NULL
	)

	SET @sql = '
	INSERT INTO #DisplayOrderTmp ([ProductId])
	SELECT p.Id
	FROM
		Product p with (NOLOCK)'
	
	SET @sql = @sql + '
	WHERE
		p.Deleted = 0'
	--PRINT (@sql)
	EXEC sp_executesql @sql

	 SELECT * From #DisplayOrderTmp
	DECLARE @attributeId int	
	
DECLARE cur_takedistincattribute CURSOR FOR
SELECT DISTINCT [ProductAttributeId]
FROM #FilteredProductattributes
OPEN cur_takedistincattribute
FETCH NEXT FROM cur_takedistincattribute INTO @attributeId
WHILE @@FETCH_STATUS = 0
BEGIN	

Delete from #DisplayOrderTmp where [ProductId] Not In
(select [ProductId] from Product_ProductAttribute_Mapping with (NOLOCK) where Id In
(select [ProductAttributeMappingId] from ProductAttributeValue with (NOLOCK) where [ProductAttributeMappingId] IN
(select Id from Product_ProductAttribute_Mapping with (NOLOCK) where ProductAttributeId= @attributeId) And Name In
 (select [ProductAttributeValue] from #FilteredProductattributes with (NOLOCK) where  ProductAttributeId = @attributeId)))

  FETCH NEXT FROM cur_takedistincattribute INTO @attributeId
End
CLOSE cur_takedistincattribute
DEALLOCATE cur_takedistincattribute

		select * from #FilteredProductattributesTemp
		select * from #FilteredProductattributes
		
		DROP TABLE #FilteredProductattributesTemp
		DROP TABLE #FilteredProductattributes
		
	
	SELECT * from #DisplayOrderTmp
	DROP TABLE #DisplayOrderTmp

END
