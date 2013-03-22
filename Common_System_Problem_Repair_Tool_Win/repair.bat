@echo off

REM clear the temp folder
del /q /f /s %temp%\*

REM this will reset the print spooler
net stop spooler
del /F /Q %systemroot%\System32\spool\PRINTERS\*
net start spooler

REM delete prefetch files
del /q /f /s %systemroot%\prefetch\*


