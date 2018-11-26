# FoxUnit 1.5 Full Change Log

## FXU.PRG 

* Changed version information constant C_Version to reflect full minor version information (1.2 -> 1.5). 
* Added compiler info about files to require on build via EXTERNAL (still incomplete). 
* Reworked code and calls during interactive startup (e.g. eliminated calling GetFoxUnitForm() twice). 
* Made class fxu use FxUInstance and cleaned up commented code formerly calling function that now have disappeared. 
* Added function GetFoxUnitPath(). 
* Removed function ManageFxuClassFactory(). 
* Removed function CheckPath(). 
* Removed function GetTestsDir(). 
* Added function FXUShowForm() (taken from FXUShowForm.prg). 
* Made function createFxuResultsAddAllTestsAndRun() use FxuInstance fixed bug by introducing new variable lnTest to replace variable I in loops because it conflicted with variable having the same name in sub-calls. 

## FXUAssertions.prg 

* Made class FxuAssertions use FxuInstance. 
* Introduced new property ioFxuInstance. 
* Enforced passing an FxuInstance object to Init() which gets stored in ioFxuInstance. 

##  FXUNewObject.prg, FXUShowForm.prg 

* Removed / Excluded from project. 

##  FXUResultData.prg 

* Basically same as for FXUAssertions. 

##  FXUTestCase.prg 

* Basically same as for FXUAssertions. 
*  BugFix related to ilSuccess property. 

## FXUTestCaseEnumerator.prg 

* Basically same as for FXUAssertions. 

##  FXUTestResult.prg 

* BugFix related to ilCurrentResult property. 
 

##  FXUTestSuite.prg 

* Basically same as for FXUAssertions. 

## Fxu.vcx 

* Added class FxuInstance 
*  Class FrmFoxUnit 
	*  Made form use FxuInstance. 
	*  Introduced new property ioFxuInstance. 
	* Enforced passing an FxuTestBroker object to Init() which gets stored in ioTestBroker and whose FxuInstance object ioFxuInstance gets also stored in ioFxuInstance of FrmFoxUnit. 
	* Moved half of the code in Load() to Init() (relies on or can be optimized using FxuInstance which isn't yet available in Load() ). 
	* Experimental: Made DetailsZoom() open details in VFP-built-in memo edit window instead of frmShowInfo. Goal is to improve experience and save code. 
	* Made methods used with BINDEVENTS() use correct data session. 
	* Changed Picture properties of multiple controls to point to graphics files directly and therefore make compiler require those graphics files. 
	* Made Init() of some controls to wait until thisform.icgridrs gets valid (their Init()s are called before form's Init() but some stuff that has moved from Load() to Init() and so not everything is already available in control's Init()s). 
* Class FrmNewTestClass 
	* Made form use FxuInstance. 
	* Introduced new property ioFxuInstance. 
	* Enforced passing FxuInstance object to Init() which gets stored in ioFxuInstance. 
	* Moved all code away from Load(). 
	* Refactored SaveSettings() and RestoreSettings() methods, made them process user names containing up to 15 characters (instead of only 10 before) without losing existing settings stored in files. 
	* Changed code in txtTestClassName.Valid() event to only change enabled state of cmdCreate instead of forcing user to type some chars to be able to leave the field. 
* Class FxuFrmLoadClass 
	* Changed Picture properties of multiple controls to point to graphics files directly and therefore make compiler require those graphics files. 
* Class FxuFrmTestBroker 
	* Made form use FxuInstance. 
	* Introduced new property FxuInstance. 
	* Enforced passing FxuInstance object to Init() which gets stored in FxuInstance. 