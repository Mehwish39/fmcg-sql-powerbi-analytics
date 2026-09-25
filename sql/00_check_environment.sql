-- Read-only. Run in SSMS after connecting to your SQL Server Database Engine.
SELECT
    CAST(SERVERPROPERTY('ProductVersion') AS varchar(50)) AS ProductVersion,
    CAST(SERVERPROPERTY('ProductLevel') AS varchar(50)) AS ProductLevel,
    CAST(SERVERPROPERTY('Edition') AS varchar(100)) AS Edition;
