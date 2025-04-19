setlocal ENABLEDELAYEDEXPANSION

call .\writeSettingsJSON.bat


echo "%VSCODE%"
echo "%SWIFT_TOOLCHAIN%"

call "%VSCODE%" .

endlocal