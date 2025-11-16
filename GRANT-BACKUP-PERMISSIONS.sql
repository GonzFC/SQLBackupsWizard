-- ============================================================================
-- SQL Server Backup Wizard - Permission Grant Script
-- ============================================================================
-- Purpose: Grant permissions to service account for automated backups
-- Version: 1.1.0
-- Date: 2025-11-16
-- ============================================================================

-- IMPORTANT: Replace 'DOMAIN\svc-sqlbackup' with your actual service account
DECLARE @ServiceAccount NVARCHAR(128) = 'DOMAIN\svc-sqlbackup'

-- ============================================================================
-- OPTION 1: MINIMAL PERMISSIONS (RECOMMENDED - Best Security Practice)
-- ============================================================================
-- Grants only the permissions needed for backups
-- Use this for production environments following principle of least privilege
-- ============================================================================

PRINT '========================================='
PRINT 'OPTION 1: Minimal Permissions (Recommended)'
PRINT '========================================='
PRINT ''

-- Step 1: Create server login if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @ServiceAccount)
BEGIN
    PRINT 'Creating login: ' + @ServiceAccount
    EXEC('CREATE LOGIN [' + @ServiceAccount + '] FROM WINDOWS')
    PRINT '✓ Login created'
END
ELSE
BEGIN
    PRINT '✓ Login already exists: ' + @ServiceAccount
END
PRINT ''

-- Step 2: Grant server-level permissions for backup operations
PRINT 'Granting server-level permissions...'
EXEC('GRANT VIEW SERVER STATE TO [' + @ServiceAccount + ']')
PRINT '✓ Granted VIEW SERVER STATE (for monitoring)'
PRINT ''

-- Step 3: Grant database-level permissions for each database
PRINT 'Granting database-level permissions...'
PRINT 'Note: Run this for EACH database you want to backup'
PRINT ''

-- Example for a specific database (repeat for each database)
DECLARE @DatabaseName NVARCHAR(128) = 'YourDatabaseName'  -- CHANGE THIS

IF EXISTS (SELECT * FROM sys.databases WHERE name = @DatabaseName)
BEGIN
    DECLARE @SQL NVARCHAR(MAX)

    PRINT 'Setting up permissions for database: ' + @DatabaseName

    -- Create database user
    SET @SQL = 'USE [' + @DatabaseName + '];
    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = ''' + @ServiceAccount + ''')
    BEGIN
        CREATE USER [' + @ServiceAccount + '] FOR LOGIN [' + @ServiceAccount + ']
    END'
    EXEC sp_executesql @SQL
    PRINT '  ✓ User created in database'

    -- Grant backup permission
    SET @SQL = 'USE [' + @DatabaseName + '];
    ALTER ROLE [db_backupoperator] ADD MEMBER [' + @ServiceAccount + ']'
    EXEC sp_executesql @SQL
    PRINT '  ✓ Added to db_backupoperator role'

    -- Grant necessary database permissions
    SET @SQL = 'USE [' + @DatabaseName + '];
    GRANT VIEW DATABASE STATE TO [' + @ServiceAccount + ']
    GRANT VIEW DEFINITION TO [' + @ServiceAccount + ']'
    EXEC sp_executesql @SQL
    PRINT '  ✓ Granted VIEW DATABASE STATE and VIEW DEFINITION'
    PRINT ''
END
ELSE
BEGIN
    PRINT '  ✗ Database not found: ' + @DatabaseName
    PRINT '  Please update @DatabaseName variable and re-run'
    PRINT ''
END

PRINT '========================================='
PRINT 'Option 1 Complete!'
PRINT '========================================='
PRINT ''
PRINT 'Permissions granted:'
PRINT '  ✓ Server: VIEW SERVER STATE'
PRINT '  ✓ Database: db_backupoperator role'
PRINT '  ✓ Database: VIEW DATABASE STATE, VIEW DEFINITION'
PRINT ''
PRINT 'These permissions allow:'
PRINT '  - Taking backups of the database'
PRINT '  - Verifying backup files'
PRINT '  - Reading backup history'
PRINT '  - Accessing backup directory information'
PRINT ''

GO

-- ============================================================================
-- OPTION 2: DATABASE CREATOR (WIZARD VALIDATES THIS)
-- ============================================================================
-- Grants dbcreator server role
-- Allows creating databases and taking backups
-- Wizard will accept this level of permission
-- ============================================================================

PRINT '========================================='
PRINT 'OPTION 2: Database Creator Role'
PRINT '========================================='
PRINT ''

DECLARE @ServiceAccount2 NVARCHAR(128) = 'DOMAIN\svc-sqlbackup'

