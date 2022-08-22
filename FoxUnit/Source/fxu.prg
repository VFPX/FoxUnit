***********************************************************************
*  FoxUnit is Copyright (c) 2004 - 2005, Visionpace
*  All rights reserved.
*
*  Redistribution and use in source and binary forms, with or
*  without modification, are permitted provided that the following
*  conditions are met:
*
*    *  Redistributions of source code must retain the above
*      copyright notice, this list of conditions and the
*      following disclaimer.
*
*    *  Redistributions in binary form must reproduce the above
*      copyright notice, this list of conditions and the
*      following disclaimer in the documentation and/or other
*      materials provided with the distribution.
*
*    *  The names Visionpace and Vision Data Solutions, Inc.
*      (including similar derivations thereof) as well as
*      the names of any FoxUnit contributors may not be used
*      to endorse or promote products which were developed
*      utilizing the FoxUnit software unless specific, prior,
*      written permission has been obtained.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
*  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
*  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
*  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
*  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
*  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
*  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
*  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
*  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
*  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
*  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
*  POSSIBILITY OF SUCH DAMAGE.
***********************************************************************
LPARAMETERS tcMethodToAutoRun, tcParam1


#DEFINE C_Version "1.70"
EXTERNAL CLASS "fxu.vcx"
EXTERNAL PROCEDURE "DOCUMENTATION\FOXUNITLICENSE.MD"
EXTERNAL PROCEDURE "DOCUMENTATION\FOXUNITACKNOWLEDGEMENTS.MD"
EXTERNAL PROCEDURE "DOCUMENTATION\README.MD"
EXTERNAL PROCEDURE "DOCUMENTATION\VERSIONS.MD"
EXTERNAL PROCEDURE "TEXT\FXUTESTCASETEMPLATE.TXT"
EXTERNAL PROCEDURE "TEXT\FXUTESTCASETEMPLATE_MINIMAL.TXT"

SET CENTURY ON
SET CENTURY TO
SET CPDIALOG OFF
SET TABLEPROMPT OFF
SET DELETED ON
SET ESCAPE OFF
SET EXCLUSIVE OFF
SET HOURS TO 24
SET MULTILOCKS ON
SET NOTIFY OFF
SET SAFETY OFF
SET TALK OFF
SET DATE TO SHORT			&& -- Alan Bourke Oct 2021 - respect Windows date setting.

*-- FDBOZZO. 06/11/2011. This facilitates automation ("createFxuResultsAddAllTestsAndRun")
IF NOT EMPTY(tcMethodToAutoRun)
	DO (tcMethodToAutoRun) WITH tcParam1
	QUIT
ENDIF

IF FXUShowForm()
	RETURN
ENDIF

* Enable asserts for initial, interactive startup
IF INLIST(_VFP.Startmode, 0, 4)
	SET ASSERTS ON
&&	ELSE	&&	is it useful to turn them off otherwise?
&&		SET ASSERTS OFF
ENDIF

LOCAL loFxuInstance as fxuinstance OF "fxu.vcx"
m.loFxuInstance=NEWOBJECT("fxuinstance", "fxu.vcx", "", C_Version, GetFoxUnitPath())
IF VARTYPE(m.loFxuInstance)!="O" OR ISNULL(m.loFxuInstance)
	RETURN .F.
ENDIF

* FXU/JDE 07/01/2004
* Included goFoxUnitTestBroker as public in
* order to de-couple the any UI tested in
* a unit test from being a child of the
* top-level FoxUnit form.

RELEASE goFoxUnitForm, goFoxUnitTestBroker
PUBLIC goFoxUnitForm, goFoxUnitTestBroker
goFoxUnitTestBroker = m.loFxuInstance.FxuNewObject("FxuTestBroker", m.loFxuInstance)
goFoxUnitForm = m.loFxuInstance.FxuNewObject("FoxUnitForm", m.goFoxUnitTestBroker)
IF VARTYPE(m.goFoxUnitForm) = "O"
	goFoxUnitForm.SHOW()
ENDIF

RETURN




* Class to expose FoxUnit tests as COM objects
*-- The code for this class have been taken and adapted from John Miller's article "Integrating VFP into VSTS Team Projects"
*-- on this URL: http://www.code-magazine.com/article.aspx?quickid=0703102&page=3
*-- FDBOZZO - 31/10/2010 19:17
DEFINE CLASS fxu AS SESSION OLEPUBLIC
	cResultsFile			= ''
	cDebugFile				= ''
	oFoxUnitTestBroker		= .NULL.
	oFoxUnitForm			= .NULL.
	oFoxUnitInstance		= .NULL.
	oTestResult				= .NULL.
	lLogOnlyFailingTests	= .T.

	PROCEDURE INIT
		LPARAMETERS tcFileName, tcResultsFile

		* Textmerge is used for two purposes:
		* To log debugging information and
		* to write out the results files
		* expected by VSTS.
		SET SAFETY OFF
		SET EXCLUSIVE OFF

		*RELEASE goFoxUnitForm, goFoxUnitTestBroker
		*PUBLIC goFoxUnitForm as frmFoxUnit OF 'FXU.VCX', goFoxUnitTestBroker
		THIS.oFoxUnitInstance	= NEWOBJECT("FxuInstance", "fxu.vcx", "", C_Version, GetFoxUnitPath())
		THIS.oFoxUnitTestBroker	= THIS.oFoxUnitInstance.FxuNewObject("FxuTestBroker", THIS.oFoxUnitInstance)
		THIS.oTestResult		= THIS.oFoxUnitInstance.FxuNewObject("FxuTestResult")

		* Your paths may differ
		LOCAL lcPath, lcFileName, lcDetailedResultsFile
		IF EMPTY(tcFileName)
			tcFileName	= FORCEPATH("FOXUNIT.DEBUG.TXT", GETENV("TEMP"))
		ENDIF
		lcPath			= ADDBS(JUSTPATH(tcFileName))
		lcFileName		= JUSTFNAME(tcFileName)
		THIS.cDebugFile	= FORCEPATH(lcFileName,lcPath)
		
		IF NOT EMPTY(tcResultsFile)
			THIS.cResultsFile = FORCEPATH( JUSTFNAME(tcResultsFile), JUSTPATH(tcFileName) )
			ERASE (THIS.cResultsFile)
			lcDetailedResultsFile	= ADDBS( JUSTPATH( THIS.cResultsFile ) ) + "DetailedResults.txt"
			ERASE (lcDetailedResultsFile)

			* Create results summary file header
			SET TEXTMERGE ON NOSHOW
			TEXT to cText
<?xml version="1.0" encoding="utf-8" ?>
<SummaryResult>

			ENDTEXT
			SET TEXTMERGE OFF
			SET TEXTMERGE TO
			STRTOFILE( STRCONV(cText,9), THIS.cResultsFile )

		ENDIF

		*ERASE d:\test\foxunit.DEBUG.txt
		*SET TEXTMERGE TO d:\test\foxunit.DEBUG.txt
		ERASE (lcPath + lcFileName)
		SET TEXTMERGE TO (lcPath + lcFileName)
		SET TEXTMERGE ON NOSHOW

   \Debug Start
   \

	ENDPROC
	

	PROCEDURE DESTROY
		IF NOT EMPTY(THIS.cResultsFile)
		* Create results summary file footer
			SET TEXTMERGE ON NOSHOW
			TEXT to cText
