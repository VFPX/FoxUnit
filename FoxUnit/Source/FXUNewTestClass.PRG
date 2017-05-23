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

RETURN CREATEOBJECT("FxuNewTestClass")

**********************************************************************
 DEFINE CLASS FxuNewTestClass AS FxuCustom OF FxuCustom.prg
**********************************************************************

	#IF .F.
		LOCAL THIS AS FxuNewTestClass OF FxuNewTestClass.prg
	#ENDIF

	icTemplateContents = SPACE(0)
	ilTabs = .T.
	ilFunction = .T.

********************************************************************
	FUNCTION CreateNewTestClass(tcClassName, tcTemplate, tlTabs, tlFunction)
********************************************************************

* tnTemplateType=1 (Existing TXT template), 2 (Copy a test class PRG), 3 (Mock tests from existing classlib)
*
*  called from FXUResultData.PRG/FXUResultData::CreateNewTestCaseClass()
*    XXDTES("FXURESULTDATA.PRG","loTestClassCreator.CreateNewTestClass(")
*
	LOCAL lcFullPathToClass, lcJustClassName, plReturn
	plReturn = .t.
	m.tcClassName = ALLTRIM(m.tcClassName)
*
*  only filename was passed, no path 
*
*  note that this code is never called at the moment,
*  because when FoxUnit.SCX/cmdCreateNewTestClass.Click()
*  calls FXUResultsData/ResultsData::CreateNewTestCaseClass()
*  and it calls here, it always passes the filename
*  including the full path
*
	IF UPPER(JUSTFNAME(m.tcClassName)) == UPPER(m.tcClassName)
		LOCAL lcJustClassName
		m.lcJustClassName = JUSTSTEM(m.tcClassName)
		m.lcFullPathToClass = CURDIR() + m.tcClassName + ".PRG"
		IF FILE(m.lcFullPathToClass)
			THIS.icLastErrorMessage = "Program File " + m.lcFullPathToClass + " already exists."
			plReturn = .F.
		ENDIF
	ELSE
		m.lcFullPathToClass = m.tcClassName
		m.lcJustClassName = CHRTRAN(JUSTSTEM(m.lcFullPathToClass), ' ','')
	ENDIF
	
	IF plReturn
		m.pcTemplate = UPPER(ALLTRIM(m.tcTemplate))
		This.ilFunction = EVL(tlFunction,.null.)
		This.ilTabs = EVL(tlTabs,.null.)
		* 8/1/14 Only using existing class template now in this function

		*  user selected an existing test case class
		*  .TXT template to copy as the starting point
		*
		m.pcTemplate = GETWORDNUM(m.pcTemplate, 1, ",")
		IF THIS.LoadNewTestClassTemplate(m.pcTemplate)
			THIS.MergeClassName(m.lcJustClassName)
			STRTOFILE(THIS.icTemplateContents, m.lcFullPathToClass)
		ENDIF
		THIS.ProcessTabsAndFunction(m.lcFullPathToClass)
		plReturn = FILE(m.lcFullPathToClass)
	ENDIF 

	RELEASE m.pcTemplate
	RETURN plReturn

********************************************************************
	ENDFUNC
********************************************************************


********************************************************************
 	FUNCTION MergeClassName(tcJustClassName)
********************************************************************
	THIS.icTemplateContents = STRTRAN(THIS.icTemplateContents, "<<testclass>>", m.tcJustClassName)
	ENDFUNC
********************************************************************


********************************************************************
 	FUNCTION LoadNewTestClassTemplate(m.tcClassTemplate)
********************************************************************
	LOCAL lcClassTemplate, lcClassTemplateFullPath, llTemplateLoaded
	m.llTemplateLoaded = .F.
	IF VARTYPE(m.tcClassTemplate) = "C" ;
			AND NOT EMPTY(m.tcClassTemplate)
		m.lcClassTemplate = UPPER(ALLTRIM(m.tcClassTemplate))
	ELSE
		m.lcClassTemplate = UPPER(FULLPATH("FxuTestCaseTemplate.TXT"))
	ENDIF

	m.lcClassTemplateFullPath = LOCFILE(m.lcClassTemplate, ".txt", "Find " + m.lcClassTemplate)
	IF NOT EMPTY(m.lcClassTemplateFullPath) ;
			AND FILE(m.lcClassTemplateFullPath)

		THIS.icTemplateContents = FILETOSTR(m.lcClassTemplateFullPath)
		m.llTemplateLoaded = .T.
	ENDIF
	RETURN m.llTemplateLoaded
	ENDFUNC