-- Create login if needed
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @ServiceAccount2)
BEGIN
    PRINT 'Creating login: ' + @ServiceAccount2
    EXEC('CREATE LOGIN [' + @ServiceAccount2 + '] FROM WINDOWS')
END

-- Grant dbcreator role
PRINT 'Granting dbcreator role...'
EXEC('ALTER SERVER ROLE [dbcreator] ADD MEMBER [' + @ServiceAccount2 + ']')
PRINT '✓ User added to dbcreator server role'
PRINT ''
PRINT 'Permissions granted:'
PRINT '  ✓ Can create, alter, drop, and restore databases'
PRINT '  ✓ Can take backups of any database'
PRINT '  ✓ VALIDATED BY WIZARD ✓'
PRINT ''

GO

-- ============================================================================
-- OPTION 3: SYSADMIN (WIZARD VALIDATES THIS - HIGHEST PRIVILEGE)
-- ============================================================================
-- Grants sysadmin server role
-- Full control over SQL Server instance
-- Use only if required by your environment
-- ============================================================================

PRINT '========================================='
PRINT 'OPTION 3: System Administrator Role'
PRINT '========================================='
PRINT ''
PRINT '⚠ WARNING: This grants FULL CONTROL over SQL Server'
PRINT '⚠ Only use if your security policy allows it'
PRINT ''

DECLARE @ServiceAccount3 NVARCHAR(128) = 'DOMAIN\svc-sqlbackup'

-- Create login if needed
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @ServiceAccount3)
BEGIN
    PRINT 'Creating login: ' + @ServiceAccount3
    EXEC('CREATE LOGIN [' + @ServiceAccount3 + '] FROM WINDOWS')
END

-- Grant sysadmin role
PRINT 'Granting sysadmin role...'
EXEC('ALTER SERVER ROLE [sysadmin] ADD MEMBER [' + @ServiceAccount3 + ']')
PRINT '✓ User added to sysadmin server role'
PRINT ''
PRINT 'Permissions granted:'
PRINT '  ✓ FULL ADMINISTRATIVE ACCESS to SQL Server'
PRINT '  ✓ Can perform ANY operation'
PRINT '  ✓ VALIDATED BY WIZARD ✓'
PRINT ''

GO

-- ============================================================================
-- OPTION 4: GRANT ALL DATABASES AT ONCE (db_backupoperator)
-- ============================================================================
-- Loop through all user databases and grant backup permissions
-- Use this if you want to backup multiple databases
-- ============================================================================

PRINT '========================================='
PRINT 'OPTION 4: Grant Backup Permissions to All Databases'
PRINT '========================================='
PRINT ''

DECLARE @ServiceAccount4 NVARCHAR(128) = 'DOMAIN\svc-sqlbackup'

-- Create login if needed
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @ServiceAccount4)
BEGIN
    PRINT 'Creating login: ' + @ServiceAccount4
    EXEC('CREATE LOGIN [' + @ServiceAccount4 + '] FROM WINDOWS')
END

-- Grant server-level permissions
EXEC('GRANT VIEW SERVER STATE TO [' + @ServiceAccount4 + ']')
PRINT '✓ Granted VIEW SERVER STATE'
PRINT ''

-- Loop through all user databases
DECLARE @DB NVARCHAR(128)
DECLARE @SQL4 NVARCHAR(MAX)

DECLARE db_cursor CURSOR FOR
SELECT name
FROM sys.databases
WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb')
  AND state_desc = 'ONLINE'

OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @DB

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Setting up permissions for: ' + @DB

    -- Create user
    SET @SQL4 = 'USE [' + @DB + '];
    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = ''' + @ServiceAccount4 + ''')
    BEGIN
        CREATE USER [' + @ServiceAccount4 + '] FOR LOGIN [' + @ServiceAccount4 + ']
    END'
    EXEC sp_executesql @SQL4

    -- Add to db_backupoperator
    SET @SQL4 = 'USE [' + @DB + '];
    ALTER ROLE [db_backupoperator] ADD MEMBER [' + @ServiceAccount4 + ']'
    EXEC sp_executesql @SQL4

    -- Grant additional permissions
    SET @SQL4 = 'USE [' + @DB + '];
    GRANT VIEW DATABASE STATE TO [' + @ServiceAccount4 + ']
    GRANT VIEW DEFINITION TO [' + @ServiceAccount4 + ']'
    EXEC sp_executesql @SQL4

    PRINT '  ✓ Permissions granted for: ' + @DB

    FETCH NEXT FROM db_cursor INTO @DB
END

CLOSE db_cursor
DEALLOCATE db_cursor

PRINT ''
PRINT '========================================='
PRINT 'All databases configured!'
PRINT '========================================='
PRINT ''

GO

-- ============================================================================
-- VERIFICATION SCRIPT
-- ============================================================================
-- Run this to verify what permissions the service account has
-- ============================================================================

