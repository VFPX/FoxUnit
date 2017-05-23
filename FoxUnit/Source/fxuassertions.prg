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

RETURN CREATEOBJECT("FxuAssertions")
EXTERNAL ARRAY taArray1, taArray2
*** Added by BSt -> mailto:burkhard.stiller@freenet.de

**********************************************************************
 DEFINE CLASS FxuAssertions AS FxuCustom OF FxuCustom.prg

	#IF .F.
		LOCAL THIS AS FxuAssertions OF FxuAssertions.prg
	#ENDIF

	ioTestResult = .NULL.
	ioFxuInstance = .NULL.
	icFailureMessage = ''
	ilNotifyListener = .F.
	ilSuccess = .T.

	PROCEDURE Init
		PARAMETERS toFxuInstance
		
		IF VARTYPE(m.toFxuInstance)!="O" OR ISNULL(m.toFxuInstance)
			ERROR 1924, "m.toFxuInstance"
			RETURN .F.
		ENDIF
		this.ioFxuInstance=m.toFxuInstance
	ENDPROC
********************************************************************
********************************************************************
	PROCEDURE ilSuccess_Assign(tlSuccess AS Booelan) AS Void
* tlSuccess <byVal> [optional] default=.F. := result of last evaluation
	WITH THIS
		IF .ilSuccess
			.ilSuccess = m.tlSuccess
		ENDIF
		IF .ilNotifyListener
			.ioTestResult.ilCurrentResult = .ilSuccess
		ENDIF
	ENDWITH
	ENDPROC
********************************************************************
********************************************************************
 	PROCEDURE ioTestResult_Assign(teResult AS Variant) AS Void
* teResult <byRef>/<objRef> [optional] default=.F. := evaluation result object
	LOCAL llNotifyListener AS Boolean
	IF VARTYPE(m.teResult) == "O"
		IF PEMSTATUS(m.teResult, "Class", 5) AND ;
				NOT PEMSTATUS(m.teResult, "Class", 2) AND ;
				PEMSTATUS(m.teResult, "Class", 3) == "Property" AND ;
				UPPER(m.teResult.CLASS) == "FXUTESTRESULT"
			m.llNotifyListener = .T.
		ENDIF
	ENDIF
	THIS.ilNotifyListener = m.llNotifyListener
	THIS.ioTestResult = m.teResult
	ENDPROC
********************************************************************
*******************     A S S E R T I O N S    *********************
********************************************************************
 	FUNCTION AssertNotImplemented(tcMessage AS STRING) AS Boolean
* tcMessage <byVal> [optional]! (default=""):= assertion message that gets logged
*
	tcMessage=EVL(tcMessage,"This test has not been implemented yet")
	THIS.ReportNotImplemented(m.tcMessage)
	THIS.ilSuccess = .f.
	RETURN THIS.ilSuccess 
	ENDFUNC
********************************************************************

********************************************************************
 	FUNCTION AssertEquals(tcMessage AS STRING, teItem1 AS Variant, teItem2 AS Variant, tlNonCaseSensitiveStringCompare AS Boolean) AS Boolean
* tcMessage <byVal> [optional]! (default=""):= assertion message that gets logged
* teItem1 <byVal/Ref>/<objRef> [optional]!	:= first item to compare
* teItem2 <byVal/Ref>/<objRef>  [optional]! := second item to compare
* tlNonCaseSensitiveStringCompare <byVal> [optional] (default =.F.)	:= case sensivity flag
*
*\\ BSt: force correct parameter type
	m.tlNonCaseSensitiveStringCompare = TRANSFORM(m.tlNonCaseSensitiveStringCompare) == ".T."

	LOCAL llAssertEquals AS Boolean		&& return value:= .T. if both items are equal

*\\ BSt: This is pretty ugly! 
*\\		 Making the first one or more parameters optional never
*\\		 seems to be a good idea!
* Trap for no message passed
	IF PCOUNT() = 2
		m.teItem2 = m.teItem1
		m.teItem1 = m.tcMessage
		m.tcMessage = ""
	ENDIF
*//

