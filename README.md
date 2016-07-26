# SQL2016_Scripted_Install

This is SQL 2016 scripted install process. There is a best practices script which configures SQL Server with best practices. 

A few assumptions here:

--You have SQL Media mounted to the D: drive

--You have Ola Hallengen's scripts in C:\temp. I'm having an issue with invoke-webrequest in Windows 2016 that I need to get worked out

--The SSMS silent installer doesn't offer any indication of progress, and has worked about 50% of the time in my testing

--Even though SQL Server 2016 does not require .NET 3.5, Database Mail does. I'm currently waiting to hear back to see if this fixed in CU1

--This looks for updates in C:\SQLUpdates, you may wish to update to a different drive (a network share works well)

--This script puts data files on the E: drive--you may need to change for Azure VMs
