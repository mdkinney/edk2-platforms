@REM @file
@REM   Windows batch file to build BIOS ROM
@REM
@REM Copyright (c) 2006 - 2019, Intel Corporation. All rights reserved.<BR>
@REM SPDX-License-Identifier: BSD-2-Clause-Patent
@REM

@echo off
setlocal EnableDelayedExpansion EnableExtensions
echo.
echo %date%  %time%
echo.


::**********************************************************************
:: Initial Setup
::**********************************************************************
if %WORKSPACE:~-1%==\ set WORKSPACE=%WORKSPACE:~0,-1%
set /a build_threads=1
set "Build_Flags= "
set exitCode=0
set Arch=X64
set Source=0
set PLATFORM_NAME=Vlv2TbltDevicePkg

set CORE_PATH=%WORKSPACE%
if not exist %CORE_PATH%\edksetup.bat (
  if defined PACKAGES_PATH (
    for %%i IN (%PACKAGES_PATH%) DO (
      if exist %%~fi\edksetup.bat (
        set CORE_PATH=%%~fi
        goto CorePathFound
      )
    )
  ) else (
    echo.
    echo !!! ERROR !!! Cannot find edksetup.bat !!!
    echo.
    goto BldFail
  )
)
:CorePathFound

set PLATFORM_PACKAGE=%WORKSPACE%\%PLATFORM_NAME%
if not exist %PLATFORM_PACKAGE% (
  if defined PACKAGES_PATH (
    for %%i IN (%PACKAGES_PATH%) DO (
      if exist %%~fi\%PLATFORM_NAME% (
        set PLATFORM_PACKAGE=%%~fi\%PLATFORM_NAME%
        goto PlatformPackageFound
      )
    )
  ) else (
    echo.
    echo !!! ERROR !!! Cannot find %PLATFORM_NAME% !!!
    echo.
    goto BldFail
  )
)
:PlatformPackageFound

cd %CORE_PATH%

:: Clean up previous build files.
if exist %WORKSPACE%\edk2.log del %WORKSPACE%\edk2.log
if exist %WORKSPACE%\unitool.log del %WORKSPACE%\unitool.log
if exist %WORKSPACE%\Conf\target.txt del %WORKSPACE%\Conf\target.txt
if exist %WORKSPACE%\Conf\tools_def.txt del %WORKSPACE%\Conf\tools_def.txt
if exist %WORKSPACE%\Conf\build_rule.txt del %WORKSPACE%\Conf\build_rule.txt
if exist %WORKSPACE%\Conf\.cache rmdir /q/s %WORKSPACE%\Conf\.cache

:: Setup EDK environment. Edksetup puts new copies of target.txt, tools_def.txt, build_rule.txt in WorkSpace\Conf
:: Also run edksetup as soon as possible to avoid it from changing environment variables we're overriding
call %CORE_PATH%\edksetup.bat Rebuild
@echo off

:: Define platform specific environment variables.
set config_file=%PLATFORM_PACKAGE%\PlatformPkgConfig.dsc
set auto_config_inc=%PLATFORM_PACKAGE%\AutoPlatformCFG.txt



::create new AutoPlatformCFG.txt file
copy /y nul %auto_config_inc% >nul

::**********************************************************************
:: Parse command line arguments
::**********************************************************************

:: Optional arguments
:OptLoop
if /i "%~1"=="/?" goto Usage

if /i "%~1"=="/l" (
    set Build_Flags=%Build_Flags% -j EDK2.log
    shift
    goto OptLoop
)
if /i "%~1"=="/y" (
    set Build_Flags=%Build_Flags% -y %PLATFORM_PACKAGE%\EDK2_%PLATFORM_PACKAGE%.report
    shift
    goto OptLoop
)
if /i "%~1"=="/m" (
    if defined NUMBER_OF_PROCESSORS (
        set /a build_threads=%NUMBER_OF_PROCESSORS%+1
    )
    shift
    goto OptLoop
)
if /i "%~1" == "/c" (
    echo Removing previous build files ...
    if exist build (
        del /f/s/q build > nul
        rmdir /s/q build
    )
    if exist %WORKSPACE%\Conf\.cache (
        del /f/s/q %WORKSPACE%\Conf\.cache > nul
        rmdir /s/q %WORKSPACE%\Conf\.cache
    )
    echo.
    shift
    goto OptLoop
)

if /i "%~1"=="/x64" (
    set Arch=X64
    shift
    goto OptLoop
)
if /i "%~1"=="/IA32" (
    set Arch=IA32
    shift
    goto OptLoop
)

:: Required argument(s)
if "%~1"=="" goto Usage

