call .\solutionEnvironment.bat
set LLDB_LIBRARY=%SWIFT_TOOLCHAIN%\\usr\\bin\\liblldb.dll

(
    echo {
    echo "lldb.library" : "%LLDB_LIBRARY%"
    echo }
) > .\.vscode\settings.json