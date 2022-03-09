@ECHO off

:: Author: Lukas K. Schumann,
:: Mail: lukas_kilian.schumann@stud-mail.uni-wuerzburg.de

:: Newest Version always available at https://10.106.242.102



:: should normally point to fiwi-coordinator: 10.106.242.102
set IPADDRESS=10.106.242.102
:: your user account, i.e. lkschu
set REMOTEUSER=test02


set NODEBUG=gfortran-8 -O3
set DEBUG=gfortran-8 -g -Og
set DETACH=true
set GPU=false



if [%1]==[--install] (
    scp %userprofile%\.ssh\id_rsa.pub %REMOTEUSER%@%IPADDRESS%:id_rsa.pub^
    && ssh %REMOTEUSER%@%IPADDRESS% "cat id_rsa.pub >> .ssh/authorized_keys && rm id_rsa.pub"^
    && goto :EOF^
    || echo Installing ssh keys failed, please check internet and vpn status or contact the administrator.
)

::::::::

:: get timestamp
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "timestamp=%YYYY%-%MM%-%DD%_%HH%-%Min%-%Sec%"

:: set up config
:: :select subroutine defined at the bottom
call :select MAINFILE in ./*.f90
echo Picked %MAINFILE%.

echo --------------------------------
:: main program's name
echo main="%MAINFILE%" > config.cfg

:: choose compiler
:enableDebug
set "answer=x"
set /p answer=Enable debug flags? Gives traceback but can increase runtime.(y/N)
if %answer%==y (
    echo Debugging active.
    echo compiler="%DEBUG%" >> config.cfg
) else (
    if %answer%==n (
	  echo Debugging inactive.
      echo compiler="%NODEBUG%" >> config.cfg
	) else (
	  echo Please answer ^(y^)es or ^(n^)o.
	  goto :enableDebug
	)
)

:: local or detach?
:enableDetach
set "answer=x"
set /p answer=Detach execution to run in background?(y/n)
if %answer%==y (
    echo Detaching.
    set "DETACH=true"
) else (
    if %answer%==n (
	  echo Not detatching.
	  set "DETACH=false"
	) else (
	  echo Please answer ^(y^)es or ^(n^)o.
	  goto :enableDetach
	)
)


:: timestamp to create temporary directory
echo timestamp="%timestamp%" >> config.cfg
echo --------------------------------

::::::::

:: send source and config for compiler
tar -czf source.tar.gz *.f90 config.cfg

:: create directory on the server,
:: -vvv circumvents openssh_on_windows bug freezing the shell.
:: minimized subshell to hide the output, logfiles wouldn't always prevent the bug.
:: start /high /wait /min ssh -vvv %REMOTEUSER%@%IPADDRESS% mkdir web_html/data/%timestamp%

ssh %REMOTEUSER%@%IPADDRESS% mkdir web_html/data/%timestamp%

:: send over source and config
echo Sending files to target.
scp ./source.tar.gz %REMOTEUSER%@%IPADDRESS%:web_html/data/%timestamp%/source.tar.gz && echo Done.^
 || goto ERROR
echo --------------------------------

::::::::

:: execute the code on the server, relies on serverside build instructions

if %DETACH% == true (
    ssh %REMOTEUSER%@%IPADDRESS% delegate-build --ts=%timestamp%
	echo Check the website https://%IPADDRESS%/~%REMOTEUSER% for progress.
	echo Program ID is %timestamp%.
	goto CLEANUP
)

:: else
ssh %REMOTEUSER%@%IPADDRESS% delegate-build --local --ts=%timestamp%
goto CLEANUP

:ERROR
echo Something went wrong! Is the vpn running?

:: local garbage collection
:CLEANUP
DEL source.tar.gz
DEL config.cfg


pause

ECHO.

goto :EOF


::::::::::::::::::::::::::::::::


:: Subroutine that emulates Bash's select
:select returnVar in directory

setlocal EnableDelayedExpansion

echo Enter the number of the file you want to select:

:: Show the files and create an array with them
set n=0
for %%a in (%3) do (
   set /A n+=1
   set file[!n!]=%%a
   echo !n!^) %%a
)

:: Get the number of the desired file
:getNumber
set /P "number=#? "
if not defined file[%number%] goto getNumber

:: Return selected file to caller
for /F "delims=" %%a in ("!file[%number%]!") do endlocal & set "%1=%%a" & exit /B %number%



