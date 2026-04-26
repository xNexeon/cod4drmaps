@echo off
setlocal enabledelayedexpansion

set "SOURCE=C:\Users\Nex\Desktop\ogdr\mods"
set "DEST=C:\Program Files (x86)\Steam\steamapps\common\Call of Duty 4 WIP XXX\Mods"
set "MOD=deathrun_dev"

:: -----------------------------------------------
:: Build timestamp (YYYYMMDD_HHMMSS) - no spaces
:: -----------------------------------------------
set "D=%DATE%"
set "T=%TIME%"
set "YY=%D:~6,4%"
set "MM=%D:~3,2%"
set "DD=%D:~0,2%"
set "HH=%T:~0,2%"
set "MIN=%T:~3,2%"
set "SS=%T:~6,2%"
set "HH=%HH: =0%"
set "TIMESTAMP=%YY%%MM%%DD%_%HH%%MIN%%SS%"

:: No spaces in the backup folder name
set "OLD_LABEL=%MOD%_old_%TIMESTAMP%"

:: -----------------------------------------------
:: Step 1: Rename existing folders
:: -----------------------------------------------
echo Renaming existing source folder if it exists...
if exist "%SOURCE%\%MOD%" (
    rename "%SOURCE%\%MOD%" "%OLD_LABEL%"
    echo Renamed source to: %OLD_LABEL%
) else (
    echo No existing source folder found, skipping rename.
)

echo Renaming existing destination folder if it exists...
if exist "%DEST%\%MOD%" (
    rename "%DEST%\%MOD%" "%OLD_LABEL%"
    echo Renamed destination to: %OLD_LABEL%
) else (
    echo No existing destination folder found, skipping rename.
)

:: -----------------------------------------------
:: Step 2: Copy renamed source to destination
:: -----------------------------------------------
echo.
echo Copying %OLD_LABEL% from source to destination...
robocopy "%SOURCE%\%OLD_LABEL%" "%DEST%\%MOD%" /E /IS /IT
if errorlevel 8 (
    echo ERROR: Failed to copy mod to destination. Aborting.
    pause
    exit /b 1
)
echo Copy to destination complete.

:: -----------------------------------------------
:: Step 3: Run compile.bat
:: -----------------------------------------------
echo.
echo Running compile.bat...
pushd "%DEST%"
call compile.bat
if errorlevel 1 (
    echo ERROR: compile.bat failed. Aborting copy back.
    popd
    pause
    exit /b 1
)
popd
echo Compile complete.

:: -----------------------------------------------
:: Step 4: Copy compiled mod back to source
:: -----------------------------------------------
echo.
echo Copying compiled mod back to source...
robocopy "%DEST%\%MOD%" "%SOURCE%\%MOD%" /E /IS /IT
if errorlevel 8 (
    echo ERROR: Failed to copy compiled mod back to source.
    pause
    exit /b 1
)
echo Copy back to source complete.

echo.
echo -----------------------------------------------
echo Done! Old folders backed up as: %OLD_LABEL%
echo -----------------------------------------------
pause
