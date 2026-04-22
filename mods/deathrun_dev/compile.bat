@echo off
echo Starting Mod Build Process...

:: Runs the mod compiler script
call makeMod.bat

echo.
echo Mod compilation finished. Starting IWD packaging...
echo.

:: Runs the IWD packaging script
call makeIWD.bat

echo.
echo Full build process complete!
pause