@echo off
if "%1"=="start" goto start
if "%1"=="build" goto build
if "%1"=="" goto help

:help
echo Usage: luax [command]
echo   build  - Build static site
echo   start  - Start HTTP server
echo   all    - Build + Start
goto end

:build
lua55 build.lua
goto end

:start
lua55 start.lua
goto end

:all
lua55 build.lua
lua55 start.lua
goto end

:end