* Determine if we are comparing objects or value types
	IF VARTYPE(m.teItem1) == "O" AND VARTYPE(m.teItem2) == "O"
		m.llAssertEquals = THIS.AssertEqualsObjects(m.tcMessage, m.teItem1, m.teItem2)
	ELSE
		IF TYPE("m.teItem1", 1) == "A" AND TYPE("m.teItem2", 1) == "A"
*\\ BSt: added support for non-scalar values (arrays)
			m.llAssertEquals = THIS.AssertEqualsArray(m.tcMessage, @m.teItem1, @m.teItem2, m.tlNonCaseSensitiveStringCompare)
		ELSE
			m.llAssertEquals = THIS.AssertEqualsValues(m.tcMessage, m.teItem1, m.teItem2, m.tlNonCaseSensitiveStringCompare)
		ENDIF
	ENDIF
	THIS.ilSuccess = m.llAssertEquals
	RETURN m.llAssertEquals
	ENDFUNC
********************************************************************
********************************************************************
 	FUNCTION AssertEqualsValues(tcMessage AS STRING, teValue1 AS Variant, teValue2 AS Variant, tlNonCaseSensitiveStringCompare AS Boolean) AS Boolean
* tcMessage <byVal> [optional]! (default=""):= assertion message that gets logged
* teValue1 <byVal/Ref>/<objRef> [optional]!	:= first value to compare
* teValue2 <byVal/Ref>/<objRef>  [optional]! := second value to compare
* tlNonCaseSensitiveStringCompare <byVal> 	:= case sensivity flag
*

	LOCAL llAssertEqualsValues, llTypesMatch, lcItem1Type, lcItem2Type
	m.llAssertEqualsValues = .F.

	m.lcItem1Type = VARTYPE(m.teValue1 )
	m.lcItem2Type = VARTYPE(m.teValue2 )

	IF m.lcItem1Type != m.lcItem2Type
		THIS.ReportTypeMismatch(m.tcMessage, m.teValue1, m.teValue2 )
	ELSE
		m.llAssertEqualsValues = .T.
		IF tlNonCaseSensitiveStringCompare AND m.lcItem1Type == "C"

			IF !UPPER(m.teValue1 ) == UPPER(m.teValue2 )
				THIS.ReportValuesNotEqual(m.tcMessage + " (Non Case Sensitive String Comparison) ", m.teValue1, m.teValue2 )
				m.llAssertEqualsValues = .F.
			ENDIF
		ELSE
			IF ! m.teValue1== m.teValue2
				THIS.ReportValuesNotEqual(m.tcMessage, m.teValue1, m.teValue2 )
				m.llAssertEqualsValues=.F.
			ENDIF
		ENDIF
	ENDIF
	RETURN m.llAssertEqualsValues
	ENDFUNC
********************************************************************
********************************************************************
*\\ BSt: (sub)function added - compare two arrays (all array fields)
 	FUNCTION AssertEqualsArrays(tcMessage AS STRING, taArray1 AS ARRAY@, taArray2 AS ARRAY@, tlNonCaseSensitiveStringCompare AS Boolean, lnElementNo AS INTEGER) AS Boolean
* tcMessage <byVal> [optional] (default=""):= assertion message that gets logged
* taArray1 <byRef>	[mandatory]	:= first array to compare
* taArray2 <byRef>	[mandatory] := second array to compare
* tlNonCaseSensitiveStringCompare <byVal> := case sensivity flag (evaluated during string comparisons)
* lnElementNo <byVal> [optional] (default=0):= Array element pointer
	LOCAL llAssertEqualsArrays AS Boolean	&& return value:= .T. if both arrays are identical
	IF NOT VARTYPE(m.lnElementNo) == "N"
		m.lnElementNo = 0 && 0:= special value
	ELSE
		m.lnElementNo = MAX(MIN(m.nElementNo, ALEN(m.taArray1, 0)), 0)
	ENDIF
	DO CASE
*\\ Check array type again (if method gets called from outside)
	CASE NOT TYPE("m.taArray1", 1) == "A" AND NOT TYPE("m.taArray2", 1) == "A"
		THIS.ReportTypeMismatch(m.tcMessage, m.taArray1, m.taArray2)
*\\ compare array structure (part I) - element count
	CASE NOT ALEN(m.taArray1) = ALEN(m.taArray2)
		THIS.ReportArrayMismatch(m.tcMessage + " (Array Length Comparison) ", ;
			  @m.taArray1, @m.taArray2, 0)
