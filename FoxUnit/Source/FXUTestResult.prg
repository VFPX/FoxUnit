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

**********************************************************************
DEFINE CLASS FxuTestResult as Collection
**********************************************************************

	#IF .f.
		LOCAL this as FxuTestResult OF FxuTestResult.prg
	#ENDIF
	
	inRunTests = 0
	inTotalTests = 0
	inFailedTests = 0
	icFailureErrorDetails = ''
	ioExceptionInfo = .NULL.
	ioTeardownExceptionInfo = .NULL.
	ilCurrentResult = .t.
	icCurrentTestClass = ''
	icCurrentTestName = ''
	icCurrentResultPK = ''
	inCurrentStartSeconds = 0
	inCurrentEndSeconds = 0
	icMessages = ''	
	inLastKey = 0
	HIDDEN ilCurrentResult_Allow
	
	********************************************************************
	FUNCTION ResetCurrentResult
	********************************************************************
	
		WITH THIS

			.icFailureErrorDetails = ''
			.icMessages = ''
			.ilCurrentResult_Allow = .T.
			.ilCurrentResult = .t.
			.ilCurrentResult_Allow = .F.
			.icCurrentTestClass = ''
			.icCurrentTestName = ''
			.inFailedTests = 0
			.inCurrentStartSeconds = 0
			.inCurrentEndSeconds = 0
			.ioExceptionInfo = .NULL.
			.ioTeardownExceptionInfo = .NULL.
			
		ENDWITH
	
		
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION LogException(toExceptionInfo, tlTearDownException)
	********************************************************************
	
		IF EMPTY(tlTearDownException)
			tlTearDownException = .f.
		ELSE
			tlTearDownException = .t.
		ENDIF   
	
		this.ilCurrentResult = .f.
		
		IF tlTearDownException
			this.ioTeardownExceptionInfo = toExceptionInfo
		ELSE  
			this.ioExceptionInfo = toExceptionInfo
		ENDIF
		
		*this.LogDetail(this.BuildExceptionString(toException))
		this.LogDetail(toExceptionInfo.ToString())
		*this.icFailureErrorDetails = this.icFailureErrorDetails + this.BuildExceptionString(toException)
		
	********************************************************************
	ENDFUNC
	********************************************************************

	
	********************************************************************
	FUNCTION NewResult(tcClassName, tcTestName)
	********************************************************************
	
		this.ResetCurrentResult()
		this.icCurrentTestClass = tcClassName
		this.icCurrentTestName = tcTestName
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	
	********************************************************************
	FUNCTION LogResult()
	********************************************************************
	
		this.inRunTests = this.inRunTests + 1
	
	********************************************************************
	ENDFUNC
	********************************************************************

	********************************************************************
	PROCEDURE LogDetail(tcDetail AS String)
	********************************************************************
	
		IF !EMPTY(this.icFailureErrorDetails)
			this.icFailureErrorDetails = this.icFailureErrorDetails + CHR(10)
		ENDIF
		
		this.icFailureErrorDetails = this.icFailureErrorDetails + ALLTRIM(tcDetail)
	
	********************************************************************
	ENDPROC
	********************************************************************
	
	********************************************************************
	PROCEDURE LogMessage(tcMessage AS String) AS Void
	********************************************************************
		*BSt [~] shortend code a little bit
		tcMessage = Iif(PCOUNT() = 0, "", ALLTRIM(m.tcMessage))
		this.icMessages = this.icMessages + ;
				Iif(EMPTY(this.icMessages),"", CHR(10)) + m.tcMessage
	
	********************************************************************
	ENDPROC
	********************************************************************		
	
	********************************************************************
	FUNCTION BuildExceptionString(toException as Exception)
	********************************************************************
	
		LOCAL lcException
		
		toException = this.ioException	
		
		lcException = ("******** Error/Exception **********" + CHR(10))
		
		lcException = (lcException + "An error occurred on line " + ;
			TRANSFORM(toException.LineNo) + " of " + ;
			toException.Procedure + " .")
			
		lcException = lcException + (CHR(10))
		
		lcException = lcException + ("Error Number: " + TRANSFORM(toException.ErrorNo))
		
		lcException = lcException + (CHR(10))
		
		lcException = lcException + ("Error Message: " + toException.Message)
		
		lcException = lcException + CHR(10)
		
		lcException = lcException + ("******** Line Contents **********" + CHR(10))
		
		lcException = lcException + (toException.LineContents + CHR(10))
		
		lcException = lcException + ("*********************************" + CHR(10))
				
		RETURN lcException
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION EnumerateVarType(tcVarType)
	********************************************************************
	
		lcReturnType = "Unknown"
		
		lcVarType = UPPER(ALLTRIM(tcVarType))
		
		DO case
		
			CASE lcVarType == "C" 
				lcReturnType = "Character"
			CASE lcVarType == "N"
				lcReturnType =	"Numeric"
			CASE lcVarType == "Y"
				lcReturnType = "Currency"
			CASE lcVarType == "L"
				lcReturnType = "Logical"
			CASE lcVarType == "O"
				lcReturnType = "Object"
			CASE lcVarType == "G"
				lcReturnType = "General"
			CASE lcVarType == "D"
				lcReturnType = "Date"
			CASE lcVarType == "T"
				lcReturnType = "DateTime "
			CASE lcVarType == "X"
				lcReturnType = "Null"
				
		ENDCASE
		
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	PROTECTED PROCEDURE ilCurrentResult_Assign
		PARAMETERS vNewVal
		
		IF this.ilCurrentResult_Allow
			this.ilCURRENTRESULT = m.vNewVal
		ELSE
			this.ilCURRENTRESULT = this.ilCURRENTRESULT AND m.vNewVal
		ENDIF
	ENDPROC

**********************************************************************
ENDDEFINE && CLASS
**********************************************************************