:: Admin
:: @ECHO OFF
::PowerShell.exe -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dpn0.ps1""' -Verb RunAs}"

:: Non-Admin
:: This is for troubleshooting, leaves the child process open, unless you remove -NoExit
@ECHO OFF
PowerShell.exe -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoExit -NoProfile -ExecutionPolicy Bypass -File ""%~dpn0.ps1""'}"