*\\ compare array structure (part II) - column count
	CASE NOT ALEN(m.taArray1, 2) = ALEN(m.taArray2, 2)
		THIS.ReportArrayMismatch(m.tcMessage + " (Array Column Count Comparison) ", ;
			  @m.taArray1, @m.taArray2, 0)
*\\ compare array structure (part III) - row count
	CASE NOT ALEN(m.taArray1, 1) = ALEN(m.taArray2, 1)
		THIS.ReportArrayMismatch(m.tcMessage + " (Array Row Count Comparison) ", ;
			  @m.taArray1, @m.taArray2, 0)
*\\ handle case sensitive STRING comparison
	CASE m.tlNonCaseSensitiveStringCompare AND ;
			VARTYPE(m.taArray1) == "C" AND ;
			VARTYPE(m.taArray2) == "C" AND ;
			NOT UPPER(m.taArray1) == UPPER(m.taArray2)
		THIS.ReportValuesNotEqual(m.tcMessage + ;
			  " (Non Case Sensitive String Comparison) ", ;
			  m.taArray1, m.taArray2, 0)
	OTHERWISE
*\\ compare both arrays
		LOCAL lnLoop AS INTEGER;	&& array fields loop
			, m.lnLowerB AS INTEGER;	&& lower array loop boundary
			, m.lnUpperB AS INTEGER	&& upper array loop boundary
		m.lnLowerB = 1
		m.lnUpperB = ALEN(m.taArray1)
		m.llAssertEqualsArrays = .T.	&& .T. if no comparison error occurred
		IF m.lnElementNo > 0
*\\ reduce loop to just one element!
			STORE m.lnElementNo TO m.lnLowerB, m.lnUpperB
		ENDIF
		FOR m.lnLoop = m.lnLowerB TO m.lnUpperB
			IF VARTYPE(m.taArray1[m.lnLoop]) == "C" AND VARTYPE(m.taArray2[m.lnLoop]) == "C"
*\\ handle case sensitive STRING comparison
				IF m.tlNonCaseSensitiveStringCompare
					IF NOT UPPER(m.taArray1[m.lnLoop]) == UPPER(m.taArray2[m.lnLoop])
						THIS.ReportArrayMismatch(m.tcMessage + " (Array String Value Comparison) ", ;
							  @m.taArray1, @m.taArray2, m.lnLoop)
						m.llAssertEqualsArrays = .F.
					ENDIF
				ELSE
					IF NOT m.taArray1[m.lnLoop] == m.taArray2[m.lnLoop]
						THIS.ReportArrayMismatch(m.tcMessage + ;
							  " (Array String Value Comparison - Exact Match) ", ;
							  @m.taArray1, @m.taArray2, m.lnLoop)
						m.llAssertEqualsArrays = .F.
					ENDIF
				ENDIF
			ELSE
				IF NOT VARTYPE(m.taArray1[m.lnLoop]) == VARTYPE(m.taArray2[m.lnLoop])
					THIS.ReportArrayMismatch(m.tcMessage + ;
						  " (Array Field Type Comparison) ", ;
						   @m.taArray1, @m.taArray2, m.lnLoop)
					m.llAssertEqualsArrays = .F.
				ELSE
					IF NOT m.taArray1[m.lnLoop] = m.taArray2[m.lnLoop]
						THIS.ReportArrayMismatch(m.tcMessage + ;
							  " (Array Field Value Comparison) ", ;
							  @m.taArray1, @m.taArray2, m.lnLoop)
						m.llAssertEqualsArrays = .F.
					ENDIF
				ENDIF
			ENDIF
*\\ comment out EXIT command to always scan/log all array elements
			IF NOT m.llAssertEqualsArrays
				EXIT && ================================>>>>>>>>>>>>
			ENDIF
		NEXT
	ENDCASE
	RETURN m.llAssertEqualsArrays = .T.
	ENDFUNC
