# FoxUnit Folders

The folder hierarchy used with the FoxUnit project consists of five directories:

`.\Documentation` contains text files providing general information about the FoxUnit project as well as license and developer information.

`.\Graphics` is the home of all picture and icon files used throughout the FoxUnit project - no screen shots or other documentation files.

`.\Source` is used for the FoxUnit source code files of any kind.

`.\Text` contains resource files like the two built in test case templates.

`.\Tests` provides a place to store tests - the tests delivered with FoxUnit can be found here right from the beginning.

All files located in these subdirectories get included in the FoxUnit application file on build. If you want to deploy FoxUnit to a developer team, you just need to provide the FoxUnit application file and the class factory base table (see below). You can also deploy FoxUnit using an SCC system because both of these needed files don't have to be writable.

## The FoxUnit Path

The term FoxUnit Path refers to either the home directory of the FoxUnit project or the directory containing the FoxUnit application file (e.g. FoxUnit.app), depending on how FoxUnit was started. If FoxUnit was run by executing FXU.PRG, the FoxUnit Path is the path to FoxUnit.pjx. If FoxUnit was started as a compiled binary file (e.g. FoxUnit.app), the FoxUnit path is the directory containing that file. According to the recommendations mentioned in the readme file, the FoxUnit Path must be configured in the Visual FoxPro search path. Therefore, the FoxUnit Path should be the first choice to store reusable test case classes as well as their corresponding template files.

## The FoxUnit Data Path

This is where test results and FoxUnit settings are stored. The FoxUnit Data Path always points to a directory named Tests, but is project specific. If there's a project available, the FoxUnit Data Path is the subfolder Tests of the project home directory. If no Project is available, the FoxUnit Data Path is the subfolder Tests of the current directory.

## `FxuClassFactoryBase.dbf`

The class factory base table

This file is vital to the class factory of FoxUnit. It must reside in the FoxUnit Path. It doesn't need to be writable. If it is missing or corrupt, FoxUnit won't be able to start at all.

## `FxuClassFactory.dbf`

The class factory table

The second file the FoxUnit class factory works with. This table is also located in the FoxUnit Path, but is created automatically if it doesn't exist. 

## `FXURresults.dbf`

FoxUnit results

Test results are stored in these table files. Because test results are project specific in most cases, the test result files are stored in the FoxUnit Data Path.

## `FXUPersist*.xml`

FoxUnit settings files

Several forms used in FoxUnit persist their settings in this sort of file. All settings are saved per user and the files are stored in the FoxUnit Data Path, so actually all settings are maintained per user and per project. Because of their volatile nature, these files are also not deployed in FoxUnit download packages.
