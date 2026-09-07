@echo off
:: Check for Admin permissions
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ========================================================
echo  Fixing ReviewsGateway Domain Resolution to New VPS
echo ========================================================
echo.

:: 1. Update Windows Hosts file so reviewsgateway.in ALWAYS opens VPS (65.20.77.112)
set HOSTS=%WINDIR%\System32\drivers\etc\hosts

:: Remove any existing entries for reviewsgateway
powershell -Command "(Get-Content '%HOSTS%') | Where-Object { $_ -notmatch 'reviewsgateway\.in' } | Set-Content '%HOSTS%'"

:: Append new clean mapping
echo 65.20.77.112 reviewsgateway.in www.reviewsgateway.in >> "%HOSTS%"
echo [OK] Hosts file updated: 65.20.77.112 reviewsgateway.in www.reviewsgateway.in

:: 2. Set Wi-Fi DNS to Google DNS (8.8.8.8, 1.1.1.1) to bypass slow ISP/Router DNS cache
powershell -Command "Set-DnsClientServerAddress -InterfaceAlias 'Wi-Fi' -ServerAddresses ('8.8.8.8','1.1.1.1') -ErrorAction SilentlyContinue"
echo [OK] Wi-Fi DNS set to Google DNS (8.8.8.8 / 1.1.1.1)

:: 3. Flush DNS resolver cache
ipconfig /flushdns
echo [OK] DNS Cache Flushed.

echo.
echo ========================================================
echo  DONE! Now reviewsgateway.in will open your NEW VPS site!
echo ========================================================
echo.
pause
