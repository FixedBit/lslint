@echo off
rem :: Check for Visual Studio 2022

reg query "HKEY_CLASSES_ROOT\VisualStudio.DTE.17.0" >> nul 2>&1
if not errorlevel 1 (
    rem :: VS2017
    rem :: NOTE: The instructions contained in the NMakefile are no longer necessary with this method.
    pushd "C:\Program Files\Microsoft Visual Studio\2022\Community\"
    call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
    popd
) else (
    echo "You do not appear to have Visual Studio 2022 (x64) Installed"
    exit /b 1
)

if not exist C:\flexandbison\ ( echo "You need to have the Flex and Bison Packages, please see documentation." && exit /b 1 )

set PATH=%PATH%;C:\flexandbison
nmake /F NMakefile
mkdir binary\windows64\ >> nul 2>&1
move lslint.exe binary\windows64\
nmake /F NMakefile clean
