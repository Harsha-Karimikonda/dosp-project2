@echo off
set SCRIPT_DIR=%~dp0
erl -noshell -pa "%SCRIPT_DIR%ebin" -s project2_bonus main %*

