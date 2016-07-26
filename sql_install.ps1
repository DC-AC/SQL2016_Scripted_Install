& 'D:\setup.exe' /ConfigurationFile=C:\temp\ConfigurationFile.ini
# Download Ola's scripts
invoke-WebRequest https://ola.hallengren.com/scripts/MaintenanceSolution.sql -outfile c:\temp\ola.sql

$CMD = 'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\SQLCMD.EXE'
$ARG1 = '-E'
$ARG2 = '-i'
$ARG3 = 'C:\temp\best_practices_run_once.sql'
& $CMD $ARG1 $ARG2 $ARG3


$CMD = 'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\SQLCMD.EXE'
$ARG1=  '-E'
$ARG2 = '-i'
$ARG3 = 'C:\temp\ola.sql'
& $CMD $ARG1 $ARG2 $ARG3

$CMD ='C:\Temp\SSMS-Setup-ENU.exe'
$ARG1 =' /install'
$ARG2 = '/norestart'
$ARG3 = '/quiet'
$ARG4 = '/log ssms.log'
& $CMD $ARG1 $ARG2 $ARG3 $ARG4
