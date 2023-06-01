CREATE TABLE Catalog (
    Name varchar(250),
    Description varchar(250),
    Price decimal,
    PictureFileName varchar(250),
    CatalogTypeId int,
    CatalogBrandId int,
    AvailableStock int,
    RestockThreshold int,
    MaxStockThreshold int,
    OnReorder bit,
    Id int
);
GO

CREATE TABLE CatalogBrand(
    Brand varchar(250),
    Id int
);
GO

CREATE TABLE CatalogRegisterUser(
    firstname varchar(250),
    lastname varchar(250),
    password varchar(250),
    CatalogRegisterUserId varchar(250),
    Id int
);
GO

CREATE TABLE CatalogType(
    Type varchar(250),
    Id int
);
GO

INSERT INTO [dbo].[CatalogBrand]([Brand])VALUES ('Azure') 
INSERT INTO [dbo].[CatalogBrand]([Brand])VALUES ('.NET')
INSERT INTO [dbo].[CatalogBrand]([Brand])VALUES ('SQL Server') 
INSERT INTO [dbo].[CatalogBrand]([Brand])VALUES ('Visual Studio')
INSERT INTO [dbo].[CatalogBrand]([Brand])VALUES ('other') 


INSERT INTO [dbo].[CatalogRegisterUser]([firstname],[lastname],[password],[confirmpassword],[CatalogRegisterUserId])VALUES('Muzz','muzz','12345','12345',1)
INSERT INTO [dbo].[CatalogRegisterUser]([firstname],[lastname],[password],[confirmpassword],[CatalogRegisterUserId])VALUES('Weijuan','w','12345','12345',1)


INSERT INTO [dbo].[CatalogType]([Type])VALUES('Mug')
INSERT INTO [dbo].[CatalogType]([Type])VALUES('T-Shirt')
INSERT INTO [dbo].[CatalogType]([Type])VALUES('Sheet')
INSERT INTO [dbo].[CatalogType]([Type])VALUES('USB Memory Stick')

INSERT INTO [dbo].[Catalog]([Id],[Name],[Description],[Price],[PictureFileName],[CatalogTypeId],[CatalogBrandId],[AvailableStock],[RestockThreshold],[MaxStockThreshold],[OnReorder])VALUES(1,'.NET Bot Black Hoodie','.NET Bot Black Hoodie',19.5,'1.png',	2,2,100,1000,800,200)
INSERT INTO [dbo].[Catalog]([Id],[Name],[Description],[Price],[PictureFileName],[CatalogTypeId],[CatalogBrandId],[AvailableStock],[RestockThreshold],[MaxStockThreshold],[OnReorder])VALUES(2,'.NET Black & White Mug','.NET Black & White Mug',200,'2.png',1,2,200,2000,500,100)
INSERT INTO [dbo].[Catalog]([Id],[Name],[Description],[Price],[PictureFileName],[CatalogTypeId],[CatalogBrandId],[AvailableStock],[RestockThreshold],[MaxStockThreshold],[OnReorder])VALUES(3,'Prism White T-Shirt','Prism White T-Shirt',300,'3.png',2,5,300,400,200,200)
GO








