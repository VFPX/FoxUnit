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

RETURN CREATEOBJECT("FxuResultData")

**********************************************************************
DEFINE CLASS FxuResultData AS FxuCustom OF FxuCustom.prg
**********************************************************************

	#IF .F.
		LOCAL THIS AS FxuResultData OF FxuResultData.prg
	#ENDIF

	ioDataMaintenance = .NULL.
	icDataPath		  = CURDIR()
	icResultsTable	  = "FXUResults"
	ioFileIO		  = .NULL.
	ioFxuInstance	  = .NULL.

********************************************************************
	FUNCTION INIT(toFxuInstance, tcResultsTable)
********************************************************************

	IF VARTYPE(m.toFxuInstance)!="O" OR ISNULL(m.toFxuInstance)
		ERROR 1924, "m.toFxuInstance"
		RETURN .F.
	ENDIF

	THIS.icResultsTable	= EVL(m.tcResultsTable, THIS.icResultsTable)
	THIS.icResultsTable	= JUSTSTEM(THIS.icResultsTable)
	THIS.ioFxuInstance	= m.toFxuInstance
	THIS.icDataPath = ADDBS(m.toFxuInstance.DataPath)

	SET DELETED ON
	THIS.ioDataMaintenance = THIS.ioFxuInstance.FxuNewObject("FxuDataMaintenance", THIS.icResultsTable, THIS.icDataPath)	&& FDBOZZO
	THIS.OpenDataInit()

	THIS.ioFileIO = THIS.ioFxuInstance.FxuNewObject("FXUFileIO")

********************************************************************
	ENDFUNC
********************************************************************

********************************************************************
	FUNCTION OpenDataInit
********************************************************************

	LOCAL loDataMaintenance AS FxuDataMaintenance OF FxuDataMaintenance.prg

	m.loDataMaintenance = THIS.ioDataMaintenance

	IF !FILE(THIS.icDataPath + FORCEEXT(THIS.icResultsTable, "DBF"))
		m.loDataMaintenance.CreateNewTestResultTable(THIS.icDataPath, THIS.icResultsTable)
	Else
		m.loDataMaintenance.ReIndexResultsTable(.T.)
	ENDIF

	m.loDataMaintenance.OpenResultsTable(.F.)

	RETURN


********************************************************************
	ENDFUNC
********************************************************************

********************************************************************
	FUNCTION LogResult(toTestResult AS FxuTestResult OF FxuTestResult.prg)
********************************************************************

	LOCAL lcPkExpression, lnSecondsElapsed
	LOCAL lcFailureErrorDetails, lcMessages, lcErrorDetails
	Local lcExpected, lcActual

	m.lnSecondsElapsed		= THIS.CalculateElapsed(m.toTestResult.inCurrentStartSeconds, m.toTestResult.inCurrentEndSeconds)
	m.lcFailureErrorDetails	= m.toTestResult.icFailureErrorDetails
	m.lcMessages			= m.toTestResult.icMessages
	m.lcExpected 			= m.toTestResult.icExpected
	m.lcActual				= m.toTestResult.icActual

	m.lcErrorDetails = SPACE(0)
	m.lcPkExpression = PADR(UPPER(m.toTestResult.icCurrentTestClass), LENC(EVALUATE(THIS.icResultsTable + ".TClass"))) + ;
		PADR(UPPER(m.toTestResult.icCurrentTestName), LENC(EVALUATE(THIS.icResultsTable + ".TName")))

	UPDATE  (THIS.icResultsTable) ;
		SET ;
		Success = m.toTestResult.ilCurrentResult, ;
		TLastRun = DATETIME(), ;
		TElapsed = m.lnSecondsElapsed,  ;
		Fail_Error = m.lcFailureErrorDetails, ;
		MESSAGES = m.lcMessages, ;
		Expected = m.lcExpected, ;
		Actual = m.lcActual, ;
		TRUN = .T. ;
		WHERE UPPER(TClass) + UPPER(TName) == m.lcPkExpression


********************************************************************
	ENDFUNC
********************************************************************

********************************************************************
	FUNCTION OpenResults
