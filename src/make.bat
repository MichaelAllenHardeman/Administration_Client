@echo off
  rem ------------------------------------------------------------------------------------------------------------------
  rem --                                                                                                              --
  rem -- file:        make.bat                                                                                        --
  rem -- author:      Michael Hardeman                                                                                --
  rem -- language:    batch >:D                                                                                       --
  rem -- description: Builds the program. Read "How To Compile.txt"                                                   --
  rem --                                                                                                              --
  rem ------------------------------------------------------------------------------------------------------------------

  echo Starting Program...
  cd ..

  set begin=(
  set end=)
  set then=(
  set endif=)
  set else=) else (

  set ERROR_HEADER=!!! ERROR !!!
  set WARNING_HEADER=!!! WARNING !!!

  set ROOT_DIRECTORY=%CD%
  set BINARY_DIRECTORY=%ROOT_DIRECTORY%\bin
  set SOURCE_DIRECTORY=%ROOT_DIRECTORY%\src
  set INSTALLER_DIRECTORY=%SOURCE_DIRECTORY%\installer

  set LICENSES_FILE=%ROOT_DIRECTORY%\Licenses.txt
  set README_FILE=%ROOT_DIRECTORY%\Readme.txt

  set PROGRAM_MAIN=%SOURCE_DIRECTORY%\Administration_Client.adb
  set PROGRAM_OBJECT_DIRECTORY=%SOURCE_DIRECTORY%\Objects
  set PROGRAM_OUTPUT_FILE=%BINARY_DIRECTORY%\admin_client.exe

  set INSTALLER_OBJECT_DIRECTORY=%INSTALLER_DIRECTORY%\Objects
  set INSTALLER_SOURCE_FILE=%INSTALLER_DIRECTORY%\admin_client.wxs
  set INSTALLER_OBJECT_FILE=%INSTALLER_OBJECT_DIRECTORY%\admin_client.wixobj
  set INSTALLER_LINKER_FILE=%INSTALLER_DIRECTORY%\setup.msi

  set PROGRAM_COMPILER=gnatmake.exe
  set PROGRAM_OPTIONS=-gnatW8 -mwindows -D "%PROGRAM_OBJECT_DIRECTORY%"
  set PROGRAM_INPUT="%PROGRAM_MAIN%"
  set PROGRAM_OUTPUT=-o "%PROGRAM_OUTPUT_FILE%"

  set INSTALLER_COMPILER=candle.exe
  set INSTALLER_COMPILER_OPTIONS=
  set INSTALLER_COMPILER_INPUT="%INSTALLER_SOURCE_FILE%"
  set INSTALLER_COMPILER_OUTPUT=-o "%INSTALLER_OBJECT_FILE%"

  set INSTALLER_LINKER=light.exe
  set INSTALLER_LINKER_OPTIONS=-ext WixUIExtension -ext WixUtilExtension -b "%INSTALLER_DIRECTORY%"
  set INSTALLER_LINKER_INPUT="%INSTALLER_OBJECT_FILE%"
  set INSTALLER_LINKER_OUTPUT=-o "%INSTALLER_LINKER_FILE%"

  echo Checking File Structure...
  if not exist "%BINARY_DIRECTORY%" %then%
    echo %ERROR_HEADER%
    echo Binary Directory did not exist. Dependancies Putty.exe, Ping.bat, srvany.exe, and instsrv.exe missing.
    echo %BINARY_DIRECTORY%
    goto Exit
  %endif%
  if not exist "%LICENSES_FILE%" %then%
    echo %ERROR_HEADER%
    echo Licenses.txt file missing.
    echo %LICENSES_FILE%
    goto Exit
  %endif%
  if not exist "%README_FILE%" %then%
    echo %ERROR_HEADER%
    echo Readme.txt file missing.
    echo %README_FILE%
    goto Exit
  %endif%
  if not exist "%SOURCE_DIRECTORY%" %then%
    echo %ERROR_HEADER%
    echo Source Directory did not exist. Source files missing.
    echo %SOURCE_DIRECTORY%
    goto Exit
  %endif%
  if not exist "%INSTALLER_DIRECTORY%" %then%
    echo %ERROR_HEADER%
    echo Installer Directory did not exist. Installer script file missing.
    echo %INSTALLER_DIRECTORY%
    goto Exit
  %endif%
  if not exist "%PROGRAM_OBJECT_DIRECTORY%" %then%
    echo %WARNING_HEADER%
    echo Program Object Directory did not exist. If not first run, be careful.
    echo %PROGRAM_OBJECT_DIRECTORY%
    mkdir "%PROGRAM_OBJECT_DIRECTORY%"
  %endif%
  if not exist "%INSTALLER_OBJECT_DIRECTORY%" %then%
    echo %WARNING_HEADER%
    echo Installer Object Directory did not exist. If not first run, be careful.
    echo %INSTALLER_OBJECT_DIRECTORY%
    mkdir "%INSTALLER_OBJECT_DIRECTORY%"
  %endif%

  echo Removing Output Files...
  if exist "%PROGRAM_OUTPUT_FILE%" %then%
    del "%PROGRAM_OUTPUT_FILE%"
  %endif%
  if exist "%INSTALLER_OBJECT_FILE%" %then%
    del "%INSTALLER_OBJECT_FILE%"
  %endif%
  if exist "%INSTALLER_LINKER_FILE%" %then%
    del "%INSTALLER_LINKER_FILE%"
  %endif%

  echo Starting Compilation...
  if exist "%PROGRAM_MAIN%" %then%
    echo Compiling Source...
    start /wait %PROGRAM_COMPILER% %PROGRAM_OPTIONS% %PROGRAM_INPUT% %PROGRAM_OUTPUT%

    if exist "%PROGRAM_OUTPUT_FILE%" %then%
      echo Compiling Installer...
      start /wait %INSTALLER_COMPILER% %INSTALLER_COMPILER_OPTIONS% %INSTALLER_COMPILER_INPUT% %INSTALLER_COMPILER_OUTPUT%

      if exist "%INSTALLER_OBJECT_FILE%" %then%
        echo Linking Installer...
        start /wait %INSTALLER_LINKER% %INSTALLER_LINKER_OPTIONS% %INSTALLER_LINKER_INPUT% %INSTALLER_LINKER_OUTPUT%

        if exist "%INSTALLER_LINKER_FILE%" %then%
          echo Successful Compilation...
          goto Exit
        %else%
          echo %ERROR_HEADER%
          echo Installer Linker Failed.
          goto Exit
        %endif%

      %else%
        echo %ERROR_HEADER%
        echo Installer Compilation Failed.
        goto Exit
      %endif%

    %else%
      echo %ERROR_HEADER%
      echo Program Compilation Failed.
      goto Exit
    %endif%

  %else%
    echo %ERROR_HEADER%
    echo Main Source File Missing.
    goto Exit
  %endif%

  :Exit
    cd src
    echo Exiting Program...
    pause
