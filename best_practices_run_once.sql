/******  BEST PRACTICES  ******/

--enable trace flags for tempdb allocation
--Trace Flag 3226    Suppress the backup transaction log entries from the SQL Server Log

create procedure enable_trace_flags as

dbcc traceon (3226, -1) 
dbcc traceon (1222, -1);
GO

exec sp_procoption @procname='enable_trace_flags', @optionName='startup', @optionValue='true'

exec enable_trace_flags;


EXEC sp_configure 'show advanced options', '1';
RECONFIGURE
GO

--modify model database
ALTER DATABASE model SET RECOVERY SIMPLE;
GO
ALTER DATABASE model MODIFY FILE (NAME = modeldev, FILEGROWTH = 100MB)
go

ALTER DATABASE model MODIFY FILE (NAME = modellog, FILEGROWTH = 100MB)
go


--modify msdb database
ALTER DATABASE msdb SET RECOVERY SIMPLE;
GO
ALTER DATABASE msdb MODIFY FILE (NAME = msdbdata, FILEGROWTH = 100MB)
go

ALTER DATABASE msdb MODIFY FILE (NAME = msdblog, FILEGROWTH = 100MB)
go

--modify master database
ALTER DATABASE master SET RECOVERY SIMPLE;
GO
ALTER DATABASE master MODIFY FILE (NAME = master, FILEGROWTH = 100MB)
go

ALTER DATABASE master MODIFY FILE (NAME = mastlog, FILEGROWTH = 100MB)
go



/******  CONFIGURE TEMPDB  DATA FILES ******/

declare @sql_statement nvarchar(4000),
		@data_file_path nvarchar(100),
		@drive_size_gb int,
		@individ_file_size int,
		@number_of_files int;