********************************************************************
********************************************************************
 	FUNCTION AssertEqualsObjects(tcMessage AS STRING, teItem1 AS Variant, teItem2 AS Variant) AS Boolean
	LOCAL llAssertEqualsObjects
	IF NOT COMPOBJ(m.teItem1, m.teItem2)
		THIS.ReportObjectsNotSame(m.tcMessage)
	ELSE
		m.llAssertEqualsObjects = .T.
	ENDIF
	RETURN m.llAssertEqualsObjects
	ENDFUNC
********************************************************************
********************************************************************
 	FUNCTION AssertTrue(tcMessage AS STRING, teItem AS Variant) AS Boolean
	LOCAL llAssertTrue
	IF NOT m.teItem
		THIS.ReportAssertionFalse(m.tcMessage)
	ELSE
		m.llAssertTrue = .T.
	ENDIF
	THIS.ilSuccess = m.llAssertTrue
	RETURN m.llAssertTrue
	ENDFUNC
********************************************************************
********************************************************************
*** Added by HAS
 	FUNCTION AssertFalse(tcMessage AS STRING, teItem AS Variant) AS Boolean
	LOCAL llAssertFalse
	IF m.teItem
		THIS.ReportAssertionTrue(m.tcMessage)
	ELSE
		m.llAssertFalse = .T.
	ENDIF
	THIS.ilSuccess = m.llAssertFalse
	RETURN m.llAssertFalse
	ENDFUNC
********************************************************************
********************************************************************
 	FUNCTION AssertNotNull(tcMessage AS STRING, teItem AS Varianf) AS Boolean
	LOCAL llAssertNotNull
	IF ISNULL(m.teItem)
		THIS.ReportIsNull(m.tcMessage)
	ELSE
		m.llAssertNotNull = .T.
	ENDIF
	THIS.ilSuccess = m.llAssertNotNull
	RETURN m.llAssertNotNull
	ENDFUNC
********************************************************************
********************************************************************
*** Added by HAS
 	FUNCTION AssertNotEmpty(tcMessage AS STRING, teItem AS STRING) AS Void
	LOCAL llAssertNotEmpty
* llAssertNotEmpty  = .F.
	IF EMPTY(m.teItem)
		THIS.ReportIsEmpty(m.tcMessage)
	ELSE
		m.llAssertNotEmpty  = .T.
	ENDIF
	THIS.ilSuccess = m.llAssertNotEmpty
	RETURN m.llAssertNotEmpty
	ENDFUNC
********************************************************************
********************************************************************
*** Added by HAS
 	FUNCTION AssertNotNullOrEmpty(tcMessage AS STRING, teItem AS Variant) AS Boolean
	LOCAL llAssertNotNullOrEmpty
	IF VARTYPE(m.teItem) == "O" OR ISNULL(m.teItem)
* forward message - setting This.ilSuccess will be handled there
		m.llAssertNotNullOrEmpty = THIS.AssertNotNull(m.tcMessage, m.teItem)
	ELSE
* forward message - setting This.ilSuccess will be handled there
		m.llAssertNotNullOrEmpty = THIS.AssertNotEmpty(m.tcMessage, m.teItem)
	ENDIF
	RETURN m.llAssertNotNullOrEmpty
	ENDFUNC
********************************************************************
********************************************************************
* Added by BSt
 	FUNCTION AssertIsObject(tcMessage AS STRING, tuObject AS OBJECT) AS Boolean
	LOCAL llAssertIsObject AS Boolean
* BSt: replaced call "If This.IsObject(m.tuObject)" with inline code
	IF VARTYPE(m.tuObject) == "O"
		m.llAssertIsObject = .T.
	ELSE
		THIS.ReportAssertionIsObject(m.tcMessage)
	ENDIF
	THIS.ilSuccess = m.llAssertIsObject
	RETURN m.llAssertIsObject
	ENDFUNC
********************************************************************
********************************************************************
* Added by BSt
 	FUNCTION AssertIsNotObject(tcMessage AS STRING, teObject AS Variant) AS Boolean
	LOCAL llAssertIsNotObject AS Boolean
* BSt: replaced call "If This.IsObject(m.tuObject)" with inline code
	IF VARTYPE(m.teObject) == "O"
		THIS.ReportAssertionIsNotObject(m.tcMessage)
	ELSE
		m.llAssertIsNotObject = .T.
	ENDIF
	THIS.ilSuccess = m.llAssertIsNotObject
	RETURN m.llAssertIsNotObject
	ENDFUNC
