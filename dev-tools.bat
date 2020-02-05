@echo off
CLS
ECHO.
ECHO **************************************
ECHO Starting Chocolatey Batch
ECHO **************************************


:::::::::::::::::::::::::::::::::::::::::
:: Automatically check & get admin rights
:::::::::::::::::::::::::::::::::::::::::
:checkPrivileges
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto gotPrivileges ) else ( goto getPrivileges )


:getPrivileges
if '%1'=='ELEV' (shift & goto gotPrivileges)  
ECHO.
ECHO **************************************
ECHO Invoking UAC for Privilege Escalation
ECHO **************************************

setlocal DisableDelayedExpansion
set "batchPath=%~0"
setlocal EnableDelayedExpansion
ECHO Set UAC = CreateObject^("Shell.Application"^) > "%temp%\OEgetPrivileges.vbs"
ECHO UAC.ShellExecute "!batchPath!", "ELEV", "", "runas", 1 >> "%temp%\OEgetPrivileges.vbs"
"%temp%\OEgetPrivileges.vbs"
exit /B


:gotPrivileges
::::::::::::::::::::::::::::
:START
::::::::::::::::::::::::::::
setlocal & pushd .

WHERE choco 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto chocoInstalled ) else ( goto chocoMissing )

:chocoMissing

ECHO.
choice /M "Chocolatey not found. Install now?"
IF '%errorlevel%' == '2' exit /B

ECHO.
ECHO **************************************
ECHO Installing Chocolatey
ECHO **************************************

@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin

ECHO.
ECHO **************************************
ECHO Installing Upgrade Task
ECHO **************************************

ECHO ^<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^> > "%temp%\chocotask.xml"
ECHO ^<Triggers^>^<CalendarTrigger^> >> "%temp%\chocotask.xml"
ECHO ^<StartBoundary^>2017-01-01T00:00:00^</StartBoundary^>^<Enabled^>true^</Enabled^>^<RandomDelay^>PT1M^</RandomDelay^> >> "%temp%\chocotask.xml"
ECHO ^<ScheduleByWeek^>^<DaysOfWeek^>^<Saturday /^>^</DaysOfWeek^>^<WeeksInterval^>1^</WeeksInterval^>^</ScheduleByWeek^> >> "%temp%\chocotask.xml"
ECHO ^</CalendarTrigger^>^</Triggers^> >> "%temp%\chocotask.xml"
ECHO ^<Settings^> >> "%temp%\chocotask.xml"
ECHO ^<DisallowStartIfOnBatteries^>true^</DisallowStartIfOnBatteries^> >> "%temp%\chocotask.xml"
ECHO ^<StartWhenAvailable^>true^</StartWhenAvailable^> >> "%temp%\chocotask.xml"
ECHO ^<RunOnlyIfNetworkAvailable^>true^</RunOnlyIfNetworkAvailable^> >> "%temp%\chocotask.xml"
ECHO ^</Settings^> >> "%temp%\chocotask.xml"
ECHO ^<Actions Context="Author"^> >> "%temp%\chocotask.xml"
ECHO ^<Exec^>^<Command^>choco^</Command^>^<Arguments^>upgrade all -y^</Arguments^>^</Exec^> >> "%temp%\chocotask.xml"
ECHO ^</Actions^> >> "%temp%\chocotask.xml"
ECHO ^</Task^> >> "%temp%\chocotask.xml"
more "%temp%\chocotask.xml"
schtasks /Create /TN choco-upgrade /F /IT /XML "%temp%\chocotask.xml"
schtasks /Change /TN choco-upgrade /RL HIGHEST

:chocoInstalled

ECHO.
ECHO **************************************
ECHO Upgrading and Installing Packages
ECHO **************************************

@echo on

choco feature enable --name=allowGlobalConfirmation

:: first, upgrade existing packages
choco upgrade all -y
set choco_install=choco install -fy

:: Small Tools :::::::::::::
%choco_install% git.install --params "/GitAndUnixToolsOnPath /NoShellIntegration /NoGuiHereIntegration /WindowsTerminal"
%choco_install% gitextensions
%choco_install% nodejs-lts
%choco_install% yarn
%choco_install% python
%choco_install% golang
%choco_install% vscode
%choco_install% vscode-settingssync
%choco_install% winmerge
%choco_install% postman
%choco_install% dbeaver
%choco_install% meld
%choco_install% zeal
%choco_install% docker-desktop
 
: run "elevate -k choco install -y <package>" from non-admin cmd to install more packages
%choco_install% ^
 elevate.native
 
:: add more software here

pause

choco feature disable --name=allowGlobalConfirmation