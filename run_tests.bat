@echo off
echo Running İTÜpoly Engine tests...
cd /d "%~dp0\packages\itupoly_engine"
call "C:\Users\PC_4719\flutter\bin\dart.bat" test
if %ERRORLEVEL% neq 0 (
    echo Engine tests failed!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Running İTÜpoly Flutter Presentation/Widget tests...
cd /d "%~dp0"
call "C:\Users\PC_4719\flutter\bin\flutter.bat" test
if %ERRORLEVEL% neq 0 (
    echo Flutter widget tests failed!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo All tests passed successfully!
pause