********************************************************************
********************************************************************
* Added by BSt
 	FUNCTION AssertHasError(tcMessage AS STRING, toException AS EXCEPTION, taStackInfo AS StackArray@) AS Boolean
	LOCAL llAssertHasError AS Boolean
	IF VARTYPE(m.toException) == "O" AND m.toException.BASECLASS == "Exception"
		m.llAssertHasError = .T.
*\\ create exception info object and populate its properties
		LOCAL loExceptionInfo AS FxuResultExceptionInfo OF FxuResultExceptionInfo.prg
		m.loExceptionInfo = this.ioFxuInstance.FxuNewObject('FxuResultExceptionInfo')
		m.loExceptionInfo.SetExceptionInfo(m.toException, @m.taStackInfo)
*\\ log
		THIS.ioTestResult.LogMessage(m.loExceptionInfo.ToString())
	ELSE
*\\ if there's no exception object, just report/log as normal
		THIS.ReportAssertionHasError(m.tcMessage)
	ENDIF
	THIS.ilSuccess = m.llAssertHasError
	RETURN m.llAssertHasError
	ENDFUNC
********************************************************************
********************************************************************
* Added by BSt - Log exception info if error number passed in matches,
*				 otherwise pass exception object to regular report handler
 	FUNCTION AssertHasErrorNo(tcMessage AS STRING, toException AS EXCEPTION, tnErrorNo AS INTEGER, taStackInfo AS StackArray@) AS Boolean
	LOCAL llAssertHasErrorNo AS Boolean
	IF VARTYPE(m.toException) == "O" AND ;
			m.toException.BASECLASS == "Exception" ;
			AND m.toException.ERRORNO = m.tnErrorNo
*\\ this is the case the method was build for
		m.llAssertHasErrorNo = .T.
*\\ create exception info object and populate its properties
		LOCAL loExceptionInfo AS FxuResultExceptionInfo OF FxuResultExceptionInfo.prg
		m.loExceptionInfo = this.ioFxuInstance.FxuNewObject('FxuResultExceptionInfo')
		m.loExceptionInfo.SetExceptionInfo(m.toException, @m.taStackInfo)
*\\ log
		THIS.ioTestResult.LogMessage(m.loExceptionInfo.ToString())
	ELSE
		IF NOT VARTYPE(m.toException) == "O"
*\\ report internal parameter error (-1:= No object reference was passed in)
			THIS.ReportAssertionHasErrorNo(m.tcMessage, m.tnErrorNo,	 -1)
		ELSE
			IF m.toException.BASECLASS == "Exception"
*\\ handle any other error number but the one passed in
				THIS.ReportAssertionHasErrorNo(m.tcMessage, m.tnErrorNo, m.toException.ERRORNO)
			ELSE
*\\ report internal parameter error (-2:= No Exception object reference was passed in)
				THIS.ReportAssertionHasErrorNo(m.tcMessage, m.tnErrorNo, -2)
			ENDIF
		ENDIF
	ENDIF
	THIS.ilSuccess = m.llAssertHasErrorNo
	RETURN m.llAssertHasErrorNo
	ENDFUNC
********************************************************************
********************************************************************
***  Deprecated by BSt (not used all over the project)
 	PROTECTED FUNCTION IsObject(m.teObject AS Variant) AS Boolean
*\\ Code shortened by BSt
		RETURN VARTYPE(m.teObject) == "O"
		ENDFUNC
********************************************************************
********************************************************************
 	PROTECTED FUNCTION EnumerateVarType(m.tcVarType AS STRING) AS STRING
* tcVarType 
		m.tcVarType = LEFT(UPPER(ALLTRIM(m.tcVarType)), 1)
		DO CASE
		CASE m.tcVarType == "C"
			m.tcVarType = "Character"
		CASE m.tcVarType == "N"
			m.tcVarType =	"Numeric"
		CASE m.tcVarType == "Y"
			m.tcVarType = "Currency"
		CASE m.tcVarType == "L"
			m.tcVarType = "Logical"
		CASE m.tcVarType == "O"
			m.tcVarType = "Object"
		CASE m.tcVarType == "G"
			m.tcVarType = "General"
		CASE m.tcVarType == "D"
			m.tcVarType = "Date"
		CASE m.tcVarType == "T"
			m.tcVarType = "DateTime "
		CASE m.tcVarType == "X"
			m.tcVarType = "Null"
		CASE m.tcVarType == "S"
