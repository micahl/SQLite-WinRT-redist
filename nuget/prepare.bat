@echo off
mkdir SQLite\3.8.3.1\debug\x64 2>nul
mkdir SQLite\3.8.3.1\debug\x86 2>nul
mkdir SQLite\3.8.3.1\debug\ARM 2>nul
mkdir SQLite\3.8.3.1\release\x64 2>nul
mkdir SQLite\3.8.3.1\release\x86 2>nul
mkdir SQLite\3.8.3.1\release\ARM 2>nul
echo. 2> SQLite\3.8.3.1\bootstrapper
copy scripts\Install.ps1 SQLite\3.8.3.1 1>nul
copy targets\SQLite-WinRT-redist.targets SQLite\3.8.3.1 1>nul
copy "%ProgramFiles(x86)%\Microsoft SDKs\Windows\v8.1\ExtensionSDKs\SQLite.WinRT81\3.8.3.1\Redist\Debug\x86\*" SQLite\3.8.3.1\debug\x86 1>nul
copy "%ProgramFiles(x86)%\Microsoft SDKs\Windows\v8.1\ExtensionSDKs\SQLite.WinRT81\3.8.3.1\Redist\Debug\x64\*" SQLite\3.8.3.1\debug\x64 1>nul
copy "%ProgramFiles(x86)%\Microsoft SDKs\Windows\v8.1\ExtensionSDKs\SQLite.WinRT81\3.8.3.1\Redist\Debug\ARM\*" SQLite\3.8.3.1\debug\ARM 1>nul
copy "%ProgramFiles(x86)%\Microsoft SDKs\Windows\v8.1\ExtensionSDKs\SQLite.WinRT81\3.8.3.1\Redist\Retail\x86\*" SQLite\3.8.3.1\release\x86 1>nul
copy "%ProgramFiles(x86)%\Microsoft SDKs\Windows\v8.1\ExtensionSDKs\SQLite.WinRT81\3.8.3.1\Redist\Retail\x64\*" SQLite\3.8.3.1\release\x64 1>nul
copy "%ProgramFiles(x86)%\Microsoft SDKs\Windows\v8.1\ExtensionSDKs\SQLite.WinRT81\3.8.3.1\Redist\Retail\ARM\*" SQLite\3.8.3.1\release\ARM 1>nul