SELECT @data_file_path =    
(   SELECT distinct(LEFT(physical_name,LEN(physical_name)-CHARINDEX('\',REVERSE(physical_name))+1))
    FROM sys.master_files mf   
    INNER JOIN sys.[databases] d   
    ON mf.[database_id] = d.[database_id]   
    WHERE D.name = 'tempdb' and type = 0);
--Input size of drive holding temp DB files here
SELECT @drive_size_gb = 4
--SELECT @DRIVE_SIZE_GB=total_bytes/1024/1024/1024 from sys.dm_os_volume_stats (2,1)


SELECT @number_of_files = count (*) from sys.master_Files where database_Id=2 and type = 0
SELECT  @individ_file_size = (@drive_size_gb*1024*.8)/(@number_of_files)
	
/*
PRINT '-- TEMP DB Configuration --'
PRINT 'Temp DB Data Path: ' + @data_file_path
PRINT 'File Size in MB: ' +convert(nvarchar(25),@individ_file_size)
PRINT 'Number of files: '+convert(nvarchar(25), @number_of_files)
*/

WHILE @number_of_files > 0
BEGIN
	if @number_of_files = 1 -- main tempdb file, move and re-size
		BEGIN
			SELECT @sql_statement = 'ALTER DATABASE tempdb MODIFY FILE (NAME = tempdev, SIZE = '+ convert(nvarchar(25), @individ_file_size) + ', filename = '+nCHAR(39)+@data_file_path+'tempdb.mdf'+nCHAR(39)+',MAXSIZE = '+ convert(nvarchar(25), @individ_file_size) + ', FILEGROWTH = 100MB);';
		END
	ELSE -- numbered tempdb file, add and re-size
		BEGIN
			SELECT @sql_statement = 'ALTER DATABASE tempdb MODIFY FILE (NAME = temp'+ convert(nvarchar(25), @number_of_files)+',filename = '+nCHAR(39)+@data_file_path+'tempdb_mssql_' + convert(nvarchar(25), @number_of_files)+'.ndf'+nCHAR(39)+', SIZE = '+ convert(varchar(25), @individ_file_size) + ', MAXSIZE = '+ convert(nvarchar(25), @individ_file_size) + ', FILEGROWTH = 100MB);';
		END
		
		EXEC sp_executesql @statement=@Sql_Statement
		PRINT @sql_statement
		
		SELECT @number_of_files = @number_of_files - 1
END;



EXEC sp_configure 'min server memory', '1024'; -- change to #GB * 1024, leave 2 GB per system for OS, 4GB if over 16GB RAM
RECONFIGURE WITH OVERRIDE;

declare @sqlmemory int
select @sqlmemory=convert(int,(physical_memory_kb/1024*.75)) from sys.dm_os_sys_info;

EXEC sp_configure 'max server memory', @sqlmemory; -- change to #GB * 1024, leave 2 GB per system for OS, 4GB if over 16GB RAM
RECONFIGURE WITH OVERRIDE;



/*SELECT MaxDOP for Server Based on CPU Count */

begin

DECLARE @cpu_Countdop int
select @cpu_Countdop=cpu_count
FROM sys.dm_os_sys_info dosi

exec sp_configure 'show advanced options', 1;
RECONFIGURE WITH OVERRIDE;
exec sp_configure 'max degree of parallelism', @cpu_countdop;
RECONFIGURE WITH OVERRIDE;
end

EXEC sp_configure 'xp_cmdshell', 0;
GO
RECONFIGURE
GO

EXEC sp_configure 'remote admin connections',1;
GO
RECONFIGURE;
GO
EXEC sp_configure 'backup compression default', 1 ;
RECONFIGURE WITH OVERRIDE ;
GO
sp_configure 'show advanced options',1
GO
RECONFIGURE WITH OVERRIDE
GO
sp_configure 'Database Mail XPs',1
GO
RECONFIGURE 
GO
EXEC sp_configure 'show advanced options', 1 ;
GO
RECONFIGURE
GO
EXEC sp_configure 'cost threshold for parallelism', 35 ;
GO
RECONFIGURE
GO
-------------------------------------------------------------
--  Database Mail Simple Configuration Template.
--
--  This template creates a Database Mail profile, an SMTP account and 
--  associates the account to the profile.
--  The template does not grant access to the new profile for
--  any database principals.  Use msdb.dbo.sysmail_add_principalprofile
--  to grant access to the new profile for users who are not
--  members of sysadmin.
-------------------------------------------------------------

DECLARE @profile_name sysname,
        @account_name sysname,
        @SMTP_servername sysname,
        @email_address NVARCHAR(128),
	@display_name NVARCHAR(128),
	@err NVARCHAR(2000);

-- Profile name. Replace with the name for your profile
        SELECT @profile_name = 'dbmail_profile';

-- Account information. Replace with the information for your account.
		SELECT @account_name = 'Google SMTP'
		SELECT @SMTP_servername = 'smtp.gmail.com';
		SELECT @email_address = 'joey.dantoni@gmail.com';
        	SELECT @display_name = 'SQL Server '+@@servername+' DBMail';
	    	SELECT @err = '''The specified Database Mail profile '+@profile_name+' already exists.'''
		
-- Verify the specified account and profile do not already exist.
IF EXISTS (SELECT * FROM msdb.dbo.sysmail_profile WHERE name = @profile_name)
BEGIN
  RAISERROR(@err, 16, 1);
  GOTO done;
END;

IF EXISTS (SELECT * FROM msdb.dbo.sysmail_account WHERE name = @account_name )
BEGIN
  RAISERROR(@err, 16, 1);
  GOTO done;
END;

-- Start a transaction before adding the account and the profile
BEGIN TRANSACTION ;

DECLARE @rv INT;

-- Add the account
EXECUTE @rv=msdb.dbo.sysmail_add_account_sp
    @account_name = @account_name,
    @email_address = @email_address,
    @display_name = @display_name,
    @mailserver_name = @SMTP_servername,
    @port=587,
    @username='$useranme',
    @password='$password',
    @enable_ssl=1;

IF @rv<>0
BEGIN
    RAISERROR(@err, 16, 1);
  GOTO done;
END
  
-- Add the profile
EXECUTE @rv=msdb.dbo.sysmail_add_profile_sp
    @profile_name = @profile_name ;

IF @rv<>0
BEGIN
  RAISERROR(@err, 16, 1);
  ROLLBACK TRANSACTION;
    GOTO done;
END;

-- Associate the account with the profile.
EXECUTE @rv=msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = @profile_name,
    @account_name = @account_name,
    @sequence_number = 1 ;

IF @rv<>0
BEGIN
    RAISERROR('Failed to associate the speficied profile with the specified account (<account_name,sysname,SampleAccount>).', 16, 1) ;
	ROLLBACK TRANSACTION;
    GOTO done;
END;

COMMIT TRANSACTION;

done:

DECLARE @msg varchar(1000)
select @msg='Automated Success Message for server '+@@servername 

EXEC msdb.dbo.sp_send_dbmail  
    @profile_name = @profile_name,  
    @recipients = 'email@domain.com',  
    @body = 'The install finished successfully.',  
    @subject = @msg;
GO

/*Configure SQL Agent Alerts */

use [msdb]

EXEC dbo.sp_add_operator
    @name = N'The DBA Team',
    @enabled = 1,
    @email_address = N'email@domain.com',
    @pager_address = N'email@domain.com',
    @weekday_pager_start_time = 000000,
    @weekday_pager_end_time = 235959;
GO

USE [msdb]
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 016',
@message_id=0,
@severity=16,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 016', @operator_name=N'The DBA Team', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 017',
@message_id=0,
@severity=17,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 017', @operator_name=N'The DBA Team', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 018',
@message_id=0,
@severity=18,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 018', @operator_name=N'The DBA Team', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 019',
@message_id=0,
@severity=19,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 019', @operator_name=N'The DBA Team', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 020',
@message_id=0,
@severity=20,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 020', @operator_name=N'The DBA Team', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 021',
@message_id=0,
@severity=21,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 021', @operator_name=N'The DBA Team', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 022',
@message_id=0,
@severity=22,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 022', @operator_name=N'The DBA Team', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 023',
@message_id=0,
@severity=23,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 023', @operator_name=N'The DBA Team', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 024',
@message_id=0,
@severity=24,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 024', @operator_name=N'The DBA Team', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 025',
@message_id=0,
@severity=25,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 025', @operator_name=N'The DBA Team', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 823',
@message_id=823,
 @severity=0,
 @enabled=1,
 @delay_between_responses=60,
 @include_event_description_in=1,
 @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 823', @operator_name=N'The DBA Team', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 824',
 @message_id=824,
 @severity=0,
 @enabled=1,
 @delay_between_responses=60,
 @include_event_description_in=1,
 @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 824', @operator_name=N'The DBA Team', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 825',
 @message_id=825,
 @severity=0,
 @enabled=1,
 @delay_between_responses=60,
 @include_event_description_in=1,
 @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 825', @operator_name=N'The DBA Team', @notification_method = 7;
GO
RAISERROR (N'This is test error.', 17,1)