*\\ BSt: added for completeness
			m.tcVarType = "Screen"
		OTHERWISE
			m.tcVarType = "Unknown"
		ENDCASE
		RETURN m.tcVarType
		ENDFUNC
********************************************************************
********************************************************************
 	PROCEDURE ClearAssert() AS Void
	THIS.icFailureMessage = ''
	ENDPROC
********************************************************************
********************************************************************
 	PROCEDURE ReportNotImplemented(tcMessage) AS Void
	THIS.NewMessageDivider(.T.)
	THIS.AddMessage(m.tcMessage)
	ENDPROC
********************************************************************
********************************************************************
 	PROCEDURE ReportIsNull(tcMessage) AS Void
	THIS.NewMessageDivider(.T.)
	THIS.AddMessage(m.tcMessage)
	THIS.AddMessage("Item is Null")
	ENDPROC
********************************************************************
********************************************************************
*** Added by HAS
 	PROCEDURE ReportIsEmpty(tcMessage AS STRING) AS Void
	THIS.NewMessageDivider(.T.)
	THIS.AddMessage(m.tcMessage)
	THIS.AddMessage("Item is Empty")
	ENDPROC
********************************************************************
********************************************************************
 	PROCEDURE ReportObjectsNotSame(tcMessage AS STRING) AS Void
	THIS.NewMessageDivider(.T.)
	THIS.AddMessage(m.tcMessage)
	THIS.AddMessage("Objects are not the same")
	ENDPROC
********************************************************************
********************************************************************
 	PROCEDURE ReportTypeMismatch(tcMessage AS STRING, teItem1 AS Variant, teItem2 AS Variant) AS Void
	LOCAL lcReportType1, lcReportType2
	m.lcReportType1 = THIS.EnumerateVarType(VARTYPE(m.teItem1))
	m.lcReportType2 = THIS.EnumerateVarType(VARTYPE(m.teItem2))
	THIS.NewMessageDivider(.T.)
	THIS.AddMessage(m.tcMessage)
	THIS.AddMessage("Value Type Mismatch")
	THIS.AddMessage("Expected Type: " + m.lcReportType1 + " Expected Value: "	+ TRANSFORM(m.teItem1))
	THIS.AddMessage("Actual Type: "	+ m.lcReportType2 + " Actual Value: "	+ TRANSFORM(m.teItem2))
	ENDPROC
********************************************************************
********************************************************************
 	PROCEDURE ReportArrayMismatch(tcMessage AS STRING, taArray1 AS ARRAY@, taArray2 AS ARRAY@, tnArrayPointer AS INTEGER) AS Void
	IF NOT VARTYPE(m.tnArrayPointer) == "N"
		m.tnArrayPointer = 0 && special flag value: "no array index needed"
	ENDIF
	LOCAL lcReportType1, lcReportType2
	m.lcReportType1 = THIS.EnumerateVarType(VARTYPE(m.taArray1[m.tnArrayPointer]))
	m.lcReportType2 = THIS.EnumerateVarType(VARTYPE(m.taArray2[m.tnArrayPointer]))
	THIS.NewMessageDivider(.T.)
	THIS.AddMessage(m.tcMessage)
	IF m.tnArrayPointer = 0
		THIS.AddMessage("Array Mismatch")
	ELSE
		THIS.AddMessage("Array Mismatch at Index:" + TRANSFORM(m.tnArrayPointer))
	ENDIF
	THIS.AddMessage("Expected Type: " + m.lcReportType1 + " Expected Value: " + TRANSFORM(m.taArray1[m.tnArrayPointer]))
	THIS.AddMessage("Actual Type: "	+ m.lcReportType2 + " Actual Value: " + TRANSFORM(m.taArray2[m.tnArrayPointer]))
	ENDPROC