********************************************************************

	IF !USED(THIS.icResultsTable)
		USE (THIS.icDataPath + THIS.icResultsTable) IN 0 SHARED ORDER tclname
	ENDIF


********************************************************************
	ENDFUNC
********************************************************************

********************************************************************
	FUNCTION LoadTestCaseClass(tcTestClassFile)
********************************************************************
* EHW/02/27/2005
	IF EMPTY(m.tcTestClassFile)
		LOCAL loFrmLoadClass AS fxuFrmLoadClass OF fxu.vcx
		LOCAL i
		m.loFrmLoadClass = NEWOBJECT("fxuFrmLoadClass", "fxu.vcx", "", THIS.icDataPath)	&& FDBOZZO. 01/06/2014. DataPath Fix
		m.loFrmLoadClass.SHOW
		IF m.loFrmLoadClass.ilCancel = .F.
			WITH m.loFrmLoadClass.lstFiles
				FOR m.i = 1 TO .LISTCOUNT
					IF m.loFrmLoadClass.lstFiles.SELECTED[m.i]
						THIS.LoadTestCaseClassStep2(ADDBS(m.loFrmLoadClass.icfxuselectedtestdirectory) + .LISTITEM[m.i], .T.) && Added path to file name. HAS
					ENDIF
				NEXT
			ENDWITH
		ENDIF
		RELEASE m.loFrmLoadClass
	ELSE
		THIS.LoadTestCaseClassStep2(m.tcTestClassFile)
	ENDIF
	RETURN
	ENDFUNC

********************************************************************
	FUNCTION LoadTestCaseClassStep2(tcTestClassFile, tlNew)
********************************************************************

	LOCAL loEnumerator AS FxuTestCaseEnumerator OF FxuTestCaseEnumerator.prg

	LOCAL lcTestClassFile, lcCurdir, lcTestDirectory, ;
		lcTag, lnTClass, lnTName, lnLocation, llNew, lcTestName, lcFilter

************
* EHW/02/27/2005
	m.llNew = m.tlNew
************
	m.lcTag = ORDER(THIS.icResultsTable)
	SET ORDER TO 0 IN (THIS.icResultsTable)
	m.lnTClass	   = LENC(EVALUATE(THIS.icResultsTable + ".TCLass"))
	m.lnTName	   = LENC(EVALUATE(THIS.icResultsTable + ".TName"))
	m.lcFilter	   = FILTER(THIS.icResultsTable)	&& Save FILTER expression. FDBOZZO. 2014.06.19
	m.loEnumerator = THIS.ioFxuInstance.FxuNewObject("FxuTestCaseEnumerator", THIS.ioFxuInstance)

	IF EMPTY(m.tcTestClassFile)
		LOCAL lcTestsFolder
		IF USED(THIS.icResultsTable)
			m.lcTestsFolder = ADDBS(JUSTPATH(DBF(THIS.icResultsTable)))
		ELSE
			SET STEP ON
			m.lcTestsFolder = THIS.icDataPath
		ENDIF
		m.lcCurdir = FULLPATH(CURDIR())

		CD (m.lcTestsFolder)
		m.lcTestClassFile = GETFILE("PRG", ;
			"Test Class .PRG", ;
			"", ;
			0, ;
			"Select the Test Class .PRG whose tests (methods) you want to load into the list.")
		CD (m.lcCurdir)

		m.llNew = .T.  &&& as opposed to re-loading an existing .PRG

	ELSE

		m.tcTestClassFile = FULLPATH(m.tcTestClassFile)

		IF FILE(m.tcTestClassFile)
			m.lcTestClassFile = m.tcTestClassFile
		ENDIF

	ENDIF

	IF NOT EMPTY(m.lcTestClassFile)

		m.lcTestClassFile = THIS.ioFileIO.GetCaseSensitiveFileName(m.lcTestClassFile, .T.)
		m.lcTestClass	  = JUSTSTEM(m.lcTestClassFile)
		m.lcTestCases	  = m.loEnumerator.ReadTestNames(m.lcTestClassFile, m.lcTestClass)
		m.lnTestCases	  = ALINES(laTestCases, m.lcTestCases, .T.)
		m.cTestClassPath  = JUSTPATH(m.lcTestClassFile) && HAS
