@echo off
echo Rebuilding İTÜpoly Flutter Web Application...
cd /d "%~dp0"
call "C:\Users\PC_4719\flutter\bin\flutter.bat" build web
if %ERRORLEVEL% neq 0 (
    echo Build failed!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Starting İTÜpoly web server on port 8080...
:: Automatically open http://localhost:8080 in your default browser after 2 seconds
start /b cmd /c "timeout /t 2 >nul && start http://localhost:8080"
python -m http.server 8080 --directory build/web
pause
