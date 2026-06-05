@echo off
echo Starting İTÜpoly web server on port 8080...
cd /d "%~dp0"
:: Automatically open http://localhost:8080 in your default browser after 2 seconds
start /b cmd /c "timeout /t 2 >nul && start http://localhost:8080"
python -m http.server 8080 --directory build/web
pause
