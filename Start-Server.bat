@echo off
title Diyarbakir Nöbetci Eczane Sunucusu
echo Sunucu baslatiliyor, lutfen bu pencereyi kapatmayin...
cd /d "%~dp0backend"
set COLLECT_API_KEY=apikey 1sANSGLTRRtz49AfxrWivW:0pgKHq7FGhmVKTE8QydFWa
npm start
pause
