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

RETURN CREATEOBJECT("FxuTestSuite")

**********************************************************************
DEFINE CLASS FxuTestSuite as FxuTest OF FxuTest.prg
**********************************************************************

	#IF .f.
		LOCAL this as FxuTestSuite OF FxuTestSuite.prg
	#ENDIF
	
	DIMENSION iaTests[1,2]
	inTestCount = 0
	inTestsRun = 0
	inTestsSuccessfull = 0
	ioTestBroker = .f.
	ilAllowDebug = .f.
	ioTestResult = .f.
	ilNotifyListener = .f.
	ioListener = .f.
	ioFxuInstance = .NULL.
	llStopped = .f.

	********************************************************************
	FUNCTION Init
	********************************************************************
		PARAMETERS toFxuInstance
		
		IF VARTYPE(m.toFxuInstance)!="O" OR ISNULL(m.toFxuInstance)
			ERROR 1924, "m.toFxuInstance"
			RETURN .F.
		ENDIF
		this.ioFxuInstance=m.toFxuInstance
		this.iaTests[1,1] = ''
	
	********************************************************************
	ENDFUNC
	********************************************************************

	********************************************************************
	FUNCTION AddTest(tcTestClass,tcTestName)
	********************************************************************
		IF EMPTY(tcTestName)
			RETURN
		ENDIF
		
		IF UPPER(ALLTRIM(tcTestName)) == "(NONE)"
			RETURN
		ENDIF
		
		
		LOCAL lnTestCount, llAddOne
		
		lnTestCount = this.inTestcount + 1
			
		DIMENSION this.iaTests[lnTestCount,2]
		
		this.iaTests[lnTestCount,1] = tcTestClass
		this.iaTests[lnTestCount,2] = tcTestName
		
		this.inTestCount = lnTestCount
			
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION RunTest(tcTestClass, tcTestMethod)
	********************************************************************
		LOCAL loTestBroker as FxuTestBroker OF FxuTestBroker.prg
		
		loTestBroker = this.ioFxuInstance.FxuNewObject("FxuTestBroker", this.ioFxuInstance)
		
		this.ioTestResult.NewResult(JUSTSTEM(tcTestClass),tcTestMethod) && Stripped path. HAS
		loTestBroker.RunTest(tcTestClass,tcTestMethod,this.ioTestResult,this.ilAllowDebug)
			
		
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION RunTests
	********************************************************************
		
		LOCAL lnCurrentTest, lnStartSeconds
		LOCAL lcTestClass, lcTestMethod, lcEscSetting
		PRIVATE llStopped 
		llStopped=.f.
		this.ioTestResult.inTotalTests = this.inTestCount
		this.ioTestResult.inRunTests = this.inTestsRun
		lcEscSetting = SET("Escape")
		SET ESCAPE ON 
		ON Escape StopTests()
		
		lnStartSeconds = SECONDS()
		
		FOR lnCurrentTest = 1 TO this.inTestCount
		
			lcTestClass = ALLTRIM(this.iaTests[lnCurrentTest,1])
			lcTestMethod = ALLTRIM(this.iaTests[lnCurrentTest,2])
			this.RunTest(lcTestClass,lcTestMethod)
			IF this.ioTestResult.ilCurrentResult
				this.inTestsSuccessfull = this.inTestsSuccessfull + 1
			ENDIF		
			this.NotifyListener()
			IF llStopped
				EXIT 
			ENDIF
		
		ENDFOR
		
		IF NOT llStopped
			this.NotifyListenerAllTestsComplete(SECONDS() - lnStartSeconds)
		ENDIF 
		SET ESCAPE &lcEscSetting
	********************************************************************
	ENDFUNC
	********************************************************************
	
	
	
	
	********************************************************************
	FUNCTION NotifyListener()
	********************************************************************

		this.Event_OneTestComplete(this.ioTestResult)		
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION NotifyListenerAllTestsComplete(tnSecondsElapsed)
	********************************************************************
		LOCAL lnTestsFailed, llTestSuiteSuccessfull

		lnTestsFailed = this.inTestCount - this.inTestsSuccessfull
		llTestSuiteSuccessfull = (this.inTestCount = this.inTestsSuccessfull)

		this.Event_AllTestsComplete(this.inTestCount, lnTestsFailed, llTestSuiteSuccessfull,tnSecondsElapsed)
		
	********************************************************************
	ENDFUNC
	********************************************************************
	
	
	********************************************************************
	FUNCTION Event_OneTestComplete(toTestResult)
	********************************************************************
	
		
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION Event_AllTestsComplete(tnTestCount, tnTestsFailed, tlSuccess, tnSecondsElapsed)
	********************************************************************
	
	
	
	********************************************************************
	ENDFUNC
	********************************************************************

**********************************************************************
ENDDEFINE && CLASS
**********************************************************************

	FUNCTION StopTests
	llStopped = .t.
