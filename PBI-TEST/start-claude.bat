@echo off
cd /d "%~dp0PBI-TEST\Claude-Work\Project"

if not exist "test_sales.pbip" (
    echo ERROR: Approved Power BI project folder not found.
    pause
    exit /b 1
)

claude