</SummaryResult>

			ENDTEXT
			SET TEXTMERGE OFF
			SET TEXTMERGE TO
			STRTOFILE( STRCONV(cText,9), THIS.cResultsFile, 1 )
		ENDIF
		
		IF FILE(THIS.cDebugFile)
			STRTOFILE( STRCONV( FILETOSTR(THIS.cDebugFile),9), THIS.cDebugFile )
		ENDIF
	ENDPROC
	

	* Do the real work
	FUNCTION RunTest( ;
			tcTest AS STRING, ;
			tcTestMethod AS STRING, ;
			tcSourcePath AS STRING, ;
			tcResultsFile AS STRING ) AS INTEGER

		LOCAL lcDetailedResultsFile, llSeparatedLogFile
		llSeparatedLogFile = (NOT EMPTY(tcResultsFile))
		tcResultsFile			= EVL(tcResultsFile, THIS.cResultsFile)
		
		* Parameter validation
		IF EMPTY( tcTest ) ;
				OR EMPTY( tcTestMethod ) ;
				OR EMPTY( tcSourcePath ) ;
				OR EMPTY( tcResultsFile )

			ERROR "Missing Parameter"
		ENDIF

		lcDetailedResultsFile	= ADDBS( JUSTPATH( tcResultsFile ) ) + "DetailedResults.txt"

		* Write to debug log
   \====================================================================================================
   \Parameters:
   \tcTest:         << tcTest >>
   \tcTestMethod:   << tcTestMethod >>
   \tcSourcePath:   << tcSourcePath >>
   \tcResultsFile:  << tcResultsFile >>

		* Parameter validation
		IF ! DIRECTORY( tcSourcePath )
			ERROR "Source Directory not found"
		ENDIF

		* Write to debug log
   \
   \Directory:      << sys(5) + sys(2003) >>
   \set("Path"):    << set("Path") >>
   \_vfp.StartMode: << _vfp.StartMode >>
   \FoxUnitSetup    << datetime() >>

		LOCAL goFoxUnitTestBroker

   \Create goFoxUnitTestBroker

		* The test broker runs the test
		goFoxUnitTestBroker = THIS.oFoxUnitTestBroker

		LOCAL oTestResult

		* Write to debug log
   \Create oTestResult

		* The test result encapsulates the results
		oTestResult = THIS.oTestResult

		* Write to debug log
   \Set oTestResult properties

		oTestResult.icCurrentTestClass = tcTest
		oTestResult.icCurrentTestName = tcTestMethod
		oTestResult.icMessages	= ''

		* Write to debug log
   \Run Test ...........................................................................................
   \

		* Here we go!
		goFoxUnitTestBroker.RunTest( tcTest, tcTestMethod, oTestResult, .F. )

   \Set lTestPassed to
   \\<< oTestResult.ilCurrentResult >>

		* Thumbs up?
		lTestPassed = oTestResult.ilCurrentResult

		cResults = IIF( lTestPassed, "Passed", "Failed" )
		cMessage = oTestResult.icMessages
		cMessage = STRTRAN( cMessage, CHR(13)+CHR(10), CHR(10))
		cMessage = STRTRAN( cMessage, CHR(13), CHR(10))
		cMessage = STRTRAN( cMessage, CHR(10), CHR(13)+CHR(10))

		* Write to debug log
   \Set results properties
   \cResults = << cResults >>
   \cMessage:
   FOR i = 1 TO ALINES( laLines, cMessage )
      \<< laLines(i) >>
   ENDFOR
   *\cMessage = << cMessage >>

   * Write to debug log
   \Generate Results
   \
   \


		IF NOT THIS.lLogOnlyFailingTests OR THIS.lLogOnlyFailingTests AND NOT lTestPassed
			SET TEXTMERGE TO

			* Create results summary file
			SET TEXTMERGE ON NOSHOW

			IF llSeparatedLogFile

				TEXT to cText
<?xml version="1.0" encoding="utf-8" ?>
<SummaryResult>
	<TestName><<tcTest>></TestName>
	<TestResult><< cResults >></TestResult>
	<InnerTests>
		<InnerTest>
			<TestName><< tcTestMethod >></TestName>
			<TestResult><< cResults >></TestResult>
			<ErrorMessage><< cMessage >></ErrorMessage>
			<DetailedResultsFile>
				<< lcDetailedResultsFile >>
			</DetailedResultsFile>
		</InnerTest>
	</InnerTests>
</SummaryResult>
				ENDTEXT

			ELSE

				TEXT to cText
	<Test>
		<TestName><<tcTest>></TestName>
		<TestResult><< cResults >></TestResult>
		<InnerTests>
			<InnerTest>
				<TestName><< tcTestMethod >></TestName>
				<TestResult><< cResults >></TestResult>
				<ErrorMessage><< cMessage >></ErrorMessage>
				<DetailedResultsFile>
					<< lcDetailedResultsFile >>
				</DetailedResultsFile>
			</InnerTest>
		</InnerTests>
	</Test>

				ENDTEXT

			ENDIF

			SET TEXTMERGE OFF

			* Write summary to disk
			STRTOFILE( STRCONV(cText,9), tcResultsFile, 1 )

			* Create results detail file
			IF ISNULL( oTestResult.ioExceptionInfo )
				cExceptionInfo = "None"
			ELSE
				cExceptionInfo = oTestResult.ioExceptionInfo.ToString()
			ENDIF

			IF ISNULL( oTestResult.ioTeardownExceptionInfo )
				cTeardownExceptionInfo = "None"
			ELSE
				cTeardownExceptionInfo = oTestResult.ioTeardownExceptionInfo.ToString()
			ENDIF

			SET TEXTMERGE ON NOSHOW
			cFED = oTestResult.icFailureErrorDetails
			cFED = STRTRAN( cFED, CHR(13)+CHR(10), CHR(10))
			cFED = STRTRAN( cFED, CHR(13), CHR(10))
			cFED = STRTRAN( cFED, CHR(10), CHR(13)+CHR(10))

			TEXT to cText

