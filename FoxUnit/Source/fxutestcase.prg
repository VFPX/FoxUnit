***********************************************************************
*	FoxUnit is Copyright (c) 2004 - 2005, Visionpace
*	All rights reserved.
*
*	Redistribution and use in source and binary forms, with or 
*	without modification, are permitted provided that the following 
*	conditions are met:
*
*		*	Redistributions of source code must retain the above
*			copyright notice, this list of conditions and the 
*			following disclaimer.
*
*		*	Redistributions in binary form must reproduce the above 
*			copyright notice, this list of conditions and the 
*			following disclaimer in the documentation and/or other 
*			materials provided with the distribution. 
*			
*		*	The names Visionpace and Vision Data Solutions, Inc. 
*			(including similar derivations thereof) as well as
*			the names of any FoxUnit contributors may not be used 
*			to endorse or promote products which were developed
*			utilizing the FoxUnit software unless specific, prior, 
*			written permission has been obtained.
*
*	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
*	"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
*	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
*	FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
*	COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
*	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
*	BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
*	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
*	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
*	LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
*	ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
*	POSSIBILITY OF SUCH DAMAGE.  
***********************************************************************
LPARAMETERS toTestResult as FxuTestResult of FxuTestResult.prg

RETURN CREATEOBJECT("FxuTestCase",toTestResult)

**********************************************************************
DEFINE CLASS FxuTestCase As FxuTest OF FxuTest.Prg
**********************************************************************

	#IF .f.
		LOCAL this as FxuTestCase OF FxuTestCase.prg
	#ENDIF
	
	icCurrentTest = ""
	ioTestResult = .NULL.
	ioFxuInstance = .NULL.
	ilAllowDebug = .f.
	ilQueryTests = .f.
	ilSuccess = .t.
	inReturnCode = 0
	ioAssert = .f.
	icTestPrefix = "TEST"
	inTestCountsAs = 1
	HIDDEN ilTestingModalForm 

	********************************************************************
	FUNCTION INIT(toTestResult, toFxuInstance)
	********************************************************************
		
		IF VARTYPE(m.toFxuInstance)!="O" OR ISNULL(m.toFxuInstance)
			IF VARTYPE(goFoxUnitForm.ioFxuInstance)='O'
				m.toFxuInstance=goFoxUnitForm.ioFxuInstance
			ELSE
				ERROR 1924, "m.toFxuInstance"
				RETURN .F.
			ENDIF			
		ENDIF
		this.ioFxuInstance=m.toFxuInstance
		
		ilTestingModalForm = .f.
		
		IF VERSION(5) < 900
			LOCAL laStackInfo[1]
			IF ASTACKINFO(laStackInfo) > 0
				IF ASCAN(laStackInfo,"FXUInheritsFromFXUTestCase",1,-1,3,15)>0
				*
				*  don't proceed with this method if this 
				*  object is being instantiated from 
				*  FXUInheritsFromFXUTestCase.PRG, to test
				*  its inheritance
				*
				*  MODIFY COMMAND FXUInheritsFromFXUTestCase
				*
				RETURN .t.
				ENDIF
				RELEASE laStackInfo
			ENDIF
		ENDIF

	
		IF VARTYPE(toTestResult) != "O"
			this.ilQueryTests = .t.
		ELSE
			IF UPPER(toTestResult.Class) == "FXUTESTRESULT"
				this.ioTestResult = toTestResult
			ELSE
				RETURN .f.
			ENDIF
		ENDIF
		
		this.icCurrentTest = this.ioTestResult.icCurrentTestName
			
		RETURN .t.
	
	********************************************************************
	ENDFUNC
	********************************************************************

	********************************************************************
	FUNCTION Run( ;
		 tu01, tu02, tu03, tu04, tu05, tu06, tu07, tu08, tu09, tu10 ;
		,tu11, tu12, tu13, tu14, tu15, tu16, tu17, tu18, tu19, tu20 ;
	)
	********************************************************************
		*--------------------------------------------------------------------------------------
		* Pass all parameters on to the test
		*--------------------------------------------------------------------------------------
		Local lcParam
		lcParam = Left ( ;
			 " tu01,tu02,tu03,tu04,tu05,tu06,tu07,tu08,tu09,tu10" ;
			+",tu11,tu12,tu13,tu14,tu15,tu16,tu17,tu18,tu19,tu20" ;
			,Pcount()*5 ;
		)
	
		LOCAL loEx as Exception
		
		this.ioAssert = .f.		

		this.ioAssert = this.ioFxuInstance.FxuNewObject("FxuAssertions", this.ioFxuInstance)
		this.ioAssert.ioTestResult = this.ioTestResult
		