*TODO store the class path in the cursor.
		IF THIS.LoadUpTestCasesToCursor(m.lcTestClass, m.lcTestCases)
			SELECT TestCase_Curs
			GO TOP
			m.lnLocation = 0
*-- Clear FILTER temporaly on icResultsTable before INSERT/REPLACE to avoid errors. FDBOZZO. 2014.06.19
			SET FILTER TO IN (THIS.icResultsTable)
			SCAN
				m.lnLocation = m.lnLocation + 1
				m.lcTestName = TestCase_Curs.TName

				IF SEEK(PADR(UPPER(m.lcTestClass), m.lnTClass) + PADR(UPPER(m.lcTestName), m.lnTName), ;
						THIS.icResultsTable, ;
						"TCLName")
					REPLACE Location WITH m.lnLocation ;
						IN (THIS.icResultsTable)
				ELSE

					INSERT INTO (THIS.icResultsTable) ;
						(TClass, TName, TRUN, Location, TPath) ;
						VALUES ;
						(m.lcTestClass, m.lcTestName, .F., m.lnLocation, m.cTestClassPath) && Added path value. HAS
				ENDIF
				SELECT TestCase_Curs
			ENDSCAN

*  delete the records for the TestClass.PRG
*  that are no longer contained in that
*  TestClass.PRG (the developer deleted those
*  tests)
			DELETE  ;
				FROM (THIS.icResultsTable) ;
				WHERE UPPER(ALLTRIM(TClass)) == UPPER(ALLTRIM(m.lcTestClass)) ;
				AND UPPER(TName) NOT IN ;
				(SELECT  UPPER(TName) AS CurrentTests;
				FROM TestCase_Curs ;
				WHERE UPPER(ALLTRIM(TClass)) == UPPER(ALLTRIM(m.lcTestClass)))

*-- Restore FILTER, if any. FDBOZZO. 2014.06.19
			IF NOT EMPTY(m.lcFilter)
				SET FILTER TO &lcFilter. IN (THIS.icResultsTable)
			ENDIF
		ENDIF
	ENDIF

	USE IN SELECT("TestCase_Curs")
	USE IN SELECT("TheCrit")
	IF NOT EMPTY(m.lcTag)
		SET ORDER TO TAG (m.lcTag) IN (THIS.icResultsTable)
	ENDIF

	IF m.llNew AND NOT EMPTY(m.lcTestClassFile)
*
*  position the record pointer on the first
*  test in the newly-added .PRG (if any)
*
		SELECT (THIS.icResultsTable)
		LOCATE FOR UPPER(ALLTRIM(TClass)) == UPPER(ALLTRIM(m.lcTestClass))
		IF EOF()
			LOCATE
		ENDIF
	ELSE
*
*  most likely this method was called from
*  THIS.ReLoadTestCaseClass(), which has
*  its own record-pointer-repositioning logic
*
	ENDIF


********************************************************************
	ENDFUNC
********************************************************************


********************************************************************
	FUNCTION LoadUpTestCasesToCursor
********************************************************************

	LPARAMETERS lcTestClass, lcTestCases
	LOCAL ARRAY laTestCases[1]
	LOCAL lnTestCases
	m.lnTestCases = ALINES(laTestCases, m.lcTestCases)
	IF m.lnTestCases < 1
		RETURN .F.
	ENDIF

*-- FDBOZZO. 01/10/2011. Field length expansion.
*-- 	Expanded TClass C(80) to C(110) ==> So the Unit Test file name can be 'ut_libraryName__className__methodName.prg'
*-- 	Expanded TName C(100) to C(130) ==> So the method name can be 'SHOULD_DoSomething__WHEN_SomeConditions'
	CREATE CURSOR TestCase_Curs (resultid c(32), TClass c(110), TName c(130))

	FOR m.lnX = 1 TO m.lnTestCases
		INSERT INTO TestCase_Curs (TClass, TName) ;
			VALUES (m.lcTestClass, m.laTestCases(m.lnX))
	ENDFOR
	RETURN .T.