--------------------------------------------------------------------------------------
Test Class:           << oTestResult.icCurrentTestClass >>
Test Name:            << oTestResult.icCurrentTestName >>
Total execution time: << oTestResult.inCurrentEndSeconds - oTestResult.inCurrentStartSeconds >> seconds
Result:               << cResults >>
Messages:             << cMessage >>
Failed Tests:         << oTestResult.inFailedTests >>
Failed Error Details: << cFED >>
Exception Info:       << cExceptionInfo >>
Teardown Exception:   << cTeardownExceptionInfo >>


			ENDTEXT

			SET TEXTMERGE OFF

			* Write detail file to disk
			STRTOFILE( STRCONV(cText,9), lcDetailedResultsFile, 1 )

		ENDIF && NOT THIS.lLogOnlyFailingTests OR THIS.lLogOnlyFailingTests AND NOT lTestPassed

		RETURN IIF(oTestResult.ilCurrentResult, 0, 1)
	ENDFUNC


	PROCEDURE encode( cString )
		cResults = cString
		cResults = STRTRAN( cResults, "\", "%5C")
		cResults = STRTRAN( cResults, "", "%20" )
		RETURN cResults
	ENDPROC

	PROCEDURE ERROR(nError, cMethod, nLine)
		* Write error to debug log
   \
   \Error:          << nError >>
   \Method:         << cMethod >>
   \Line:           << nLine >>

		*--------------------------------------------
		* Set DOS errorlevel. CCNet interprets
		* errorlevel 0 as success, everything else as
		* failure. So we exit with errorlevel 1.
		*--------------------------------------------
		*DECLARE ExitProcess in Win32API INTEGER ExitCode
		*=ExitProcess( 1 )

		objWMIService = GETOBJECT("winmgmts:\\.\root\CIMV2")
		objWMIService.Security_.ImpersonationLevel = 3  && wbemImpersonationLevelImpersonate
		colItems = objWMIService.ExecQuery( "SELECT * FROM Win32_Process WHERE ProcessID = " + TRANSFORM(_VFP.ProcessId) + "", "WQL", 0x10 + 0x20)
		FOR EACH objItem IN colItems
			objItem.Terminate(1)
		ENDFOR

		IF INLIST(_VFP.StartMode, 2, 3, 5)
			COMRETURNERROR( MESSAGE(1), TRANSFORM(m.nError) + " - " + MESSAGE() + CHR(13) + m.cMethod + ", línea:" + TRANSFORM(m.nLine))
		ELSE
			RETURN
		ENDIF
	ENDPROC

ENDDEFINE


*************************************************
PROCEDURE GetFoxUnitPath
	*************************************************
	*
	*	RETURNs the path of either
	*	- The FoxUnit 'executable' (if running as APP or EXE)
	*	- The FoxUnit project file (PJX, if run through DO fxp)
	*
	*	Adapted code originally written by HAS.
	LOCAL lnLevels, lcResult
	LOCAL ARRAY laProgChain[1,1]

	m.lnLevels = ASTACKINFO(m.laProgChain)
	ASSERT m.lnLevels>0 MESSAGE "ASTACKINFO() failed!"
	
	IF INLIST(UPPER(JUSTEXT(m.laProgChain[m.lnLevels, 2])), "APP", "EXE")
		DEBUGOUT "fxu.prg/GetFoxUnitPath()", "Found compiled module ", m.laProgChain[m.lnLevels, 2]
		m.lcResult = ADDBS(JUSTPATH(m.laProgChain[m.lnLevels, 2]))
	ELSE
		DEBUGOUT "fxu.prg/GetFoxUnitPath()", "Found source module ", m.laProgChain[m.lnLevels, 2]
		m.lcResult = ADDBS(JUSTPATH(JUSTPATH(m.laProgChain[m.lnLevels, 2])))
	ENDIF
	DEBUGOUT "fxu.prg/GetFoxUnitPath()", "m.lcResult evaluated to", m.lcResult
	
	ASSERT DIRECTORY(m.lcResult, 1) MESSAGE "FoxUnit Path {" + m.lcResult + "} doesn't exist!"
	
	RETURN m.lcResult
ENDPROC


*************************************************
PROCEDURE GetFoxUnitForm
	*************************************************
	*
	*  RETURN an object reference to the FoxUnit form
	*  (form inheriting from FXU.VCX/frmFoxUnit)
	*     MODIFY CLASS frmFoxUnit OF FXU.VCX
	*
	LOCAL loFXUForm, loForm, lcFormID, laClasses[1]
	loFXUForm = .NULL.
	FOR EACH loForm IN _SCREEN.FORMS
		DIMENSION laClasses[1]
		ACLASS(laClasses,m.loForm)
		IF ASCAN(laClasses,"frmFoxUnit",1,-1,1,15) > 0
			loFXUForm = m.loForm
			EXIT
		ENDIF
	ENDFOR
	RETURN m.loFXUForm
ENDPROC


*************************************************
PROCEDURE GetFoxUnitVersion
	*************************************************
	*
	*  pass the tcVersion parameter by REFERENCE like this:
	*    DO GetFoxUnitVersion WITH SomeVar
	*  and it gets populated here, as we've done here toward
	*  the end of this method:
	*    MODIFY CLASS frmFoxUnit OF FXU.VCX METHOD Load
	*
	*  or, you can SET PROCEDURE TO FXU, and:
	*    SomeVar = GetFoxUnitVersion()
	*
	LPARAMETERS tcVersion
	tcVersion = C_Version
	RETURN C_Version
ENDPROC

&&	ManageFxuClassFactory() has been moved to fxu.vcx/FxuInstance.ManageFxuClassFactory()

********************************************************************
* EHW/02/27/2005
********************************************************************
FUNCTION getArrayOfNewTestCases(taNewTests AS ARRAY, taOldTests AS ARRAY, tcDirectory AS STRING)
	********************************************************************
	*
	* Returns the number of testcases in the passed directory that are not already in taOldTest.
	* Updates the passed array with a list of valid test case programs.
	*
	* A test case is only valid if it can be instantiated in the current
	* test environment. It is possible that a file will be a valid test
	* case but not be able to run under the current enviornment. This
	* function is designed to remove those program files from the list.
	*
	LOCAL lnFileCount, lnx, lnLoopCount, lcAsserts
	lnFileCount = 0
	lnFileCount = getArrayOfNewProgramFiles(@taNewTests, @taOldTests, tcDirectory)
	IF lnFileCount > 0
		lnLoopCount = lnFileCount
		lcAsserts = SET("Asserts")
		SET ASSERTS OFF
		FOR lnx = lnLoopCount TO 1 STEP - 1
			IF fxuInheritsFromFxuTestCase(JUSTSTEM(taNewTests[lnx,1]), ADDBS(m.tcDirectory) + taNewTests[lnx,1]) = .F.
				*
				* Not a test case, delete it
				*
				ADEL(taNewTests,lnx)
				lnFileCount = lnFileCount - 1
			ENDIF
		NEXT
		IF lcAsserts = "ON"
			SET ASSERTS ON
		ENDIF
		IF lnFileCount <> lnLoopCount
			IF VARTYPE(taNewTests[1]) = 'C'
				*
				* Deleteing rows from the array with ADEL
				* leaves the array the same size. Resize the
				* array and Remove the empty rows (the deleted ones)
				* from the bottom of the array.
				*
				DIMENSION taNewTests[lnFileCount,ALEN(taNewTests,2)]
			ELSE
				*
				* All files were deleted
				*
				DIMENSION  taNewTests[1]
			ENDIF
		ELSE
			*
			* nothing was deleted, taNewTests has the files
			*
		ENDIF
	ENDIF
	RETURN lnFileCount
	********************************************************************
ENDFUNC
********************************************************************

********************************************************************
FUNCTION getArrayOfTestCases(taTestCases AS ARRAY, tcDirectory AS STRING)
	********************************************************************
	*
	* Returns the number of testcases in the passed directory.
	* Updates the passed array with a list of valid test case programs.
	*
	* A test case is only valid if it can be instantiated in the current
	* test environment. It is possible that a file will be a valid test
	* case but not be able to run under the current enviornment. This
	* function is designed to remove those program files from the list.
	*
	LOCAL lnFileCount, lnx, lnLoopCount, lcAsserts
	lnFileCount = 0
	lnFileCount = getArrayOfProgramFiles(@taTestCases, tcDirectory)
	IF lnFileCount > 0
		lnLoopCount = lnFileCount
		lcAsserts = SET("Asserts")
		SET ASSERTS OFF
		FOR lnx = lnLoopCount TO 1 STEP - 1
			IF fxuInheritsFromFxuTestCase(JUSTSTEM(taTestCases[lnx,1]), ;
					ADDBS(m.tcDirectory) + taTestCases[lnx,1]) = .F. && Added directory to file name parameter. HAS

				ADEL(taTestCases,lnx)
				lnFileCount = lnFileCount - 1

			ENDIF
		NEXT
		IF lcAsserts = "ON"
			SET ASSERTS ON
		ENDIF
		IF lnFileCount <> lnLoopCount
			IF VARTYPE(taTestCases[1]) = 'C'
				*
				* Deleteing rows from the array with ADEL
				* leaves the array the same size. Resize the
				* array and Remove the empty rows (the deleted ones)
				* from the bottom of the array.
				*
				DIMENSION taTestCases[lnFileCount,ALEN(taTestCases,2)]
			ELSE
				*
				* All files were deleted
				*
				DIMENSION taTestCases[1]
			ENDIF
		ELSE
			*
			* nothing was deleted, taTestCases has the files
			*
		ENDIF

	ENDIF
	RETURN lnFileCount
	********************************************************************
ENDFUNC
********************************************************************


********************************************************************
FUNCTION getArrayOfNewProgramFiles(taNewFiles AS ARRAY, taOldFiles AS ARRAY, tcDirectory AS STRING)
	********************************************************************
  LOCAL lnFileCount, lnLoopCount, lnX, lnOldIndex, lnOldFileCount
	lnFileCount = getArrayOfProgramFiles(@taNewFiles, tcDirectory)
	IF lnFileCount > 0
		lnOldFileCount = ALEN(taOldFiles,1)
		lnLoopCount = lnFileCount
		IF lnOldFileCount > 0
      FOR lnX = lnLoopCount TO 1 STEP -1
				IF ASCAN(taOldFiles,JUSTSTEM(taNewFiles[lnx,1]),1,lnOldFileCount,1,15) > 0
					*
					* This file is already in the list.
					* Delete the file name.
					*
					ADEL(taNewFiles,lnx)
					lnFileCount = lnFileCount - 1
				ENDIF
			NEXT
			IF lnFileCount <> lnLoopCount
				IF VARTYPE(taNewFiles[1]) = 'C'
					*
					* Deleteing rows from the array with ADEL
					* leaves the array the same size. Resize the
					* array and Remove the empty rows (the deleted ones)
					* from the bottom of the array.
					*
					DIMENSION taNewFiles[lnFileCount,ALEN(taNewFiles,2)]
				ELSE
					*
					* All files were deleted
					*
					DIMENSION  taNewFiles[1]
				ENDIF
			ELSE
				*
				* nothing was deleted, taNewFiles has the files
				*
			ENDIF

		ENDIF
	ENDIF
	RETURN lnFileCount
	********************************************************************
ENDFUNC
********************************************************************


********************************************************************
FUNCTION getArrayOfProgramFiles(taFiles AS ARRAY, tcDirectory AS STRING)
	********************************************************************
	*
	* Returns the number of programs in the passed directory.
	* Updates the passed array with a list of programs.
	*
	LOCAL lnFileCount, lcDirectory
	lnFileCount = 0
	lcDirectory = ''
	*
	* Validate the directory
	*
	DO CASE
	CASE EMPTY(tcDirectory)
		lcDirectory = FULLPATH('.')
	CASE NOT DIRECTORY(tcDirectory)
		lnFileCount = -1
	OTHERWISE
		lcDirectory = tcDirectory
	ENDCASE
	IF lnFileCount = 0
		lcDirectory = ADDBS(lcDirectory)
		lnFileCount = ADIR(taFiles,lcDirectory+'\*.prg','',1)
	ENDIF
	RETURN lnFileCount
	********************************************************************
ENDFUNC
********************************************************************
* EHW/02/27/2005 END
********************************************************************

&&	CheckPath() was moved to fxu.vcx/FxuInstance.Init()

&&	GetTestsDir() has been replaced by the FxuInstance.DataPath property

FUNCTION FXUShowForm
	LOCAL loFXUForm
	loFXUForm = GetFoxUnitForm()
	IF VARTYPE(m.loFXUForm) = "O"
	  loFXUForm.Show()
	  loFXUForm.WindowState = 0
	  RETURN .T.
	ENDIF
	RETURN .F.
ENDFUNC

PROCEDURE runTests
LPARAMETERS cLogPath, cResultFormat, cTestClass, cTest
cLogPath=EVL(cLogPath, ".\")
cResultFormat=EVL(cResultFormat, "JUNIT")	&& Default to JUNIT compatible
*% TODO: Filter to just run the right tests
createFxuResultsAddAllTestsAndRun(cLogPath)


PROCEDURE createFxuResultsAddAllTestsAndRun
	*-- FDBOZZO. 06/11/2011. New method to automate the running of all tests from a CI server.
	*-- This is the Use Case:
	*-- 	- Automation centralized in a CruiseControl server:
	*-- 	- Get all source code of the project and the Unit Tests from SourceSafe
	*-- 	- If ok, compile all files and generate the EXE or APP of the project and generate error log, if any
	*-- 	- If ok, run all test cases, generate statistics and error log, if any
	*------------------------------------------------------------------------------------------------------
	LPARAMETERS tcLogsPath

	TRY
		LOCAL lcFXUDataPath, loCovEng, lcCovFile, lcUT_ErrFile, llTestFailed, llTerminate, lcCovStats ;
			, lnTest, lnTests, lnTestsOK, lnTestsFailed, lcTestStats, lcTestFile ;
			, loFxu as fxu OF 'Fxu.prg' ;
			, oTestResult as "FxuTestResult" ;
			, loEx as Exception ;
			, loFxuInstance as fxuinstance OF "fxu.vcx"
		
		m.loFxuInstance=NEWOBJECT("fxuinstance", "fxu.vcx", "", C_Version, GetFoxUnitPath())
		IF VARTYPE(m.loFxuInstance)!="O"
			RETURN .F.
		ENDIF
		
		STORE .NULL. TO loFxu, goFoxUnitForm, goFoxUnitTestBroker
		*_SCREEN.AlwaysOnTop= .T.
		*ZOOM WINDOW SCREEN MAX
		
		lcFXUDataPath	= ADDBS(m.loFxuInstance.DataPath)
		IF NOT EMPTY(tcLogsPath) AND DIRECTORY(tcLogsPath)
			tcLogsPath	= ADDBS(tcLogsPath)
		ELSE
			tcLogsPath	= lcFXUDataPath
		ENDIF
		lcCovFile		= tcLogsPath + 'UT_COVERAGE_STATS.TXT'
		lcTestFile		= tcLogsPath + 'UT_STATS.TXT'
		lcUT_ErrFile	= tcLogsPath + 'UT_ERRORS.LOG'

		*-- Erase previous FxuResults to make a new one
		ERASE (tcLogsPath + 'FxuResults.DBF')
		ERASE (tcLogsPath + 'FxuResults.FPT')
		ERASE (tcLogsPath + 'FxuResults.CDX')
		
		*-- The coverage log is generated in the unit tests, activates on Setup and deactivates on TearDown.
		ERASE (tcLogsPath + 'UT_COVERAGE.LOG')
		ERASE (tcLogsPath + 'UT_COVERAGE_COV1.DBF')
		ERASE (tcLogsPath + 'UT_COVERAGE_COV1.FPT')
		ERASE (tcLogsPath + 'UT_COVERAGE_STACK1.XML')
		ERASE (lcCovFile)
		ERASE (lcUT_ErrFile)

		RELEASE goFoxUnitForm, goFoxUnitTestBroker
		PUBLIC goFoxUnitForm as frmFoxUnit OF 'FXU.VCX', goFoxUnitTestBroker
		goFoxUnitTestBroker = m.loFxuInstance.FxuNewObject("FxuTestBroker", m.loFxuInstance)
		goFoxUnitForm = m.loFxuInstance.FxuNewObject("FoxUnitForm", m.goFoxUnitTestBroker)

		IF VARTYPE(m.goFoxUnitForm) = "O"
			goFoxUnitForm.ioTestBroker = goFoxUnitTestBroker

			*-- Adapted from FxuResultData.prg
			LOCAL loFrmLoadClass AS fxuFrmLoadClass OF fxu.vcx
			LOCAL i
			STORE .NULL. TO loFrmLoadClass
			loFrmLoadClass=NEWOBJECT('fxuFrmLoadClass','fxu.vcx','',lcFXUDataPath)
			*loFrmLoadClass.Show()

			*-- Select all available test cases and fill the FxuResultData table
			IF loFrmLoadClass.lstFiles.ListCount > 0
				loFrmLoadClass.selectall(.T.)
				loFrmLoadClass.okaction()

				IF loFrmLoadClass.ilCancel = .F.
					WITH loFrmLoadClass.lstFiles
						FOR i = 1 TO .LISTCOUNT
							IF loFrmLoadClass.lstFiles.SELECTED[i]
								goFoxUnitForm.ioResultData.LoadTestCaseClassStep2(ADDBS(loFrmLoadClass.icfxuselectedtestdirectory) + .LISTITEM[i], .T.) && Added path to file name. HAS
							ENDIF
						NEXT
					ENDWITH
				ENDIF
			ENDIF

			* Joel Leach: Releasing this early causes error when form is released below
			*goFoxUnitForm.ioResultData = .NULL.
			goFoxUnitForm.ioTestBroker = .NULL.
			RELEASE loFrmLoadClass
			*--
			*goFoxUnitForm.SHOW()
			*goFoxUnitForm.RunAllTests()

			RELEASE goFoxUnitForm
		ENDIF

		RELEASE goFoxUnitForm, goFoxUnitTestBroker

		*-- Run all the tests
		loFxu = CREATEOBJECT( 'fxu', tcLogsPath + 'FOXUNIT.DEBUG.TXT', tcLogsPath + 'ResultsFile.xml' )
		loFxu.lLogOnlyFailingTests = .T.
		
		LOCAL laTests(1)
		SELECT TClass, TName, TPath FROM (lcFXUDataPath + 'FXURESULTS') INTO ARRAY laTests
		USE IN (SELECT('FXURESULTS'))
		STORE 0 TO lnTestsOK, lnTestsFailed
		lnTests = ALEN(laTests,1)
		IF EMPTY(laTests(1)) OR ISNULL(laTests(1))
			lnTests = 0
		ENDIF
		
		FOR m.lnTest = 1 TO lnTests
			IF loFxu.runtest( ALLTRIM(laTests(m.lnTest,1)), ALLTRIM(laTests(m.lnTest,2)), ALLTRIM(laTests(m.lnTest,3)) ) = 0
				*-- Test OK
				lnTestsOK	= lnTestsOK + 1
			ELSE
				*-- One test have failed!
				llTestFailed	= .T.
				lnTestsFailed	= lnTestsFailed + 1
			ENDIF
		ENDFOR
		*--
		
		RELEASE loFxu

		
		*-- Guardo log de resumen de ejecución de los tests
		lcTestStats = ''
		lcTestStats = lcTestStats + '<TestStats>' + CHR(13) + CHR(10)
		lcTestStats = lcTestStats + CHR(9) + '<TestsOK>' + TRANSFORM(lnTestsOK) + ' of ' + TRANSFORM(lnTests) + '</TestsOK>' + CHR(13) + CHR(10)
		lcTestStats = lcTestStats + CHR(9) + '<TestsFailed>' + TRANSFORM(lnTestsFailed) + ' of ' + TRANSFORM(lnTests) + '</TestsFailed>' + CHR(13) + CHR(10)
		lcTestStats = lcTestStats + '</TestStats>' + CHR(13) + CHR(10)
		STRTOFILE( STRCONV(lcTestStats,9), lcTestFile )

		IF llTestFailed
			EXIT
		ENDIF
		
        *-- COVERAGE.CFG is used as semaphor file. If exist with vlaue of '0' it deactivates de coverage analysis
        IF FILE(tcLogsPath + "UT_COVERAGE.LOG") AND (NOT FILE("COVERAGE.CFG") OR FILETOSTR("COVERAGE.CFG") = '1')
            *-- Now that all tests are executed and have the coverage log, take the statistics.
            loCovEng    = NEWOBJECT("cov_engine", "coverage.vcx", _coverage, tcLogsPath + "UT_COVERAGE.LOG", .T.)
            loCovEng.Release()
            loCovEng    = .NULL.
            
            IF FILE(tcLogsPath + 'UT_COVERAGE_COV1.DBF')
                USE (tcLogsPath + 'UT_COVERAGE_COV1.DBF') SHARED NOUPDATE
                lcCovStats = ''
                lcCovStats = lcCovStats + '<CoverageCodeStats>' + CHR(13) + CHR(10)
                
                *-- Scan all results, with the exception of FoxUnit code and Unit Tests code
                SCAN ALL FOR ATC( '\foxunit\', HostFile ) = 0 AND ATC( '\tests\', HostFile ) = 0
                    lcCovStats = lcCovStats + CHR(9) ;
                        + '<item>covered ' + TRANSFORM(covered * 100 / coverable, '####.##') ;
                        + '% for class [' + ALLTRIM(ObjClass) + '] of file ' + SYS(2014, ALLTRIM(HostFile)) ;
                        + '</item>' + CHR(13) + CHR(10)
                ENDSCAN
                
                lcCovStats = lcCovStats + '</CoverageCodeStats>' + CHR(13) + CHR(10)
                STRTOFILE( STRCONV(lcCovStats,9), lcCovFile )
            ENDIF
        ENDIF


	CATCH TO loEx
		llTerminate = .T.
		STRTOFILE( PROGRAM() + ' ERROR: ' + TRANSFORM(loEx.ErrorNo) + ', ' + loEx.Message + CHR(13) ;
			+ 'Line: ' + TRANSFORM(loEx.LineNo) + CHR(13) ;
			+ '>> ' + loEx.Details ;
			, lcUT_ErrFile )

	FINALLY
		*-- Garbage collect
		USE IN (SELECT('FxuResults'))
		USE IN (SELECT('UT_COVERAGE_COV1'))
		
		STORE .NULL. TO loFxu, loFrmLoadClass,goFoxUnitForm, goFoxUnitTestBroker
		RELEASE loFrmLoadClass,goFoxUnitForm, goFoxUnitTestBroker

		IF VARTYPE(loCovEng) = "O" AND NOT ISNULL(loCovEng)
			loCovEng.Release()
			loCovEng	= .NULL.
		ENDIF
	ENDTRY

	IF NOT llTestFailed AND NOT llTerminate
		IF _VFP.STARTMODE # 4
			RETURN
		ENDIF
		QUIT
	ENDIF
	
     *--------------------------------------------
     * Set DOS errorlevel. CCNet interprets
     * errorlevel 0 as success, everything else as
     * failure. So we exit with errorlevel 1.
     *--------------------------------------------
     CLEAR DLLS
     CLEAR ERROR
     CLEAR EVENTS
     CLOSE PROCEDURES
     CLOSE ALL
     CLEAR ALL
     =SYS(1104)
		
     *objWMIService = GETOBJECT("winmgmts:\\.\root\CIMV2")
     *objWMIService.Security_.ImpersonationLevel = 3  && wbemImpersonationLevelImpersonate
     *colItems = objWMIService.ExecQuery( "SELECT * FROM Win32_Process WHERE ProcessID = " + TRANSFORM(_VFP.ProcessId) + "", "WQL", 0x10 + 0x20)
     *FOR EACH objItem IN colItems
     *   objItem.Terminate(1)
     *ENDFOR

     DECLARE ExitProcess in Win32API INTEGER ExitCode
     ExitProcess(1)
     QUIT

ENDPROC


DEFINE CLASS sesTextBlockReport AS SESSION

	*
	*  MODIFY CLASS frmShowInfo OF FXU METHOD PrintInfo
	*

	NAME = "sesTextBlockReport"


	***************************************************
	PROCEDURE CreateTextBlockFRX
		***************************************************
		*
		*  XXFWUTIL.VCX/frmTextblockReport::CreateTextblockFRX()
		*
		*
		*  create the temporary .FRX for the report, same
		*  as XXTBLOCK.FRX, just a header, detail, and
		*  DATETIME() in the footer
		*
		*  this method eliminates the need for an XXTBLOCK.FRX
		*  by creating it on the fly
		*
		*  CURSORTOXML("TempCursor","Junk.XML",1,0+2+8+512,0,"1")
		*
		LOCAL lcFileName, lcText
		lcFileName = ADDBS(SYS(2023)) + SYS(2015)+".XML"
		TEXT TO lcText NOSHOW
<?xml version = "1.0" encoding="Windows-1252" standalone="yes"?>
<VFPData>
  <xsd:schema id="VFPData" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">
    <xsd:element name="VFPData" msdata:IsDataSet="true">
      <xsd:complexType>
        <xsd:choice maxOccurs="unbounded">
          <xsd:element name="tempcursor" minOccurs="0" maxOccurs="unbounded">
            <xsd:complexType>
              <xsd:sequence>
                <xsd:element name="platform">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="8"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="uniqueid">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="10"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="timestamp">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="10"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="objtype">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="2"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="objcode">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="3"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="name">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="expr">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="vpos">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="8"></xsd:totalDigits>
                      <xsd:fractionDigits value="3"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="hpos">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="8"></xsd:totalDigits>
                      <xsd:fractionDigits value="3"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="height">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="8"></xsd:totalDigits>
                      <xsd:fractionDigits value="3"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="width">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="8"></xsd:totalDigits>
                      <xsd:fractionDigits value="3"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="style">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="picture">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="order">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:base64Binary">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="unique" type="xsd:boolean"></xsd:element>
                <xsd:element name="comment">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="environ" type="xsd:boolean"></xsd:element>
                <xsd:element name="boxchar">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="1"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="fillchar">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="1"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="tag">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="tag2">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:base64Binary">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="penred">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="5"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="pengreen">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="5"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="penblue">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="5"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="fillred">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="5"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="fillgreen">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="5"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="fillblue">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="5"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="pensize">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="5"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="penpat">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="5"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="fillpat">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="5"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="fontface">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="fontstyle">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="3"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="fontsize">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="3"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="mode">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="3"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="ruler">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="1"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="rulerlines">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="1"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="grid" type="xsd:boolean"></xsd:element>
                <xsd:element name="gridv">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="2"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="gridh">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="2"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="float" type="xsd:boolean"></xsd:element>
                <xsd:element name="stretch" type="xsd:boolean"></xsd:element>
                <xsd:element name="stretchtop" type="xsd:boolean"></xsd:element>
                <xsd:element name="top" type="xsd:boolean"></xsd:element>
                <xsd:element name="bottom" type="xsd:boolean"></xsd:element>
                <xsd:element name="suptype">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="1"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="suprest">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="1"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="norepeat" type="xsd:boolean"></xsd:element>
                <xsd:element name="resetrpt">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="2"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="pagebreak" type="xsd:boolean"></xsd:element>
                <xsd:element name="colbreak" type="xsd:boolean"></xsd:element>
                <xsd:element name="resetpage" type="xsd:boolean"></xsd:element>
                <xsd:element name="general">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="3"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="spacing">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="3"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="double" type="xsd:boolean"></xsd:element>
                <xsd:element name="swapheader" type="xsd:boolean"></xsd:element>
                <xsd:element name="swapfooter" type="xsd:boolean"></xsd:element>
                <xsd:element name="ejectbefor" type="xsd:boolean"></xsd:element>
                <xsd:element name="ejectafter" type="xsd:boolean"></xsd:element>
                <xsd:element name="plain" type="xsd:boolean"></xsd:element>
                <xsd:element name="summary" type="xsd:boolean"></xsd:element>
                <xsd:element name="addalias" type="xsd:boolean"></xsd:element>
                <xsd:element name="offset">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="3"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="topmargin">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="3"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="botmargin">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="3"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="totaltype">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="2"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="resettotal">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="2"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="resoid">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="3"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="curpos" type="xsd:boolean"></xsd:element>
                <xsd:element name="supalways" type="xsd:boolean"></xsd:element>
                <xsd:element name="supovflow" type="xsd:boolean"></xsd:element>
                <xsd:element name="suprpcol">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="1"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="supgroup">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="2"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="supvalchng" type="xsd:boolean"></xsd:element>
                <xsd:element name="supexpr">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="user">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
              </xsd:sequence>
            </xsd:complexType>
          </xsd:element>
        </xsd:choice>
        <xsd:anyAttribute namespace="http://www.w3.org/XML/1998/namespace" processContents="lax"></xsd:anyAttribute>
      </xsd:complexType>
    </xsd:element>
  </xsd:schema>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid>_RU901GIQ7</uniqueid>
    <timestamp>614008089</timestamp>
    <objtype>1</objtype>
    <objcode>53</objcode>
    <name></name>
    <expr><![CDATA[ORIENTATION=0
PAPERSIZE=1
COPIES=1
DEFAULTSOURCE=1
YRESOLUTION=600
TTOPTION=1
]]></expr>
    <vpos>1.000</vpos>
    <hpos>0.000</hpos>
    <height>0.000</height>
    <width>-1.000</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar></fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>0</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>0</fillred>
    <fillgreen>0</fillgreen>
    <fillblue>0</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface><![CDATA[Courier New]]></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>10</fontsize>
    <mode>0</mode>
    <ruler>1</ruler>
    <rulerlines>0</rulerlines>
    <grid>true</grid>
    <gridv>4</gridv>
    <gridh>4</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>false</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>true</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>0</resettotal>
    <resoid>0</resoid>
    <curpos>true</curpos>
    <supalways>false</supalways>
    <supovflow>false</supovflow>
    <suprpcol>0</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid>_RU901GIQ9</uniqueid>
    <timestamp>0</timestamp>
    <objtype>9</objtype>
    <objcode>1</objcode>
    <name></name>
    <expr></expr>
    <vpos>0</vpos>
    <hpos>0</hpos>
    <height>5313.000</height>
    <width>0.000</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar></fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>0</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>0</fillred>
    <fillgreen>0</fillgreen>
    <fillblue>0</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>0</fontsize>
    <mode>0</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>false</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>0</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>false</supalways>
    <supovflow>false</supovflow>
    <suprpcol>0</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid>_RU901GIQA</uniqueid>
    <timestamp>0</timestamp>
    <objtype>9</objtype>
    <objcode>4</objcode>
    <name></name>
    <expr></expr>
    <vpos>0</vpos>
    <hpos>0</hpos>
    <height>3334.000</height>
    <width>0.000</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar></fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>0</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>0</fillred>
    <fillgreen>0</fillgreen>
    <fillblue>0</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>0</fontsize>
    <mode>0</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>false</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>0</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>false</supalways>
    <supovflow>false</supovflow>
    <suprpcol>0</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid>_RU901GIQB</uniqueid>
    <timestamp>0</timestamp>
    <objtype>9</objtype>
    <objcode>7</objcode>
    <name></name>
    <expr></expr>
    <vpos>0</vpos>
    <hpos>0</hpos>
    <height>6355.000</height>
    <width>0.000</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar></fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>0</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>0</fillred>
    <fillgreen>0</fillgreen>
    <fillblue>0</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>0</fontsize>
    <mode>0</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>false</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>0</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>false</supalways>
    <supovflow>false</supovflow>
    <suprpcol>0</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid>_RU901HXTS</uniqueid>
    <timestamp>697138784</timestamp>
    <objtype>8</objtype>
    <objcode>0</objcode>
    <name></name>
    <expr><![CDATA[DateTime()]]></expr>
    <vpos>13854.167</vpos>
    <hpos>5000.000</hpos>
    <height>1875.000</height>
    <width>16770.833</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment><![CDATA[ ]]></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar>C</fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>0</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>-1</fillred>
    <fillgreen>-1</fillgreen>
    <fillblue>-1</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface><![CDATA[Arial]]></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>10</fontsize>
    <mode>1</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>true</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>2</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>1</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>true</supalways>
    <supovflow>false</supovflow>
    <suprpcol>3</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid>_RU902ASYP</uniqueid>
    <timestamp>697138775</timestamp>
    <objtype>8</objtype>
    <objcode>0</objcode>
    <name></name>
    <expr><![CDATA[TheHeader]]></expr>
    <vpos>2291.667</vpos>
    <hpos>5000.000</hpos>
    <height>1875.000</height>
    <width>70000.000</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment><![CDATA[TheHeader (header)]]></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar>C</fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>0</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>-1</fillred>
    <fillgreen>-1</fillgreen>
    <fillblue>-1</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface><![CDATA[Arial]]></fontface>
    <fontstyle>1</fontstyle>
    <fontsize>10</fontsize>
    <mode>1</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>true</stretch>
    <stretchtop>false</stretchtop>
    <top>true</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>2</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>1</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>true</supalways>
    <supovflow>false</supovflow>
    <suprpcol>3</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid>_RU902BXJ1</uniqueid>
    <timestamp>697138780</timestamp>
    <objtype>8</objtype>
    <objcode>0</objcode>
    <name></name>
    <expr><![CDATA[TheText]]></expr>
    <vpos>7708.333</vpos>
    <hpos>5000.000</hpos>
    <height>1875.000</height>
    <width>70000.000</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment><![CDATA[ ]]></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar>C</fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>0</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>-1</fillred>
    <fillgreen>-1</fillgreen>
    <fillblue>-1</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface><![CDATA[Arial]]></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>10</fontsize>
    <mode>1</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>true</float>
    <stretch>true</stretch>
    <stretchtop>false</stretchtop>
    <top>false</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>2</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>1</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>true</supalways>
    <supovflow>false</supovflow>
    <suprpcol>3</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid>_RU903HYT2</uniqueid>
    <timestamp>614010044</timestamp>
    <objtype>6</objtype>
    <objcode>0</objcode>
    <name></name>
    <expr></expr>
    <vpos>4583.333</vpos>
    <hpos>5000.000</hpos>
    <height>104.167</height>
    <width>70104.167</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar></fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>-1</penred>
    <pengreen>-1</pengreen>
    <penblue>-1</penblue>
    <fillred>-1</fillred>
    <fillgreen>-1</fillgreen>
    <fillblue>-1</fillblue>
    <pensize>1</pensize>
    <penpat>8</penpat>
    <fillpat>0</fillpat>
    <fontface></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>0</fontsize>
    <mode>0</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>true</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>true</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>1</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>0</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>true</supalways>
    <supovflow>false</supovflow>
    <suprpcol>3</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid>_RU903ICYO</uniqueid>
    <timestamp>614010055</timestamp>
    <objtype>6</objtype>
    <objcode>0</objcode>
    <name></name>
    <expr></expr>
    <vpos>13437.500</vpos>
    <hpos>5000.000</hpos>
    <height>104.167</height>
    <width>70104.167</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar></fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>-1</penred>
    <pengreen>-1</pengreen>
    <penblue>-1</penblue>
    <fillred>-1</fillred>
    <fillgreen>-1</fillgreen>
    <fillblue>-1</fillblue>
    <pensize>1</pensize>
    <penpat>8</penpat>
    <fillpat>0</fillpat>
    <fontface></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>0</fontsize>
    <mode>0</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>true</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>1</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>0</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>true</supalways>
    <supovflow>false</supovflow>
    <suprpcol>3</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid>_09O0XZLM4</uniqueid>
    <timestamp>753231709</timestamp>
    <objtype>8</objtype>
    <objcode>0</objcode>
    <name></name>
    <expr><![CDATA[x3i('Page') + " " + Transform(_PageNo)]]></expr>
    <vpos>13854.167</vpos>
    <hpos>65416.667</hpos>
    <height>1875.000</height>
    <width>9687.500</width>
    <style><![CDATA[J]]></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment><![CDATA[ ]]></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar>C</fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>0</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>255</fillred>
    <fillgreen>255</fillgreen>
    <fillblue>255</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface><![CDATA[Arial]]></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>10</fontsize>
    <mode>0</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>true</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>1</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>true</supalways>
    <supovflow>false</supovflow>
    <suprpcol>3</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid></uniqueid>
    <timestamp>0</timestamp>
    <objtype>23</objtype>
    <objcode>0</objcode>
    <name></name>
    <expr></expr>
    <vpos>16.000</vpos>
    <hpos>8.000</hpos>
    <height>12.000</height>
    <width>9.000</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar></fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>4</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>0</fillred>
    <fillgreen>0</fillgreen>
    <fillblue>0</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface><![CDATA[Courier New]]></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>10</fontsize>
    <mode>0</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>false</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>0</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>false</supalways>
    <supovflow>false</supovflow>
    <suprpcol>0</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid></uniqueid>
    <timestamp>0</timestamp>
    <objtype>23</objtype>
    <objcode>0</objcode>
    <name></name>
    <expr></expr>
    <vpos>16.000</vpos>
    <hpos>6.000</hpos>
    <height>13.000</height>
    <width>35.000</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar></fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>3</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>0</fillred>
    <fillgreen>0</fillgreen>
    <fillblue>0</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface><![CDATA[Arial]]></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>10</fontsize>
    <mode>0</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>false</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>0</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>false</supalways>
    <supovflow>false</supovflow>
    <suprpcol>0</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid></uniqueid>
    <timestamp>0</timestamp>
    <objtype>23</objtype>
    <objcode>0</objcode>
    <name></name>
    <expr></expr>
    <vpos>16.000</vpos>
    <hpos>6.000</hpos>
    <height>13.000</height>
    <width>35.000</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar></fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>3</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>0</fillred>
    <fillgreen>0</fillgreen>
    <fillblue>0</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface><![CDATA[Arial]]></fontface>
    <fontstyle>1</fontstyle>
    <fontsize>10</fontsize>
    <mode>0</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>false</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>0</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>false</supalways>
    <supovflow>false</supovflow>
    <suprpcol>0</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid></uniqueid>
    <timestamp>0</timestamp>
    <objtype>25</objtype>
    <objcode>0</objcode>
    <name><![CDATA[dataenvironment]]></name>
    <expr><![CDATA[Top = 0
Left = 0
Width = 0
Height = 0
DataSource = .NULL.
Name = "Dataenvironment"
]]></expr>
    <vpos>0</vpos>
    <hpos>0</hpos>
    <height>0</height>
    <width>0</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar></fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>0</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>0</fillred>
    <fillgreen>0</fillgreen>
    <fillblue>0</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>0</fontsize>
    <mode>0</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>false</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>0</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>false</supalways>
    <supovflow>false</supovflow>
    <suprpcol>0</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
</VFPData>
		ENDTEXT
		lcText = ALLTRIM(lcText)
        STRTOFILE( STRCONV(lcText,9),lcFileName,0)   && Support for special chars in logs (Ñ,á,é,í,ó,ú,etc). FDBOZZO. 2014/6/7
		RETURN lcFileName
		***************************************************
	ENDPROC
	***************************************************


	***************************************************
	PROCEDURE INIT
		***************************************************
		LPARAMETERS tcText AS STRING, ;
			tcHeader AS STRING, ;
			tcFontName AS STRING, ;
			tnFontSize AS INTEGER, ;
			tlFontBold AS Boolean, ;
			tlFontItalic AS Boolean

		SET CENTURY ON
		SET CENTURY TO
		SET CPDIALOG OFF
		SET DELETED ON
		SET EXCLUSIVE OFF
		SET HOURS TO 24
		SET MULTILOCKS ON
		SET NOTIFY OFF
		SET SAFETY OFF
		SET TALK OFF

		*
		*  create the cursor for the report
		*
    CREATE CURSOR C_TextBlock (TheText M, TheHeader C(254))
		SELECT C_TextBlock
		APPEND BLANK

		*
		*  populate the Detail band
		*
		REPLACE TheText WITH tcText

		*
		*  populate the Header band
		*
		IF VARTYPE(tcHeader) = "C" AND NOT EMPTY(tcHeader)
			REPLACE TheHeader WITH tcHeader
		ELSE
			REPLACE TheHeader WITH SPACE(0)
		ENDIF

		LOCAL lcFRXFile, llError, laError[1], lcSetDatabase, ;
			lnSelect, lcTempFile
		lcSetDatabase = SET("DATABASE")
		lnSelect = SELECT(0)
		lcTempFile = ADDBS(SYS(2023)) + "TempReportTextBlock"
		THIS.ADDPROPERTY("icTempFile",lcTempFile)
		*
		*  generate the .FRX file as an .XML file
		*
		lcFRXFile = THIS.CreateTextBlockFRX()
		XMLTOCURSOR(lcFRXFile,"Temp",512)
		SELECT Temp
		SET DATABASE TO
		*
		*  turn the .XML file/cursor into a temporary table
		*
		COPY TO (lcTempFile+".DBF")
		USE IN Temp
		ERASE (lcFRXFile)
		ERASE (lcTempFile+".FRX")   &&& just in case
		ERASE (lcTempFile+".FRT")   &&& just in case
		*
		*  turn the temporary table into an .FRX
		*
		RENAME (lcTempFile+".DBF") TO (lcTempFile+".FRX")
		RENAME (lcTempFile+".FPT") TO (lcTempFile+".FRT")
		ERASE (lcTempFile+".DBF")   &&& just in case
		ERASE (lcTempFile+".FPT")   &&& just in case
		*
		*  open the .FRX as a table so we can update fields
		*
		USE (lcTempFile+".FRX") IN 0 ALIAS TempReport
		SELECT TempReport

		*
		*  update the FontName attribute for all objects
		*
		IF VARTYPE(tcFontName) = "C" AND NOT EMPTY(tcFontName)
			REPLACE ALL FontFace WITH tcFontName FOR NOT EMPTY(FontFace)
		ENDIF

		*
		*  update the other font attributes of the Detail
		*  Band object in the report form, if passed
		*
		LOCATE FOR "THETEXT" $ UPPER(EXPR)
		IF VARTYPE(tnFontSize) = "N" AND tnFontSize > 3
			REPLACE FONTSIZE WITH tnFontSize
		ENDIF
		REPLACE FontStyle WITH 0
		DO CASE
		CASE VARTYPE(tlFontBold) = "L" AND tlFontBold ;
				AND VARTYPE(tlFontItalic) = "L" AND tlFontItalic
			REPLACE FontStyle WITH 3
		CASE VARTYPE(tlFontItalic) = "L" AND tlFontItalic
			REPLACE FontStyle WITH 2
		CASE VARTYPE(tlFontBold) = "L" AND tlFontBold
			REPLACE FontStyle WITH 1
		ENDCASE
		*
		*  close it so we can run the report from the .FRX
		*
		USE IN TempReport

		SELECT C_TextBlock

		llError = .F.
		TRY
			REPORT FORM (lcTempFile+".FRX") NOCONSOLE TO PRINTER PROMPT
		CATCH
			llError = .T.
		ENDTRY
		IF llError
			AERROR(laError)
			MESSAGEBOX("Unable to print " + ;
				IIF(VARTYPE(tcHeader)="C" AND NOT EMPTY(tcHeader),ALLTRIM(tcHeader),SPACE(0)) + ;
				" because of this VFP error:" + ;
				CHR(13) + ;
				laError[2], ;
				48, ;
				"Unable to print")
		ENDIF

		USE IN C_TextBlock

		ERASE (lcTempFile+".FRX")
		ERASE (lcTempFile+".FRT")

		SET DATABASE TO &lcSetDatabase
		SELECT (lnSelect)
		***************************************************
	ENDPROC
	***************************************************


	***************************************************
	PROCEDURE DESTROY
		***************************************************
		USE IN SELECT("C_TextBlock")
		ERASE (THIS.icTempFile+".FRX")
		ERASE (THIS.icTempFile+".FRT")
		DODEFAULT()
	ENDPROC


ENDDEFINE
