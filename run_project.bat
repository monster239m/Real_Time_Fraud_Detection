@echo off
REM ============================================================
REM  run_project.bat  –  One-click runner for the SQL project
REM  Usage: Double-click this file OR run from terminal
REM  Make sure MySQL is in PATH or edit MYSQL_PATH below
REM ============================================================

SET MYSQL_PATH=C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe
SET /P MYSQL_USER="Enter MySQL username (default: root): "
IF "%MYSQL_USER%"=="" SET MYSQL_USER=root
SET /P MYSQL_PASS="Enter MySQL password: "

echo.
echo [1/4] Creating schema...
"%MYSQL_PATH%" -u%MYSQL_USER% -p%MYSQL_PASS% < 01_schema.sql
echo Done.

echo.
echo [2/4] Inserting sample data...
"%MYSQL_PATH%" -u%MYSQL_USER% -p%MYSQL_PASS% < 02_sample_data.sql
echo Done.

echo.
echo [3/4] Creating stored procedure and trigger...
"%MYSQL_PATH%" -u%MYSQL_USER% -p%MYSQL_PASS% < 03_stored_procedure_trigger.sql
echo Done.

echo.
echo [4/4] Running all queries...
"%MYSQL_PATH%" -u%MYSQL_USER% -p%MYSQL_PASS% < 04_queries.sql
echo Done.

echo.
echo ============================================================
echo  Project setup complete! Open MySQL Workbench or CLI to
echo  explore the fraud_detection database.
echo ============================================================
pause
