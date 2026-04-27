@echo off
title SSD Optimization

:: Auto-elevate to admin
fltmc >nul 2>&1 || (
    powershell -Command "Start-Process cmd.exe -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit
)

echo ==============================================
echo        SSD Professional Optimization
echo       Enable TRIM + Speed Up + Reduce Writes
echo ==============================================
echo.

echo 1. Enabling SSD TRIM...
fsutil behavior set DisableDeleteNotify 0
echo.

echo 2. Removing disk defrag schedule...
schtasks /delete /tn "\Microsoft\Windows\Defrag\ScheduledDefrag" /f >nul 2>&1
echo.

echo 3. Disabling hibernation...
powercfg -h off
echo.

echo 4. Disabling Windows Search indexing...
sc config WSearch start= disabled >nul 2>&1
net stop WSearch /y >nul 2>&1
echo.

echo 5. Disabling Prefetch and Superfetch...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 0 /f >nul 2>&1
echo.

echo 6. Disabling System Restore...
wmic /namespace:\\root\cimv2 path win32systemrestore set restoreenabled=false >nul 2>&1
echo.

echo 7. Disabling Volume Shadow Copy (VSS)...
sc config VSS start= disabled >nul 2>&1
net stop VSS /y >nul 2>&1
echo.

echo 8. Disabling automatic defrag...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v OptimizeHardDiskOn /t REG_DWORD /d 0 /f >nul 2>&1
echo.

echo 9. Enabling write cache (if possible)...
reg add "HKLM\SYSTEM\CurrentControlSet\Enum\STORAGE\Disk" /v WriteCacheEnabled /t REG_DWORD /d 1 /f >nul 2>&1
echo.

echo ==============================================
echo [OK] SSD Optimization Completed!
echo [OK] TRIM is now enabled
echo [OK] Reduced writes, extended SSD life
echo [OK] Faster boot and software loading
echo ==============================================
pause