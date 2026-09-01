@echo off
rem ============================================
rem  Saber ERP - تشغيل بطباعة فورية بدون نوافذ
rem  ⚠️ عدّلي السطر تحت لكل زبون: حطي رابطه الخاص (يلي فيه ?r=كود_المطعم) بدل العنوان
rem  مثال: https://username.github.io/repo-name/?r=almadina
rem ============================================
set URL=https://ضيفي-رابط-المطعم-هون؟r=كود_المطعم
start "" chrome --kiosk-printing --app=%URL%
if errorlevel 1 start "" "%ProgramFiles%\Google\Chrome\Application\chrome.exe" --kiosk-printing --app=%URL%
