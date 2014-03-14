@echo off
SETLOCAL
set _Version=3.8.4.1
mkdir SQLite\%_Version%\ 2>nul
echo. 2> SQLite\%_Version%\bootstrapper
copy scripts\Install.ps1 SQLite\%_Version% 1>nul