********************************************************************
********************************************************************
 	PROCEDURE ReportValuesNotEqual(tcMessage AS STRING, teItem1 AS Variant, teItem2 AS Variant) AS Void
	THIS.NewMessageDivider(.T.)
	THIS.AddMessage(m.tcMessage)
	THIS.AddMessage("Values Not Equal")
	THIS.AddMessage("Expected Value: " + TRANSFORM(m.teItem1))
	THIS.AddMessage("Actual Value: " + TRANSFORM(m.teItem2))
	ENDPROC
********************************************************************
********************************************************************
 	PROCEDURE ReportAssertionFalse(tcMessage AS STRING) AS Void
	THIS.NewMessageDivider(.T.)
	THIS.AddMessage(m.tcMessage)
	THIS.AddMessage("AssertTrue Returned False")
	ENDPROC
********************************************************************
********************************************************************
*** Added by HAS
 	PROCEDURE ReportAssertionTrue(tcMessage AS STRING) AS Void
	THIS.NewMessageDivider(.T.)
	THIS.AddMessage(m.tcMessage)
	THIS.AddMessage("AssertFalse Returned True")
	ENDPROC
********************************************************************
********************************************************************
*** Added by BSt
 	PROCEDURE ReportAssertionIsObject(tcMessage AS STRING) AS Void
********************************************************************
	THIS.NewMessageDivider(.T.)
	THIS.AddMessage(m.tcMessage)
	THIS.AddMessage("AssertIsObject Returned False")
********************************************************************
	ENDPROC
********************************************************************
********************************************************************
*** Added by BSt
 	PROCEDURE ReportAssertionIsNotObject(tcMessage AS STRING) AS Void
	THIS.NewMessageDivider(.T.)
	THIS.AddMessage(m.tcMessage)
	THIS.AddMessage("AssertIsNotObject Returned False")
	ENDFUNC
********************************************************************
********************************************************************
*** Added by BSt
 	PROCEDURE ReportAssertionHasError(tcMessage AS STRING) AS Void
	THIS.NewMessageDivider(.T.)
	THIS.AddMessage(m.tcMessage)
	THIS.AddMessage("ReportAssertionHasError Returned False")
	ENDPROC
********************************************************************
********************************************************************
** Added by BSt
 	PROCEDURE ReportAssertionHasErrorNo(tcMessage AS STRING, tnExpectedNumber AS INTEGER, tnErrorNoThrown AS INTEGER) AS Void
	THIS.NewMessageDivider(.T.)
	THIS.AddMessage(m.tcMessage)
	THIS.AddMessage("Expected ErrorNo# " + TRANSFORM(m.tnExpectedNumber))
	DO CASE
	CASE m.tnErrorNoThrown = -1
*\\ Exception not TypeOf(Object)
		THIS.AddMessage("No Object Was Generated")
	CASE m.tnErrorNoThrown = -2
*\\ Object not TypeOf(Exception)
		THIS.AddMessage("Generated Object Was Not Of Type 'Exception'")
	OTHERWISE
		THIS.AddMessage("ErrorNo# That Was Thrown: " + TRANSFORM(m.tnErrorNoThrown))
	ENDCASE
	THIS.AddMessage("ReportAssertionHasErrorNo Returned False")
	ENDPROC
********************************************************************
********************************************************************
 	PROCEDURE AddMessage(tcMessage AS STRING) AS Void
	IF NOT EMPTY(m.tcMessage)
		WITH THIS
			IF NOT EMPTY(.icFailureMessage)
				.icFailureMessage = .icFailureMessage + CHR(10)
			ENDIF
			.icFailureMessage = .icFailureMessage + m.tcMessage
			IF .ilNotifyListener
				.ioTestResult.icFailureErrorDetails = .icFailureMessage
			ENDIF
		ENDWITH
	ENDIF
	ENDPROC
********************************************************************
********************************************************************
 	PROCEDURE NewMessageDivider(tlAssertionFailure AS Boolean) AS Void
*\\ BSt: slightly shortened
	THIS.AddMessage("-------------------------------")
	IF NOT EMPTY(m.tlAssertionFailure)
		THIS.AddMessage("------Assertion Failure")
		THIS.AddMessage("-------------------------------")
	ENDIF
	ENDPROC
********************************************************************
************************************************************************
 ENDDEFINE && CLASS
************************************************************************