*		this.ioTestResult.icCurrentStartTime = timestamp()
		this.ioTestResult.inCurrentStartSeconds = SECONDS()
		
		IF this.ilAllowDebug
			this.RunWithSetupTeardownDebugging()
		ELSE

		*--------------------------------------------------------------------------------------
		* Test cases are executed in a private datasession. A new data session is used for
		* every test to avoid cross-pollution of cursor or basic settings between runs. A 
		* typical problem is that a method relies on a cursor to be open that is opened in a 
		* previous test. The second test will fail when executed on its own, but pass when
		* all tests are run - so most of the time.
		*--------------------------------------------------------------------------------------
		Local loSession, lnDS
		loSession = CreateObject("Session")
		lnDS = Set("DataSession")
		Set Datasession To loSession.DataSessionID

			TRY
				
				this.SetUp()
				this.RunTest(&lcParam)
				*this.TearDown()
			
			CATCH TO loEx
			
				LOCAL ARRAY laStackInfo[1,1]
				=ASTACKINFO(laStackInfo)
				this.HandleException(loEx,@laStackInfo,.f.)
				
			FINALLY
			
				TRY
				
					this.TearDown()
				
				CATCH TO loEx
				
					LOCAL ARRAY laStackInfo[1,1]
					=ASTACKINFO(laStackInfo)
					this.HandleException(loEx,@laStackInfo,.t.)
				
				Finally 
					Set Datasession To m.lnDS
					Release loSession
					
				ENDTRY 
			
			ENDTRY

		ENDIF
		
		this.ioTestResult.inLastKey = LASTKEY()		
		this.ioTestResult.inCurrentEndSeconds = SECONDS()
		This.ioTestResult.IncreaseTestsCompleted (This.inTestCountsAs)
		this.PostTearDown()
	
	********************************************************************
	ENDFUNC
	********************************************************************

	********************************************************************
	PROTECTED FUNCTION RunWithSetupTeardownDebugging
	********************************************************************
	
		LOCAL loEx as Exception
	
		this.Setup()
	
		TRY
		
			this.RunTest()	
		
		CATCH TO loEx
		
			LOCAL ARRAY laStackInfo[1,1]
			=ASTACKINFO(laStackInfo)
			this.HandleException(loEx,@laStackInfo)
		
		ENDTRY
		
		this.TearDown()
		
		RETURN 
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	
	********************************************************************
	FUNCTION SetForModalFormTest()
	********************************************************************

		
		IF VARTYPE(goFoxUnitForm) == "O" AND goFoxUnitForm.Visible
		
			this.ilTestingModalForm = .t.
			goFoxUnitForm.Visible = .f.
		
		ENDIF 
		

	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	
	********************************************************************
	HIDDEN FUNCTION PostTearDown()
	********************************************************************
	
		IF this.ilTestingModalForm
		
			IF VARTYPE(goFoxUnitForm) == "O" AND !goFoxUnitForm.Visible
			
				goFoxUnitForm.Visible = .t.
			
			ENDIF 
		
		ENDIF 
	
	********************************************************************
	ENDFUNC
	********************************************************************

	********************************************************************
	FUNCTION SetUp() && Abstract Method
	********************************************************************
	
	
	
	********************************************************************
	ENDFUNC
	********************************************************************

	********************************************************************
	FUNCTION RunTest( ;
		 tu01, tu02, tu03, tu04, tu05, tu06, tu07, tu08, tu09, tu10 ;
		,tu11, tu12, tu13, tu14, tu15, tu16, tu17, tu18, tu19, tu20 ;
	)
	********************************************************************
	
		LOCAL lcCurrentTest

		lcCurrentTest = "this." + this.icCurrentTest + "(" + ;
			Left ( ;
				 " tu01,tu02,tu03,tu04,tu05,tu06,tu07,tu08,tu09,tu10" ;
				+",tu11,tu12,tu13,tu14,tu15,tu16,tu17,tu18,tu19,tu20" ;
				,Pcount()*5 ;
			) + ")"

		&lcCurrentTest

	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION TearDown() && Abstract Method
	********************************************************************
	
	
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION ilSuccess_Assign(tlSuccess)
	********************************************************************
	
		this.ioTestResult.ilCurrentResult = tlSuccess
		this.ilSuccess = this.ilSuccess AND tlSuccess
	
	********************************************************************
	ENDFUNC
	********************************************************************

 ********************************************************************
  * EJS 11/11/2014 Add new assertNotImplemented
  FUNCTION AssertNotImplemented(tcMessage)  
  ********************************************************************
    Return this.ioAssert.AssertNotImplemented(tcMessage)
  
  ********************************************************************
  ENDFUNC
  ********************************************************************

	
	********************************************************************
  * Swapped message and expression parameter order. HAS
	FUNCTION AssertEquals(tuExpectedValue, tuExpression, tcMessage, tuNonCaseSensitiveStringComparison)
	********************************************************************
		LOCAL llNonCaseSensitiveStringComparison
		llNonCaseSensitiveStringComparison = .f. 
		IF VARTYPE( tuNonCaseSensitiveStringComparison ) == "L"
			llNonCaseSensitiveStringComparison = tuNonCaseSensitiveStringComparison  
		ENDIF  
		RETURN This.ioAssert.AssertEquals(tcMessage, tuExpectedValue, tuExpression, llNonCaseSensitiveStringComparison)
	********************************************************************
	ENDFUNC
	********************************************************************

	********************************************************************
  * Swapped message and expression parameter order. HAS
	FUNCTION AssertTrue(tuExpression, tcMessage)
	********************************************************************
		*BSt [+] Added RETURN statement
		Return this.ioAssert.AssertTrue(tcMessage, tuExpression)
	
	********************************************************************
	ENDFUNC
	********************************************************************

  ********************************************************************
  * Swapped message and expression parameter order. HAS
  FUNCTION AssertFalse(tuExpression, tcMessage)  && Added by HAS
  ********************************************************************
	*BSt [+] Added RETURN statement
    Return this.ioAssert.AssertFalse(tcMessage, tuExpression)
  
  ********************************************************************
  ENDFUNC
  ********************************************************************

	********************************************************************
  * Swapped message and expression parameter order. HAS
	FUNCTION AssertNotNull(tuExpression, tcMessage)
	********************************************************************
		*BSt [+] Added RETURN statement
		Return this.ioAssert.AssertNotNull(tcMessage, tuExpression)
	
	********************************************************************
	ENDFUNC
	********************************************************************

  ********************************************************************
  * Swapped message and expression parameter order. HAS
  FUNCTION AssertNotEmpty(tuExpression, tcMessage)
  ********************************************************************
	*BSt [+] Added RETURN statement  
    Return this.ioAssert.AssertNotEmpty(tcMessage, tuExpression)
  
  ********************************************************************
  ENDFUNC
  ********************************************************************

  ********************************************************************
  * Swapped message and expression parameter order. HAS
  FUNCTION AssertNotNullOrEmpty(tuExpression, tcMessage) && Added by HAS
  ********************************************************************
 	*BSt [+] Added RETURN statement
    Return this.ioAssert.AssertNotNullOrEmpty(tcMessage, tuExpression)
  ********************************************************************
  ENDFUNC
  ********************************************************************
	
  ********************************************************************
  *BSt [+] Added whole implementation
  FUNCTION AssertIsObject(tuObject AS Object, tcMessage AS String) AS Boolean
  ********************************************************************
    Return this.ioAssert.AssertIsObject(m.tcMessage, m.tuObject)
  ********************************************************************
  ENDFUNC
  ********************************************************************

  ********************************************************************
  *BSt [+] Added whole implementation
  FUNCTION AssertIsNotObject(tuUnknown AS Variant, tcMessage AS String) AS Boolean
  ********************************************************************
    Return this.ioAssert.AssertIsNotObject(m.tcMessage, m.tuUnknown)
  ********************************************************************
  ENDFUNC
  ********************************************************************

  ********************************************************************
  *BSt [+] Added whole implementation
  FUNCTION AssertEqualsArrays(taArray1 AS Variant, taArray2 AS Variant, tcMessage AS String, tlCaseInsensitive as Boolean) AS Boolean
  ********************************************************************
    Return this.ioAssert.AssertEqualsArrays(tcMessage, @taArray1, @taArray2, tlCaseInsensitive)
  ********************************************************************
  ENDFUNC
  ********************************************************************

  FUNCTION AssertNotEqualsArrays(taArray1 AS Variant, taArray2 AS Variant, tcMessage AS String, tlCaseInsensitive as Boolean) AS Boolean
  ********************************************************************
    Return NOT this.ioAssert.AssertEqualsArrays(tcMessage, @taArray1, @taArray2, tlCaseInsensitive)
  ********************************************************************
  ENDFUNC
  ********************************************************************


  ********************************************************************
  *BSt [+] Added whole implementation
  FUNCTION AssertHasError(tcFunction AS String, tcMessage AS String) AS Boolean
  ********************************************************************
	Local loExeption AS Exception
	loExeption = NULL
	LOCAL ARRAY laStackInfo[1,1]
	laStackInfo[1,1] = ""
	
	Try
		&tcFunction.
	Catch To loExeption When .T.
		=ASTACKINFO(laStackInfo)
		* now, an exception object should exist!
	Endtry
	
    Return This.ioAssert.AssertHasError(m.tcMessage, m.loExeption, @laStackInfo)
  ********************************************************************
  ENDFUNC
  ********************************************************************

  ********************************************************************
  *BSt [+] Added whole implementation
  FUNCTION AssertHasErrorNo(tcFunction AS String, tnErrorNo AS Integer, tcMessage AS String) AS Boolean
  ********************************************************************
	Local loExeption AS Exception
	loExeption = NULL
	LOCAL ARRAY laStackInfo[1,1]
	laStackInfo[1,1] = ""
	
	Try
		&tcFunction.
	Catch To loExeption When .T.
		=ASTACKINFO(laStackInfo)
		* now, an exception object should exist!
	Endtry
	
    Return This.ioAssert.AssertHasErrorNo(m.tcMessage, m.loExeption, m.tnErrorNo, @laStackInfo)
  ********************************************************************
  ENDFUNC
  ********************************************************************

	********************************************************************
	FUNCTION MessageOut(tcMessage)
	********************************************************************
		IF PCOUNT() = 0
			tcMessage = CHR(10)
		ENDIF 
		Return this.ioTestResult.LogMessage(tcMessage)
		
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION HandleException(toEx as Exception, taStackInfo, tlTearDownException)
	********************************************************************
	
		LOCAL loExceptionInfo as FxuResultExceptionInfo OF FxuResultExceptionInfo.prg
		loExceptionInfo = this.ioFxuInstance.FxuNewObject('FxuResultExceptionInfo')
		loExceptionInfo.SetExceptionInfo(toEx,@taStackInfo)
		*this.ioTestResult.ioException = toEx
		*this.ioTestResult.LogException(toEx)
		this.ioTestResult.LogException(loExceptionInfo, tlTearDownException)
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
**********************************************************************
ENDDEFINE && CLASS
**********************************************************************