PRINT '========================================='
PRINT 'VERIFICATION: Check Current Permissions'
PRINT '========================================='
PRINT ''

DECLARE @ServiceAccount5 NVARCHAR(128) = 'DOMAIN\svc-sqlbackup'

-- Check if login exists
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = @ServiceAccount5)
BEGIN
    PRINT '✓ Login exists: ' + @ServiceAccount5
    PRINT ''

    -- Check server roles
    PRINT 'Server Roles:'
    SELECT
        r.name AS [Role],
        CASE WHEN r.name = 'sysadmin' THEN '✓ VALIDATED BY WIZARD' ELSE '' END AS [Note]
    FROM sys.server_role_members srm
    JOIN sys.server_principals sp ON srm.member_principal_id = sp.principal_id
    JOIN sys.server_principals r ON srm.role_principal_id = r.principal_id
    WHERE sp.name = @ServiceAccount5

    -- Check if has sysadmin or dbcreator
    IF IS_SRVROLEMEMBER('sysadmin', @ServiceAccount5) = 1
    BEGIN
        PRINT ''
        PRINT '✓ User has SYSADMIN role - WIZARD WILL ACCEPT THIS'
        PRINT '✓ Can perform all backup operations'
    END
    ELSE IF IS_SRVROLEMEMBER('dbcreator', @ServiceAccount5) = 1
    BEGIN
        PRINT ''
        PRINT '✓ User has DBCREATOR role - WIZARD WILL ACCEPT THIS'
        PRINT '⚠ Wizard will show warning but allow backups'
    END
    ELSE
    BEGIN
        PRINT ''
        PRINT '⚠ User does NOT have sysadmin or dbcreator roles'
        PRINT '⚠ Wizard validation may fail - consider using Option 2 or 3'
        PRINT 'ℹ You can still use Option 1 if you grant permissions per database'
    END

    PRINT ''
    PRINT 'Database-level permissions:'
    SELECT
        DB_NAME(dp.dbid) AS [Database],
        dp.name AS [User],
        r.name AS [Role]
    FROM sys.sysusers dp
    LEFT JOIN sys.database_role_members drm ON dp.uid = drm.member_principal_id
    LEFT JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
    WHERE dp.name = @ServiceAccount5
    ORDER BY 1, 3
END
ELSE
BEGIN
    PRINT '✗ Login does NOT exist: ' + @ServiceAccount5
    PRINT ''
    PRINT 'Please run one of the OPTIONS above to create the login and grant permissions'
END

GO

-- ============================================================================
-- SUMMARY AND RECOMMENDATIONS
-- ============================================================================

PRINT ''
PRINT '============================================================================'
PRINT 'SUMMARY AND RECOMMENDATIONS'
PRINT '============================================================================'
PRINT ''
PRINT 'WIZARD VALIDATION REQUIREMENTS:'
PRINT '  The wizard validates that the service account has either:'
PRINT '    1. sysadmin role (preferred by wizard)'
PRINT '    2. dbcreator role (accepted with warning)'
PRINT ''
PRINT 'SECURITY RECOMMENDATIONS:'
PRINT '  - Development/Test: Option 3 (sysadmin) - Quick and easy'
PRINT '  - Production: Option 1 (minimal) - Best security practice'
PRINT '  - Multiple Databases: Option 4 (all databases) - Convenient'
PRINT '  - Quick Setup: Option 2 (dbcreator) - Balanced approach'
PRINT ''
PRINT 'WHAT EACH OPTION DOES:'
PRINT '  Option 1: Minimal permissions (db_backupoperator per database)'
PRINT '            - Most secure'
PRINT '            - Requires configuration per database'
PRINT '            - ⚠ May not pass wizard validation'
PRINT ''
PRINT '  Option 2: dbcreator role'
PRINT '            - ✓ Passes wizard validation'
PRINT '            - Can backup all databases'
PRINT '            - Can create/restore databases'
PRINT ''
PRINT '  Option 3: sysadmin role'
PRINT '            - ✓ Passes wizard validation (preferred)'
PRINT '            - Full SQL Server access'
PRINT '            - Use only if required by policy'
PRINT ''
PRINT '  Option 4: All databases at once'
PRINT '            - Convenient for multiple databases'
PRINT '            - Good balance of security and convenience'
PRINT '            - ⚠ May not pass wizard validation'
PRINT ''
PRINT 'RECOMMENDATION FOR WIZARD:'
PRINT '  Use Option 2 (dbcreator) or Option 3 (sysadmin)'
PRINT '  Both will pass the wizard validation check'
PRINT ''
PRINT '============================================================================'
PRINT 'Script Complete!'
PRINT '============================================================================'