********************************************************************
	ENDFUNC
********************************************************************

********************************************************************
	FUNCTION ReloadTestCaseClasses
********************************************************************

	LOCAL lnTestClasses, lnX
	LOCAL ARRAY laTestClasses[1]
	m.laTestClasses[1] = .F.

	SELECT  DISTINCT TClass,;
		TPath ;
		FROM (THIS.icResultsTable) ;
		INTO ARRAY laTestClasses && Added TPath to query. HAS
	IF VARTYPE(m.laTestClasses[1]) == "C"
*lnTestClasses = ALEN(laTestClasses) HAS
		m.lnTestClasses = _TALLY
		FOR m.lnX = 1 TO m.lnTestClasses
			THIS.ReloadTestCaseClass(ALLTRIM(m.laTestClasses[m.lnX, 1]), ALLTRIM(m.laTestClasses[m.lnX, 2])) && Added path to call. HAS
		ENDFOR
	ENDIF
	RETURN
********************************************************************
	ENDFUNC
********************************************************************

********************************************************************
	FUNCTION ReloadTestCaseClass(tcTestClass, tcDirectory) && Added directory parameter. HAS
********************************************************************

	IF EMPTY(m.tcTestClass)
*  this can happen in some strange scenarios
		RETURN
	ENDIF
	LOCAL lcTestClassFile, lcFullPath
	m.lcTestClassFile = ALLTRIM(m.tcTestClass) + ".prg"
	m.lcFullPath = LOCFILE(ADDBS(m.tcDirectory) + m.lcTestClassFile, "prg", ;
		"Could Not Locate " + m.lcTestClassFile) && Added directory. HAS

	LOCAL lcTestClass, lcTestName
	m.lnSelect = SELECT(0)
	SELECT (THIS.icResultsTable)
	m.lcTestClass = TClass
	m.lcTestName  = TName
	THIS.LoadTestCaseClass(THIS.ioFileIO.GetCaseSensitiveFileName(m.lcFullPath, .T.))

	SELECT (THIS.icResultsTable)
	LOCATE FOR TClass == m.lcTestClass AND TName == m.lcTestName
	IF EOF()
		LOCATE FOR TClass == m.lcTestClass
		IF EOF()
			LOCATE
		ENDIF
	ENDIF
	SELECT (m.lnSelect)
********************************************************************
	ENDFUNC
********************************************************************

********************************************************************
	FUNCTION CreateNewTestCaseClass(tcTestsPath, tcTestClassPRG)
*
*  pass tcTestClassPRG BY REFERENCE if you want
*  it populated with the .PRG filename
*
********************************************************************

	m.tcTestClassPRG = SPACE(0)

	LOCAL	loFxuInstance AS fxuinstance OF "fxu.vcx", ;
		loTestClassCreator AS FxuFrmNewTestClass OF "fxu.vcx"
	m.loFxuInstance = THIS.ioFxuInstance
	m.loTestClassCreator = m.loFxuInstance.FxuNewObject("FxuFrmNewTestClass", m.loFxuInstance)
	IF VARTYPE(m.loTestClassCreator)!="O" OR ISNULL(m.loTestClassCreator)
		RETURN .F.
	ENDIF
	m.loTestClassCreator.SHOW(1)

	LOCAL lcNewTestClassName, llClassCreated
	m.llClassCreated = .F.
	m.lcNewTestClassName = m.loTestClassCreator.ClassFullName()
	m.llClassCreated	 = m.loTestClassCreator.lCreated

	DO CASE
		CASE NOT m.llClassCreated AND EMPTY(m.loTestClassCreator.icLastErrorMessage)
		CASE NOT m.llClassCreated
			MESSAGEBOX("Class not created:" + CHR(13) + ;
				m.loTestClassCreator.icLastErrorMessage, ;
				16, ;
				"Class Not Created")
		OTHERWISE
			MODIFY COMMAND (m.lcNewTestClassName)
			THIS.ioFileIO.RenameFile(m.lcNewTestClassName, m.lcNewTestClassName)
			COMPILE (m.lcNewTestClassName)
			LOCAL lnTestMethods
			m.lnTestMethods = THIS.LoadTestCaseClass(m.lcNewTestClassName)
	ENDCASE

	m.tcTestClassPRG = m.lcNewTestClassName
	RETURN m.llClassCreated
	ENDFUNC
