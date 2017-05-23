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

RETURN CREATEOBJECT("FxuTestCaseEnumerator")

**********************************************************************
DEFINE CLASS FxuTestCaseEnumerator as FxuCustom OF FxuCustom.prg
**********************************************************************

	#if .f.
		LOCAL this as FxuTestCaseEnumerator OF FxuTestCaseEnumerator.prg
	#endif
	
	ioFxuInstance = .NULL.
	
	PROCEDURE Init
		PARAMETERS toFxuInstance
		
		IF VARTYPE(m.toFxuInstance)!="O" OR ISNULL(m.toFxuInstance)
			ERROR 1924, "m.toFxuInstance"
			RETURN .F.
		ENDIF
		this.ioFxuInstance=m.toFxuInstance
	ENDPROC
	
	********************************************************************
	FUNCTION ReadTestNames(tcProgramFile, tcClass)
	********************************************************************
	*
	*	Returns string of methods that begin with the word "test"
	*	in the class specified of the program file specified
	* 	as a list that is line feed delimited (so alines can pull
	*	it apart into an array after its returned)
	*
	********************************************************************
  
	    ASSERT FILE(m.tcProgramFile) MESSAGE "FoxUnit:  Cannot locate test case file." && HAS
	
		LOCAL ARRAY laProcedures[1]
		
		LOCAL lnProcedures
		LOCAL lnTotalTestMethods
		LOCAL lnX, lnDotPos
		LOCAL lcMethods, lcCurrentProcedure
		LOCAL llFoundClass
		LOCAL lcSuperclassMethodsList
		LOCAL loTestResult as FxuTestResult OF FxuTestResult.prg
		LOCAL loTestCase as FxuTestCase OF FxuTestCase.prg
		LOCAL lcTestPrefix, lnTestPrefixLength
		LOCAL llHonorTestPrefix
		
		llHonorTestPrefix = .t.
		lcTestPrefix = ""
		lnTestPrefixLength = 0
		
		IF VARTYPE(goFoxUnitForm) == "O"
			*IF !ISNULL(goFoxUnitForm) && This test is unnecessary. HAS
				llHonorTestPrefix = goFoxUnitForm.ilHonorTestPrefix
			*ENDIF 
		ENDIF 
		
		*tcProgramFile = JUSTSTEM(tcProgramFile) + ".prg"
    	tcProgramFile = FORCEEXT(tcProgramFile, "prg") && HAS
		
		IF EMPTY(tcClass)
			tcClass = JUSTSTEM(tcProgramFile)
		ENDIF
		
		llFoundClass = .f.
		
		lcMethods = ''
		
		IF llHonorTestPrefix 
		
			loTestResult = this.ioFxuinstance.FxuNewObject("FxuTestResult")
			loTestCase = NEWOBJECT(tcClass,tcProgramFile,.NULL.,loTestResult)
			
			lcTestPrefix = ALLTRIM(UPPER(loTestCase.icTestPrefix))
			lnTestPrefixLength = LEN(lcTestPrefix)
			
			RELEASE loTestCase, loTestResult
		
		ENDIF 

		lcSuperclassMethodsList = this.ReadSuperclassMethods(tcProgramFile, tcClass)
			
		lnProcedures = APROCINFO(laProcedures,tcProgramFile,2)
		
		FOR lnX = 1 TO lnProcedures
		
			lcCurrentProcedure = laProcedures(lnX,1)
			lnDotPos = AT(".",lcCurrentProcedure,1)
			lcClass = LEFT(lcCurrentProcedure,lnDotPos - 1)
			
			IF UPPER(lcClass) == UPPER(tcClass) 
				
				llFoundClass = .t.
				
				lcCurrentMethod = SUBSTR(lcCurrentProcedure,lnDotPos + 1,150) && FDBOZZO. Fix from 100 to 150
				*IF UPPER(LEFT(lcCurrentMethod,4)) == "TEST"
				IF ATC("|"+UPPER(lcCurrentMethod)+"|", lcSuperclassMethodsList) = 0 ;
					AND LEFT(UPPER(lcCurrentMethod),lnTestPrefixLength) == lcTestPrefix
					  
					IF !EMPTY(lcMethods)
						lcMethods = lcMethods + CHR(13)
					ENDIF
					
					lcMethods = lcMethods + SUBSTR(lcCurrentProcedure,lnDotPos + 1,150) && FDBOZZO. Fix from 100 to 150
					
				ENDIF
				
			ELSE
			
				IF llFoundClass
					EXIT
				ENDIF
				
			ENDIF
		
		ENDFOR
		
		
		IF EMPTY(lcMethods)
			lcMethods = "(NONE)"
		ENDIF
		
		RETURN lcMethods
	
	********************************************************************
	ENDFUNC
	********************************************************************
		
	********************************************************************
	FUNCTION ReadTestClasses(tcProgramFile, tcBaseTestClass)
	********************************************************************
	*
	*	Returns a list of classes in the prg specified that inherit
	*	from the class specified in tcBaseTestClass. If tcBaseTestClass
	*	is left empty, the parent class "FxuTestCase" (the foxunit base testcase
	*	class) is asssumed. This allows a developer to enumerate through
	* 	a set of classes that inherit from their implementation of the
	*	testbaseclass.
	*
	*********************************************************************
	
		LOCAL lcTestClasses
		lcTestClasses = ''
		LOCAL ARRAY laClasses[1]
		LOCAL lnX
		LOCAL lnClasses
		
		IF EMPTY(tcBaseTestClass)
		
			tcBaseTestClass = "FXUTESTCASE"
			
		ELSE
		
			tcBaseTestClass = UPPER(ALLTRIM(tcBaseTestClass))
		
		ENDIF
		
		lnClasses = APROCINFO(laClasses,tcProgramFile,1)
		
		FOR lnX = 1 TO lnClasses
		
			IF UPPER(laClasses(lnx,3)) == tcBaseTestClass
				IF !EMPTY(lcTestClasses)
					lcTestClasses = lcTestClasses + CHR(13)
				ENDIF
				
				lcTestClasses = lcTestClasses + laClasses(lnX,1)
				
			ENDIF
			
		
		ENDFOR
		
		
		RETURN lcTestClasses
	
	********************************************************************
	ENDFUNC
	********************************************************************

	********************************************************************
	PROTECTED FUNCTION GetSuperclass(tcProgramFile, tcClass)
	********************************************************************
	*
	* Returns class that tcClass inherits from in tcProgramFile
	*
	********************************************************************
	
		LOCAL lnNumClasses, laClassInfo[1], i

		tcProgramFile = FORCEEXT(tcProgramFile, ".prg")

		IF EMPTY(tcClass)
			tcClass = JUSTSTEM(tcProgramFile)
		ENDIF

		lnNumClasses = APROCINFO(laClassInfo, tcProgramFile, 1)
		
		lcSuperclass = ""
		FOR i = 1 TO lnNumClasses
			IF UPPER(ALLTRIM(laClassInfo[i, 1])) == UPPER(ALLTRIM(tcClass))
				lcSuperclass = UPPER(ALLTRIM(laClassInfo[i,3]))
			ENDIF
		ENDFOR
		
		RETURN lcSuperclass
	
	********************************************************************
	ENDFUNC
	********************************************************************

	********************************************************************
	PROTECTED FUNCTION ReadSuperClassMethods(tcProgramFile, tcClass)
	********************************************************************
	

		LOCAL loTestResult, loTestCaseSuperClass, lnMembers, laMembers[1]
		LOCAL lcCurrentMethod, lcMethodList, lcSuperClass, lcSuperClassFile
		STORE "" TO lcCurrentMethod, lcMethodList
		
		tcProgramFile = FORCEEXT(tcProgramFile, ".prg")

		IF EMPTY(tcClass)
			tcClass = JUSTSTEM(tcProgramFile)
		ENDIF  
		tcClass = CHRTRAN(tcClass,' ','')
		
		lcSuperclass = this.GetSuperclass(tcProgramFile, tcClass)
		lcSuperclassFile = DEFAULTEXT(lcSuperclass, "prg")

		IF NOT EMPTY(lcSuperClass)

			* Instantiate a test result to be passed to the creation
			* the TestCase superclass specified
			loTestResult = this.ioFxuInstance.FxuNewObject("FxuTestResult")
			* Instantiate the TestCase SuperClass in order to enumerate members
			loTestCase = NEWOBJECT(lcSuperClass,lcSuperClassFile,.NULL., m.loTestResult, this.ioFxuInstance)
			
			* Enumerate the members of the TestCase SuperClass
			lnMembers = AMEMBERS(laMembers,loTestCase,1)
			
			* Release the objects
			RELEASE loTestCase, loTestResult
			
			FOR lnX = 1 TO lnMembers
				IF laMembers[lnX,2] == "Method"
					IF !EMPTY(lcMethodList)
						lcMethodList = lcMethodList + "|"
					ENDIF 
					lcMethodList = lcMethodList + UPPER(ALLTRIM(laMembers[lnX,1])) 
				ENDIF 
			ENDFOR
		ENDIF 
		
		RETURN "|" + lcMethodList + "|"
		
		
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
**********************************************************************
ENDDEFINE && CLASS
**********************************************************************