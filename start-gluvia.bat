@echo off
setlocal enabledelayedexpansion
title Gluvia Application Launcher
echo =================================
echo    Starting Gluvia Application
echo =================================

REM Check if conda is available
where conda >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Conda is not available. Please install Anaconda or Miniconda first.
    echo Download from: https://docs.conda.io/en/latest/miniconda.html
    pause
    exit /b 1
)

echo [OK] Conda is available

REM Check if Gluvia-web environment exists
call conda env list | findstr "Gluvia-web" >nul
if %ERRORLEVEL% NEQ 0 (
    echo [INFO] Conda environment 'Gluvia-web' not found. Creating it...
    call conda create -n Gluvia-web python=3.11 -y
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to create conda environment 'Gluvia-web'
        pause
        exit /b 1
    )
    echo [OK] Conda environment 'Gluvia-web' created successfully
) else (
    echo [OK] Conda environment 'Gluvia-web' is available
)

REM Check if ports are available
netstat -an | findstr ":8000" >nul
if %ERRORLEVEL% EQU 0 (
    echo [ERROR] Port 8000 is already in use. Please stop the service using that port first.
    pause
    exit /b 1
)

netstat -an | findstr ":3000" >nul
if %ERRORLEVEL% EQU 0 (
    echo [ERROR] Port 3000 is already in use. Please stop the service using that port first.
    pause
    exit /b 1
)

echo [OK] Ports 8000 and 3000 are available

REM Navigate to backend directory
cd /d "C:\Users\srija\PycharmProjects\Gluvia-webcd\Gluvia-backend"

echo.
echo Starting Gluvia Backend...
echo.

REM Start backend in a new window with conda environment
start "Gluvia Backend" cmd /k "call conda activate Gluvia-web && pip install -r requirements.txt && uvicorn main:app --host 0.0.0.0 --port 8000 --reload"

REM Wait for backend to start
echo Waiting for backend to start...
timeout /t 10 /nobreak >nul

REM Check if backend is running
for /l %%i in (1,1,15) do (
    curl -s http://localhost:8000/ >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        echo [OK] Backend is running at http://localhost:8000
        goto backend_ready
    )
    echo Attempt %%i/15: Backend not ready yet...
    timeout /t 2 /nobreak >nul
)

echo [ERROR] Backend failed to start properly
pause
exit /b 1

:backend_ready

REM Navigate to frontend directory (FIXED: Changed from GLUVIA to Gluvia-2)
cd /d "C:\Users\srija\PycharmProjects\Gluvia-web\Gluvia-2"

echo.
echo Starting Gluvia Frontend...
echo.

REM Start frontend in a new window
start "Gluvia Frontend" cmd /k "python -m http.server 3000"

REM Wait for frontend to start
timeout /t 5 /nobreak >nul

REM Check if frontend is running
for /l %%i in (1,1,8) do (
    curl -s http://localhost:3000/ >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        echo [OK] Frontend is running at http://localhost:3000
        goto frontend_ready
    )
    echo Attempt %%i/8: Frontend not ready yet...
    timeout /t 2 /nobreak >nul
)

echo [WARNING] Frontend may not have started properly

:frontend_ready

echo.
echo =======================================
echo   Gluvia Application Started Successfully!
echo =======================================
echo.
echo Backend API:      http://localhost:8000
echo Frontend UI:      http://localhost:3000
echo API Docs:         http://localhost:8000/docs
echo Conda Environment: Gluvia-web
echo.
echo Press any key to close this launcher...
echo (Backend and Frontend will continue running in separate windows)
pause >nul
