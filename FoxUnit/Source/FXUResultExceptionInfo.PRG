**********************************************************************
DEFINE CLASS FxuResultExceptionInfo as FxuCustom OF FxuCustom.prg
**********************************************************************

	#IF .f.
		LOCAL this as FxuResultExceptionInfo OF FxuResultExceptionInfo.prg
	#ENDIF
	
	DIMENSION iaStackInfo[1,1]
	ioException = .NULL.
	icMessage = ''
	inErrorNumber = 0
	inLineNumber = 0
	icProcedure = ''
	icLineContents = ''
	
	********************************************************************
	FUNCTION SetExceptionInfo(toException as Exception, taStackInfo)
	********************************************************************
	
		this.ioException = toException
		this.icMessage = toException.Message
		this.inErrorNumber = toException.ErrorNo
		this.inLineNumber = toException.LineNo
		this.icProcedure = toException.Procedure
		this.icLineContents = toException.LineContents
		=ACOPY(taStackInfo,this.iaStackInfo)
		
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION ToString(toException as Exception)
	********************************************************************
	
	
		IF EMPTY(toException)
			IF !ISNULL(this.ioException)
				toException = this.ioException
			ELSE
				RETURN ''
			ENDIF
		ENDIF
		
		LOCAL lcException
		
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

**********************************************************************
ENDDEFINE && CLASS
**********************************************************************