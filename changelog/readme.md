## Change Log

**Version 1.7 - November 28, 2017**
* Each test runs in its own datasession for optimium encapsulation and reproducability
* Added a [Compare](FoxUnit_CompareButton.md) feature to make analyzing larger results easier

**Version 1.61 - September 15, 2017**
Undeleted a class in the Class Factory Base table that was causing FoxUnit to fail on startup
Fixed a bug that prevented tests from reloading after editing.

**Version 1.6 - September 20, 2016**
* Replaced graphics with icons from Visual Studio Graphics Library
* Grouped icons into a more logical arrangement, with group titles
* Added the ability to create a test class with unimplemented tests from all methods in a class library
* Allow custom colors for pass/fail
* Hide the filter panel unless Filter toggle is switched on

![](FoxUnit_Changes_FoxUnitIcons.png)


**Version 1.51 - July 29, 2015**
* Refactored many forms to be subclasses of new fxuFrmUser, which holds the ioFxuInstance object and the SettingsSave() and SettingsRestore() functions.
* Removed check whether tests are in path
* Added more unit tests for the forms in fxu_fxuFrmUserTests.prg
* Misc U/I Cleanup
* Switched to FoxBin2Prg for SCM

**Version 1.5 - July 13, 2015**
* Introduced new class fxu.fxuInstance
* Removed fxuShowForm.prg
* Removed fxuNewObject.prg
(See full list of changes here - [FoxUnit 1.5 Full Changes](FoxUnit-1.5-Full-Changes.md))

**Version 1.42**
* Added option to retain visual results of previous tests between each run.

**Version 1.41 - November 11, 2014**
* Added a new assertion, AssertNotImplemented()
* Made that the default function call on new tests
* Changed name of new tests to testNewTest to conform with standard of test names beginning with 'test'
* The problem was that if a new test was added but no test code was written, that test would PASS. This is wrong. Now the new test will fail with a message of "Not Implemented Yet" to indicate to the developer that the test has yet to be written.

![](FoxUnit_Changes_FoxUnit-1.41-Change.png)

![](FoxUnit_Changes_FoxUnit-1.41-NewTestFails.png)


**Version 1.4 - August 1, 2014**
* Added a filter to only show failed tests
* Promoted the "Options" button to the main screen

![](FoxUnit_Changes_Changes1.png)

* Added an About tab to the Options form for easy access to the license, getting started, acknowledgments, and version history.

![](FoxUnit_Changes_Foxunit_Options.png)

* Reworked the New Test Class form (and underlying classes) for clarity

![](FoxUnit_Changes_FoxUnit_NewTestClass.png)



**Version 1.3 - July 29, 2014**
Burkhard Stiller Added these assertions:
* AssertEqualsArrays
* AssertEqualsObjects
* AssertEqualsValues
* AssertHasError
* AssertHasErrorNo
* AssertIsObject

[Eric Selje](https://github.com/ESelje) added the unit tests he uses to confirm FoxUnit hasn't broken.

**Version 1.21 - July 11, 2014**
Doug Meerschaert found a bug that caused AssertEquals to ignore the NonCaseSensitive flag. (work item 34625)

**Version 1.2 - July 9, 2014**
[Fernando Bozzo](https://github.com/fdbozzo/) introduced the following changes:

* In FXU main window, the font of editboxes was changed to Courier New to enhance output of tabular data
* Solved some historical problems with data path (or I think so, reading the comments on the code)
* Configured Anchor of textboxes used for search (conditioned for version(5) >= 900)
* Added the possibility of running FoxUnit from a CI server like CruiseControl, using this DOS syntax: <path>\foxunit.app createFxuResultsAddAllTestsAndRun
* Closed various ENDPROC/ENDFUNC
* Text logs converted using STRCONV(Logtext,9) for special characters support (Spanish, German, etc)
* Expanded the default size of the test-cases loading form because they were too small for large test names when using BDD-style naming (verbose names that describe the tests)
* Expanded the default size of the FoxUnit main window considering a minimal conservative setup of 800x600
* Expanded TClass C(80) to C(110) ==> So the Unit Test file name can be 'ut_libraryName__className__methodName.prg'
* Expanded TName C(100) to C(130) ==> So the method name can be 'SHOULD_DoSomething__WHEN_SomeConditions'
* Fxu.prg => Added AlwaysOnTop and Zoom Max when executed from CI Server (createFxuResultsAddAllTestsAndRun procedure)
* fxuresultdata.prg => Bug Fix: Found a very old bug that throws an error sometimes when filtering tests on main window and adding a new test
* All changes are backward compatible


**Version 1.11 - Nov 2013**
[Matt Slay](https://github.com/mattslay) introduced a splitter bar (using the SFSplitter Class Library) to separate the tests from the results.

**Version 1.1 - Sept 2012**
First version in VFPX. Uses changes by H. Alan Stevens which standardizes the parameter order for Assert calls.