if "%Arch%"=="IA32" (
    echo DEFINE X64_CONFIG = FALSE  >> %auto_config_inc%
) else if "%Arch%"=="X64" (
    echo DEFINE X64_CONFIG = TRUE  >> %auto_config_inc%
)

:: -- Build flags settings for each Platform --
echo Setting  %1  platform configuration...
if /i "%~1" == "MNW2" (
    echo DEFINE ENBDT_PF_BUILD = TRUE   >> %auto_config_inc%
    
) else (
    echo Error - Unsupported PlatformType: %1
    goto Usage
)
set Platform_Type=%~1

if /i "%~2" == "RELEASE" (
    set target=RELEASE
) else (
    set target=DEBUG
)

::**********************************************************************
:: Additional EDK Build Setup/Configuration
::**********************************************************************
echo.
echo Setting the Build environment for VS2015/VS2013/VS2012/VS2010/VS2008...
if defined VS140COMNTOOLS (
  if not defined VSINSTALLDIR call "%VS140COMNTOOLS%\vsvars32.bat"
  if /I "%VS140COMNTOOLS%" == "C:\Program Files\Microsoft Visual Studio 14.0\Common7\Tools\" (
    set TOOL_CHAIN_TAG=VS2015
  ) else (
    set TOOL_CHAIN_TAG=VS2015x86
  ) 
) else if defined VS120COMNTOOLS (
  if not defined VSINSTALLDIR call "%VS120COMNTOOLS%\vsvars32.bat"
  if /I "%VS120COMNTOOLS%" == "C:\Program Files\Microsoft Visual Studio 12.0\Common7\Tools\" (
    set TOOL_CHAIN_TAG=VS2013
  ) else (
    set TOOL_CHAIN_TAG=VS2013x86
  )
) else if defined VS110COMNTOOLS (
  if not defined VSINSTALLDIR call "%VS110COMNTOOLS%\vsvars32.bat"
  if /I "%VS110COMNTOOLS%" == "C:\Program Files\Microsoft Visual Studio 11.0\Common7\Tools\" (
    set TOOL_CHAIN_TAG=VS2012
  ) else (
    set TOOL_CHAIN_TAG=VS2012x86
  )
) else if defined VS100COMNTOOLS (
  if not defined VSINSTALLDIR call "%VS100COMNTOOLS%\vsvars32.bat"
  if /I "%VS100COMNTOOLS%" == "C:\Program Files\Microsoft Visual Studio 10.0\Common7\Tools\" (
    set TOOL_CHAIN_TAG=VS2010
  ) else (
    set TOOL_CHAIN_TAG=VS2010x86
  )
) else if defined VS90COMNTOOLS (
  if not defined VSINSTALLDIR call "%VS90COMNTOOLS%\vsvars32.bat"
  if /I "%VS90COMNTOOLS%" == "C:\Program Files\Microsoft Visual Studio 9.0\Common7\Tools\" (
     set TOOL_CHAIN_TAG=VS2008
  ) else (
     set TOOL_CHAIN_TAG=VS2008x86
  )
) else (
  echo  --ERROR: VS2015/VS2013/VS2012/VS2010/VS2008 not installed correctly. VS140COMNTOOLS/VS120COMNTOOLS/VS110COMNTOOLS/VS100COMNTOOLS/VS90COMNTOOLS not defined ^^!
  echo.
  goto :BldFail
)

echo Ensuring correct build directory is present
if not exist %WORKSPACE%\Build mkdir %WORKSPACE%\Build
if "%Arch%"=="IA32" (
  if not exist %WORKSPACE%\Build\%PLATFORM_NAME%IA32 mkdir %WORKSPACE%\Build\%PLATFORM_NAME%IA32
  set BUILD_PATH=%WORKSPACE%\Build\%PLATFORM_NAME%IA32\%TARGET%_%TOOL_CHAIN_TAG%
) else (
  if not exist %WORKSPACE%\Build\%PLATFORM_NAME% mkdir %WORKSPACE%\Build\%PLATFORM_NAME%
  set BUILD_PATH=%WORKSPACE%\Build\%PLATFORM_NAME%\%TARGET%_%TOOL_CHAIN_TAG%
)
if not exist %BUILD_PATH% mkdir %BUILD_PATH%

echo Modifing Conf files for this build...
:: Remove lines with these tags from target.txt
findstr /V "TARGET  TARGET_ARCH  TOOL_CHAIN_TAG  BUILD_RULE_CONF  ACTIVE_PLATFORM  MAX_CONCURRENT_THREAD_NUMBER" %WORKSPACE%\Conf\target.txt > %WORKSPACE%\Conf\target.txt.tmp

