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
DEFINE CLASS FxuFileIO as FxuCustom OF FxuCustom.prg
**********************************************************************

	ioFs = .NULL.
	
	********************************************************************
	FUNCTION INIT
	********************************************************************
	
		this.ioFs = CREATEOBJECT("scripting.filesystemobject")
	
	********************************************************************
	ENDFUNC
	********************************************************************

	********************************************************************
	FUNCTION GetCaseSensitiveFileName(tcFullPathToFile, tlReturnFullPath)
	********************************************************************
	
		IF !EMPTY(tlReturnFullPath)
			tlReturnFullPath = .t.
		ELSE
			tlReturnFullPath = .f.
		ENDIF
		
	
		LOCAL loFs as Scripting.FileSystemObject
		LOCAL loFile as Scripting.File
		LOCAL lcCaseSensitiveFileName
		
		loFs = CREATEOBJECT("Scripting.FileSystemObject")
		loFile = loFs.GetFile(tcFullPathToFile)
		
		IF tlReturnFullPath
			lcCaseSensitiveFileName = loFile.Path
		ELSE
			lcCaseSensitiveFileName = loFile.Name
		ENDIF
		 
		RELEASE loFile
		RELEASE loFs
		
		RETURN lcCaseSensitiveFileName  
	
	********************************************************************
	ENDFUNC
	********************************************************************	

	********************************************************************
	FUNCTION RenameFile(tcOldFileName, tcNewFileName)
	********************************************************************
	* Note that the file name parameters require the full path
	
		LOCAL loFs as Scripting.FileSystemObject
		loFs = CREATEOBJECT("scripting.FileSystemObject")
		
		loFs.MoveFile(tcOldFileName,tcNewFileName)
	
		RELEASE loFs
	
	********************************************************************
	ENDFUNC
	********************************************************************


**********************************************************************
ENDDEFINE && CLASS
**********************************************************************