********************************************************************

********************************************************************
	FUNCTION RemoveTestCaseClass(tcTestClass)
********************************************************************

	DELETE FROM (THIS.icResultsTable) WHERE UPPER(ALLTRIM(TClass)) == UPPER(ALLTRIM(m.tcTestClass))
	GO TOP IN (THIS.icResultsTable)
	RETURN
	ENDFUNC
********************************************************************

********************************************************************
	FUNCTION RemoveAllTestCaseClasses()
********************************************************************
	DELETE FROM (THIS.icResultsTable)
	GO TOP IN (THIS.icResultsTable)
	RETURN
	ENDFUNC
********************************************************************


********************************************************************
	PROCEDURE AddNewTest(tcTestClass, toFXUForm, tcPath, tcTestCode, tlNoEdit) 
********************************************************************
*
*  add this new custom test Method at the bottom,
*  just before the ENDDEFINE, and open the program
*  editor with the cursor positioned on this new Method
*
	LOCAL laClasses[1], ;
		laLines[1], ;
		laNewLines[1], ;
		lcLine AS STRING, ;
		lcTestClass AS STRING, ;
		lcText AS STRING, ;
		llFoxUnitForm AS Boolean, ;
		lnInsertLine AS NUMBER, ;
		lnLines AS NUMBER, ;
		lnNewMethodLine AS NUMBER, ;
		xx
	IF AT('\', m.tcTestClass)=0
		m.lcTestClass = ADDBS(m.tcPath) + FORCEEXT(m.tcTestClass, "PRG") && Added Path. HAS
	ELSE
		m.lcTestClass=m.tcTestClass
	ENDIF 
	IF NOT FILE(m.lcTestClass)
		MESSAGEBOX("Unable to locate " + CHR(13) + ;
			m.tcTestClass + CHR(13) + ;
			"typically because it is not in the VFP " + ;
			"path at the moment -- you should include " + ;
			"the folder containing FoxUnit test classes (.PRGs) " + ;
			"in your VFP path before starting FoxUnit.", ;
			16, ;
			"Please Note")
		RETURN .F.
	ELSE
		m.lcTestClass = THIS.ioFileIO.GetCaseSensitiveFileName(FULLPATH(m.lcTestClass), .T.)
	ENDIF

	IF THIS.IsFileReadOnly(m.lcTestClass)
		MESSAGEBOX(m.lcTestClass + " is marked ReadOnly, " + ;
			"typically because it is currently not " + ;
			"checked out of your Source Control provider.", ;
			48, "Please Note")
		RETURN .F.
	ENDIF

	m.lnLines	   = ALINES(laLines, FILETOSTR(m.lcTestClass))
	m.lnInsertLine = -1
	FOR m.xx = 1 TO m.lnLines
		m.lcLine = UPPER(ALLTRIM(m.laLines[m.xx]))
		IF UPPER(ALLTRIM(CHRTRAN(m.lcLine, CHR(9), SPACE(0)))) == "ENDDEFINE"
			m.lnInsertLine = m.xx
			EXIT
		ENDIF
	ENDFOR
	IF m.lnInsertLine < 0
		MESSAGEBOX("Unable to insert new test method " + ;
			"into " + m.tcTestClass + "." + ;
			CHR(13) + CHR(13) + ;
			m.tcTestClass + " will simply be opened " + ;
			"in the program editor.", ;
			48, "Please Note")
		m.lnNewMethodLine = 1
	ELSE
* insert these 8 lines:
		TEXT TO m.lcText NOSHOW && Removed the annoying asterisks. HAS


  FUNCTION testNewTest
	* 1. Change the name of the test to reflect its purpose. Test one thing only.
	* 2. Implement the test by removing these comments and the default assertion and writing your own test code.
  RETURN This.AssertNotImplemented()

  ENDFUNC

		ENDTEXT

*BUG This line puts the function in the wrong place for me. HAS
*lnInsertLine = m.lnInsertLine - 2
		m.lnInsertLine = m.lnInsertLine - 1
		IF NOT EMPTY(tcTestCode)
			m.lcText = tcTestCode
		ENDIF
		m.lcText = CHR(13) + CHR(10) + m.lcText + CHR(13) + CHR(10)
		ALINES(laNewLines, m.lcText)
		FOR EACH m.lcLine IN m.laNewLines
			DIMENSION m.laLines[ALEN(m.laLines, 1) + 1]
			AINS(m.laLines, m.lnInsertLine)
			m.laLines[m.lnInsertLine] = m.lcLine
			IF UPPER(ALLTRIM(CHRTRAN(m.lcLine, CHR(9), SPACE(0)))) = "FUNCTION"
				m.lnNewMethodLine = m.lnInsertLine
			ENDIF
			m.lnInsertLine = m.lnInsertLine + 1
		ENDFOR

*
*  turn laLines into the new m.tcTestClass .PRG
*
		ERASE (m.lcTestClass)
		FOR EACH m.lcLine IN m.laLines
			STRTOFILE(m.lcLine + CHR(13) + CHR(10), m.lcTestClass, .T.)
		ENDFOR
	ENDIF
	RELEASE m.laLines, m.laNewLines
	IF VARTYPE(m.toFXUForm) = "O" ;
			AND UPPER(toFXUForm.BASECLASS) == "FORM"
		ACLASS(laClasses, m.toFXUForm)
		m.llFoxUnitForm = ASCAN(m.laClasses, "frmFoxUnit", 1, -1, 1, 15) > 0
		IF m.llFoxUnitForm
*
*  set a flag so that FoxUnit.SCX/Activate
*  will reload this .PRG when it activates
*  after you are done in m.lcTestClass
*    MODIFY CLASS frmFoxUnit OF FXU.VCX METHOD Activate
*
			toFXUForm.ADDPROPERTY("ilReloadCurrentClassOnActivate", .T.)
		ENDIF
	ENDIF

*
*  start the program editor on the indicated line,
*  at the spot where the developer needs to specify
*  the method name
*
	IF NOT tlNoEdit
		EDITSOURCE(m.lcTestClass, m.lnNewMethodLine)
		KEYBOARD "{HOME}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{SHIFT+END}" PLAIN CLEAR
	ENDIF 
********************************************************************
	ENDPROC
********************************************************************


********************************************************************
	PROCEDURE ModifyExistingTest(tcTestClass, tcTestName, toFXUForm, tcPath) && Added Path parameter. HAS
********************************************************************
*
*  do a MODIFY COMMAND with the cursor positioned
*  on the indicated tcTestName method in tcTestClass
*
	LOCAL lcTestClass
	m.lcTestClass = ADDBS(m.tcPath) + FORCEEXT(m.tcTestClass, "PRG") && Added Path. HAS
	IF NOT FILE(m.lcTestClass)
		MESSAGEBOX("Unable to locate " + CHR(13) + ;
			m.tcTestClass + CHR(13) + ;
			"typically because it is not in the VFP " + ;
			"path at the moment -- you should include " + ;
			"the folder containing FoxUnit test classes (.PRGs) " + ;
			"in your VFP path before starting FoxUnit.", ;
			16, ;
			"Please Note")
		RETURN .F.
	ELSE
		m.lcTestClass = THIS.ioFileIO.GetCaseSensitiveFileName(FULLPATH(m.lcTestClass), .T.)

	ENDIF
	IF THIS.IsFileReadOnly(m.lcTestClass)
		MESSAGEBOX(m.lcTestClass + " is marked ReadOnly, " + ;
			"typically because it is currently not " + ;
			"checked out of your Source Control provider." + ;
			CHR(13) + CHR(13) + ;
			m.lcTestClass + " will be opened in the VFP " + ;
			"program editor, but it is ReadOnly, and you " + ;
			"will not be able to make any changes.", ;
			48, "Please Note")
	ENDIF
*
*  find the FUNCTION/PROCEDURE <m.tcTestName> line
*
	LOCAL laLines[1], lnCursorLine, lnLines, xx, lcLine, ;
		lcTestName
	m.lcTestName   = UPPER(ALLTRIM(m.tcTestName))
	m.lnLines	   = ALINES(laLines, FILETOSTR(m.lcTestClass))
	m.lnCursorLine = -1
	FOR m.xx = 1 TO m.lnLines
		m.lcLine = UPPER(ALLTRIM(m.laLines[m.xx]))
		m.lcLine = CHRTRAN(m.lcLine, CHR(9), SPACE(0))
		m.lcLine = CHRTRAN(m.lcLine, "()", SPACE(0))
		IF m.lcLine == "FUNCTION " + m.lcTestName ;
				OR ;
				m.lcLine == "PROCEDURE " + m.lcTestName
			m.lnCursorLine = m.xx
			EXIT
		ENDIF
	ENDFOR
	RELEASE m.laLines
	IF m.lnCursorLine < 0
		MESSAGEBOX("Unable to locate the " + m.lcTestName + ;
			"method -- " + m.lcTestClass + " will be " + ;
			"opened in the program editor with the " + ;
			"cursor positioned whereever it was last " + ;
			"time.", ;
			48, "Please Note")
		m.lnCursorLine = 0
	ENDIF

	IF VARTYPE(m.toFXUForm) = "O" ;
			AND UPPER(m.toFXUForm.BASECLASS) == "FORM"
		LOCAL llFoxUnitForm, laClasses[1]
		ACLASS(laClasses, m.toFXUForm)
		m.llFoxUnitForm = ASCAN(m.laClasses, "frmFoxUnit", 1, -1, 1, 15) > 0
		IF m.llFoxUnitForm
*
*  set a flag so that FoxUnit.SCX/Activate  will reload this .PRG when it activates
*  after you are done in m.lcTestClass
*    MODIFY CLASS frmFoxUnit OF FXU.VCX METHOD Activate
*
			m.toFXUForm.ADDPROPERTY("ilReloadCurrentClassOnActivate", .T.)
		ENDIF
	ENDIF
*
*  start the program editor on the indicated line
*
	EDITSOURCE(m.lcTestClass, m.lnCursorLine)
********************************************************************
	ENDPROC
********************************************************************


********************************************************************
	FUNCTION SetAllTestsNotRun
	UPDATE (THIS.icResultsTable) SET TRUN = .F.
	ENDFUNC
********************************************************************

********************************************************************
	FUNCTION CalculateElapsed(tnStartSeconds, tnEndSeconds)
********************************************************************

	IF m.tnEndSeconds < m.tnStartSeconds
		m.tnEndSeconds = m.tnEndSeconds + 126000
	ENDIF
	m.lnElapsedSeconds = m.tnEndSeconds - m.tnStartSeconds
	RETURN m.lnElapsedSeconds
	ENDFUNC
********************************************************************

********************************************************************
	FUNCTION DESTROY
********************************************************************
	USE IN SELECT(THIS.icResultsTable)
	THIS.ioDataMaintenance = .NULL.
	ENDFUNC
********************************************************************

********************************************************************
	FUNCTION ReceiveResultsNotification(toTestResult AS TestResult OF TestResult.prg)
	THIS.LogResult(m.toTestResult)
	ENDFUNC
********************************************************************


********************************************************************
	FUNCTION IsFileReadOnly(tcFileName)
********************************************************************
*
*  pass tcFileName with a fully-qualified path
*
	LOCAL lcDir
	m.lcDir = JUSTPATH(m.tcFileName)
	IF NOT DIRECTORY(m.lcDir)
*
*  either the full path has not been passed, or the
*  indicated directory does not exist
*
		RETURN .F.
	ENDIF

	LOCAL lcCurdir, lcJustFile, llReadOnly, laFiles[1]
	m.lcCurdir	 = FULLPATH(CURDIR())
	m.lcJustFile = JUSTFNAME(m.tcFileName)

	CD (m.lcDir)

*
*  since we know the full name of the file, we can
*  pass that as the 2nd cFileSkeleton parameter to
*  ADIR(), so that that file will be the only one
*  found by ADIR()
*
	IF ADIR(laFiles, m.lcJustFile) = 0
		m.llReadOnly = .F.
	ELSE
		m.llReadOnly = "R" $ m.laFiles[1, 5]
	ENDIF
*
*  ...making this routine faster than if we used a
*  more traditional loop thru all the files

	CD (m.lcCurdir)
	RETURN m.llReadOnly

********************************************************************
	ENDFUNC
********************************************************************

********************************************************************
	FUNCTION GetCaseSensitiveFileName(tcFullPathToFile, tlReturnFullPath)
********************************************************************

	m.tlReturnFullPath = !EMPTY(m.tlReturnFullPath)

	LOCAL loFs AS Scripting.FileSystemObject
	LOCAL loFile AS Scripting.FILE
	LOCAL lcCaseSensitiveFileName

	m.loFs	 = CREATEOBJECT("Scripting.FileSystemObject")
	m.loFile = oFs.GETFILE(m.tcFullPathToFile)

	IF m.tlReturnFullPath
		m.lcCaseSensitiveFileName = oFile.PATH
	ELSE
		m.lcCaseSensitiveFileName = oFile.NAME
	ENDIF
	RELEASE m.loFile
	RELEASE m.loFs
	RETURN m.lcCaseSensitiveFileName
	ENDFUNC
********************************************************************

********************************************************************
	FUNCTION RenameFile(tcOldFileName, tcNewFileName)
********************************************************************
* Note that the file name parameters require the full path
	LOCAL loFs AS Scripting.FileSystemObject
	m.loFs.MoveFile(m.tcOldFileName, m.tcNewFileName)
	RELEASE m.loFs
	ENDFUNC
********************************************************************



*% ES 5/23/2008 Add method to go through all classes in a class library and add tests for each class that has code
********************************************
PROCEDURE AddTestsFromClassLib ;
	(tcTestClass, toFXUForm, tcPath, tcClassLib)
********************************************
	LOCAL cParams, cLine, nMemoLines, cMethod, iLine, cTestName, cParamsDeclared

	SELECT 0
	USE (tcClassLib) NOUPDATE ALIAS crsClasses
	SCAN FOR NOT EMPTY(methods)
		nMemoLines=MEMLINES(methods)
		FOR iLine = 1 TO nMemoLines
			cLine = MLINE(methods,iLine)
* Start of a function?
			IF cLine = "PROCEDURE" OR cLine = "FUNCTION"
* Get function's signature
				cParams = MLINE(methods,iLine+1)
* Remove the word 'Parameters'
				IF "PARAMETERS" $ cParams
					cParams = STRTRAN(cParams, "LPARAMETERS ","")
					cParams = STRTRAN(cParams, "PARAMETERS ","")
					cParametersDeclared= "LOCAL " + cParams
				ELSE
					cParams = ""
					cParametersDeclared=""
				ENDIF
* Merge ClassName/FunctionName as TestName
				cMethod = GETWORDNUM(cLine,2)
				cTestName = ALLTRIM(PROPER(crsClasses.objName)) +PROPER(cMethod) +"_Test"
* Create the test template for this method
				TEXT TO cTestCode TEXTMERGE NOSHOW
FUNCTION <<cTestName>>
* This unit test was created automatically from FoxUnit. You need to tweak it.
LOCAL oToTest AS <<crsClasses.objName>> OF <<tcClassLib>>, xResult, xExpectedValue
<<cParametersDeclared>>
This.assertNotImplemented("<<crsClasses.objName>>.<<cMethod>>(<<cParams>>))")
ENDFUNC
				ENDTEXT
				THIS.AddNewTest(tcTestClass, toFXUForm, tcPath, cTestCode, .T.)
			ENDIF
		NEXT
	ENDSCAN
	USE IN SELECT("crsClasses")
* Modify the code
	THIS.ModifyExistingTest(tcTestClass, cTestName, toFXUForm, tcPath)
ENDPROC

**********************************************************************
ENDDEFINE && CLASS
**********************************************************************
