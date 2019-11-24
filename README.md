# SQL Server 2016 Scripted Install
[![licence badge]][licence]
[![stars badge]][stars]
[![forks badge]][forks]
[![issues badge]][issues]

[licence badge]:https://img.shields.io/badge/license-MIT-blue.svg
[stars badge]:https://img.shields.io/github/stars/DC-AC/SQL2016_Scripted_Install.svg
[forks badge]:https://img.shields.io/github/forks/DC-AC/SQL2016_Scripted_Install.svg
[issues badge]:https://img.shields.io/github/issues/DC-AC/SQL2016_Scripted_Install.svg

[licence]:https://github.com/DC-AC/SQL2016_Scripted_Install/blob/master/LICENSE.md
[stars]:https://github.com/DC-AC/SQL2016_Scripted_Install/stargazers
[forks]:https://github.com/DC-AC/SQL2016_Scripted_Install/network
[issues]:https://github.com/DC-AC/SQL2016_Scripted_Install/issues

This is Microsoft SQL Server 2016 scripted install process. There is a best practices script which configures SQL Server with best practices. 

A few assumptions here:
 - You have SQL Media mounted to the `D:` drive
 - The SSMS silent installer doesn't offer any indication of progress, and has worked about 50% of the time in my testing
 - Even though SQL Server 2016 does not require .NET 3.5, Database Mail does. I'm currently waiting to hear back to see if this fixed in CU1
 - This looks for updates in `C:\SQLUpdates`, you may wish to update to a different drive (a network share works well)
 - This script puts data files on the  `E: ` drive--you may need to change for Azure VMs
 - You need to edit the DB Mail settings for your SMTP server
 