echo TARGET          = %TARGET%                                  >> %WORKSPACE%\Conf\target.txt.tmp
if "%Arch%"=="IA32" (
    echo TARGET_ARCH = IA32                                       >> %WORKSPACE%\Conf\target.txt.tmp
) else if "%Arch%"=="X64" (
    echo TARGET_ARCH = IA32 X64                                  >> %WORKSPACE%\Conf\target.txt.tmp
)
echo TOOL_CHAIN_TAG  = %TOOL_CHAIN_TAG%                                  >> %WORKSPACE%\Conf\target.txt.tmp
echo BUILD_RULE_CONF = Conf/build_rule.txt                               >> %WORKSPACE%\Conf\target.txt.tmp
if %Source% == 0 (
  echo ACTIVE_PLATFORM = %PLATFORM_PACKAGE%/PlatformPkg%Arch%.dsc        >> %WORKSPACE%\Conf\target.txt.tmp
) else (
  echo ACTIVE_PLATFORM = %PLATFORM_PACKAGE%/PlatformPkg%Arch%Source.dsc  >> %WORKSPACE%\Conf\target.txt.tmp
)
echo MAX_CONCURRENT_THREAD_NUMBER = %build_threads%                      >> %WORKSPACE%\Conf\target.txt.tmp

move /Y %WORKSPACE%\Conf\target.txt.tmp %WORKSPACE%\Conf\target.txt >nul

::**********************************************************************
:: Generate BIOS ID
::**********************************************************************

echo BOARD_ID       = MNW2MAX >  %BUILD_PATH%/BiosId.env
echo BOARD_REV      = 1       >> %BUILD_PATH%/BiosId.env
if "%Arch%"=="IA32" (
  echo BOARD_EXT      = I32   >> %BUILD_PATH%/BiosId.env
)
if "%Arch%"=="X64" (
  echo BOARD_EXT      = X64   >> %BUILD_PATH%/BiosId.env
)
echo VERSION_MAJOR  = 0090    >> %BUILD_PATH%/BiosId.env
if "%TARGET%"=="DEBUG" (
  echo BUILD_TYPE     = D     >> %BUILD_PATH%/BiosId.env
)
if "%TARGET%"=="RELEASE" (
  echo BUILD_TYPE     = R     >> %BUILD_PATH%/BiosId.env
)
echo VERSION_MINOR  = 01      >> %BUILD_PATH%/BiosId.env

%WORKSPACE%\edk2-platforms\Platform\Intel\Tools\GenBiosId\GenBiosId.py -i %BUILD_PATH%/BiosId.env -o %BUILD_PATH%/BiosId.bin -ot %BUILD_PATH%/BiosId.txt

::**********************************************************************
:: Build BIOS
::**********************************************************************

echo.
echo Invoking EDK2 build...
call build %Build_Flags%

if %ERRORLEVEL% NEQ 0 goto BldFail

::**********************************************************************
:: Post Build processing and cleanup
::**********************************************************************

echo Running fce...

pushd %PLATFORM_PACKAGE%
:: Extract Hii data from build and store in HiiDefaultData.txt
%PLATFORM_PACKAGE%\fce read -i %BUILD_PATH%\FV\Vlv.fd > %BUILD_PATH%\FV\HiiDefaultData.txt

:: save changes to VlvXXX.fd
%PLATFORM_PACKAGE%\fce update -i %BUILD_PATH%\FV\Vlv.fd -s %BUILD_PATH%\FV\HiiDefaultData.txt -o %BUILD_PATH%\FV\Vlv.ROM
popd

if %ERRORLEVEL% NEQ 0 goto BldFail
::echo FD successfully updated with default Hii values.

@REM build capsule here
call build -p %PLATFORM_PACKAGE%\PlatformCapsule.dsc

goto Exit

:Usage
echo.
echo ***************************************************************************
echo Build BIOS rom for VLV platforms.
echo.
echo Usage: bld_vlv.bat [options] PlatformType [Build Target]
echo.
echo    /c    CleanAll before building
echo    /l    Generate build log file
echo    /y    Generate build report file
echo    /m    Enable multi-processor build
echo    /IA32 Set Arch to IA32 (default: X64)
echo    /X64  Set Arch to X64 (default: X64)
echo.
echo        Platform Types:  MNW2
echo        Build Targets:   Debug, Release  (default: Debug)
echo.
echo Examples:
echo    bld_vlv.bat MNW2                 : X64 Debug build for MinnowMax
echo    bld_vlv.bat /IA32 MNW2 release   : IA32 Release build for MinnowMax
echo.
echo ***************************************************************************
set exitCode=1
goto Exit

:BldFail
set exitCode=1
echo  -- Error:  EDKII BIOS Build has failed!
echo See EDK2.log for more details

:Exit
echo %date%  %time%
exit /b %exitCode%

EndLocal