********************************************************************


********************************************************************
 	FUNCTION LoadExistingClassProgram(m.tcClassPRG)
********************************************************************

	LOCAL lcClassPRG, lcClassPRGFullPath, llLoaded
	m.lcClassPRG = UPPER(ALLTRIM(m.tcClassPRG))
	m.lcClassPRGFullPath = LOCFILE(m.lcClassPRG, ".PRG", "Find " + m.lcClassPRG)
	IF NOT EMPTY(m.lcClassPRGFullPath) AND FILE(m.lcClassPRGFullPath)
		THIS.icTemplateContents = FILETOSTR(m.lcClassPRGFullPath)
		m.llLoaded = .T.
	ENDIF
	IF m.llLoaded
*
*  update the DEFINE CLASS line to replace the
*  replace the class name with <<test class>>
*
		LOCAL lcLine, laLines[1], lcClassName, xx
		ALINES(laLines, THIS.icTemplateContents)
		FOR m.xx = 1 TO ALEN(m.laLines, 1)
			m.lcLine = m.laLines[m.xx]
			IF UPPER(ALLTRIM(m.lcLine)) = "DEFINE CLASS "
				m.lcClassName = GETWORDNUM(ALLTRIM(m.lcLine), 3)
				EXIT
			ENDIF
		ENDFOR
		IF EMPTY(m.lcClassName)
			m.llLoaded = .F.
		ELSE
			THIS.icTemplateContents = STRTRAN(THIS.icTemplateContents, ;
				  SPACE(1) + m.lcClassName + SPACE(1), ;
				  " <<testclass>> ", ;
				  - 1, ;
				  - 1, ;
				  1)
			THIS.icTemplateContents = STRTRAN(THIS.icTemplateContents, ;
				  SPACE(1) + m.lcClassName + ".PRG", ;
				  " <<testclass>>.PRG", ;
				  - 1, ;
				  - 1, ;
				  1)
		ENDIF
	ENDIF
	RETURN m.llLoaded
	ENDFUNC
********************************************************************


********************************************************************
 	FUNCTION ProcessTabsAndFunction(m.tcClassPRG)
********************************************************************
	IF ISNULL(THIS.ilTabs) AND ISNULL(THIS.ilFunction)
		RETURN
	ENDIF

	IF THIS.ilTabs AND THIS.ilFunction
*  the FXU templates use TABs and FUNCTION, 
*  so there's nothing to do
	ENDIF

	LOCAL laLines[1], xx, lcLine
	ALINES(laLines, FILETOSTR(m.tcClassPRG))

	IF NOT THIS.ilTabs
*  remove the {TAB} indentation
		FOR m.xx = 1 TO ALEN(m.laLines, 1)
			m.lcLine = m.laLines[m.xx]
			IF LEFTC(m.lcLine, 1) = CHR(9)
				m.laLines[m.xx] = SUBSTRC(m.lcLine, 2)
			ENDIF
		NEXT
	ENDIF

	IF NOT THIS.ilFunction
*  replace FUNCTION with PROCEDURE
		FOR m.xx = 1 TO ALEN(m.laLines, 1)
			m.lcLine = ALLTRIM(m.laLines[m.xx])
			DO CASE
			CASE m.lcLine = "FUNCTION "
				m.lcLine = STRTRAN(m.lcLine, "FUNCTION ", "PROCEDURE ", 1, 1, 1)
			CASE UPPER(ALLTRIM(m.lcLine)) = "ENDFUNC"
				m.lcLine = "ENDPROC"
			CASE m.lcLine = "*!*" AND CHR(9) + "FUNCTION " $ UPPER(m.lcLine)
				m.lcLine = STRTRAN(m.lcLine, "FUNCTION ", "PROCEDURE ", 1, 1, 1)
			CASE m.lcLine = "*!*" AND CHR(9) + "ENDFUNC" $ UPPER(m.lcLine)
				m.lcLine = STRTRAN(m.lcLine, "ENDFUNC", "ENDPROC", 1, 1, 1)
			ENDCASE
			m.laLines[m.xx] = m.lcLine
		NEXT
	ENDIF

	ERASE (m.tcClassPRG)
	FOR EACH m.lcLine IN m.laLines
		STRTOFILE(m.lcLine + CHR(13) + CHR(10), m.tcClassPRG, .T.)
	NEXT
	ENDFUNC
********************************************************************


**********************************************************************
 ENDDEFINE && CLASS
**********************************************************************

