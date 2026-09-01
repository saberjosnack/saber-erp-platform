@echo off
title Saber ERP Print Agent
rem ============================================
rem  وكيل طباعة Saber ERP — شغّله وخليه فاتح بالخلفية
rem  (حط اختصار له بمجلد Startup ليشتغل تلقائيًا مع الويندوز)
rem ============================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Saber-ERP-Print-Agent.ps1"
pause
