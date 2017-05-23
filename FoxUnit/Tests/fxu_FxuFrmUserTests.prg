**********************************************************************
DEFINE CLASS fxu_FxuFrmUserTests as FxuTestCase OF FxuTestCase.prg
**********************************************************************

	#IF .f.
	LOCAL THIS AS fxu_FxuFrmUserTests OF fxu_FxuFrmUserTests.PRG
	#ENDIF
	
	icPath = ""
	
	********************************************************************
	FUNCTION Setup
	********************************************************************
		this.icPath = SET("Path")
		SET PATH TO HOME(1)
		SET PATH TO (SYS(5)+SYS(2003)+"\Source") ADDITIVE
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION TearDown
	********************************************************************
		IF !EMPTY(this.icPath)
			SET PATH TO (this.icPath)
		ENDIF
	********************************************************************
	ENDFUNC
	********************************************************************	

	FUNCTION InitTest
		LOCAL loException as Exception
		LOCAL loFxuFrmUser AS fxufrmuser OF "fxu.vcx"
		
		TRY
			m.loFxuFrmUser=NEWOBJECT("fxufrmuser", "fxu.vcx")
			this.asserttrue(.F.,	"An exception was expected to be thrown when fxu.vcx/FxuFrmUser is instantiated without passing a valid FxuInstance reference!")
		CATCH TO m.loException WHEN m.loException.ErrorNo==1924
		CATCH TO m.loException
			this.asserttrue(.F.,	"A different exception was expected to be thrown when fxu.vcx/FxuFrmUser is instantiated without passing a valid FxuInstance reference! " + ;
									"Instead, this exception came up: ErrorNo={" + TRANSFORM(m.loException.ErrorNo) + "}, Message={" + m.loException.Message + "}")
		ENDTRY
		
		m.loFxuFrmUser=NEWOBJECT("fxufrmuser", "fxu.vcx", "", This.ioFxuInstance)
		IF !this.assertisobject(m.loFxuFrmUser)
			RETURN
		ENDIF
	ENDFUNC
	
	FUNCTION SettingsSaveTest
		LOCAL lnUsedInitially
		LOCAL ARRAY laUsed[1]
		m.lnUsedInitially=AUSED(m.laUsed)
		
		LOCAL loFxuFrmUser AS fxufrmuser OF "fxu.vcx"
		m.loFxuFrmUser=NEWOBJECT("fxufrmuser", "fxu.vcx", "", This.ioFxuInstance)
		IF !this.assertisobject(m.loFxuFrmUser)
			RETURN
		ENDIF
		
		LOCAL lcPersistFileActual, lcPersistFileExpected
		m.lcPersistFileExpected=FULLPATH(ADDBS(this.iofxuinstance.DataPath) + ".\FXUPersist" + m.loFxuFrmUser.Class + ".xml")
		IF FILE(m.lcPersistFileExpected, 1)
			DELETE FILE (m.lcPersistFileExpected)
		ENDIF
		IF this.asserttrue(m.loFxuFrmUser.SettingsSave(@m.lcPersistFileActual))
			this.assertequals(m.lcPersistFileExpected, m.lcPersistFileActual, , .T.)
		ENDIF
		IF this.asserttrue(FILE(m.lcPersistFileActual, 1))
			this.asserttrue(m.loFxuFrmUser.SettingsSave(@m.lcPersistFileActual))
			DELETE FILE (m.lcPersistFileExpected)
		ENDIF
		this.assertequals(m.lnUsedInitially, AUSED(m.laUsed), "Found more cursors than expected!")
		
		m.lcPersistFileActual	= "FXUPersistTest.xml"
		m.lcPersistFileExpected	=FULLPATH(m.lcPersistFileActual)
		IF this.asserttrue(m.loFxuFrmUser.SettingsSave(@m.lcPersistFileActual))
			this.assertequals(m.lcPersistFileExpected, m.lcPersistFileActual, , .T.)
		ENDIF
		IF this.asserttrue(FILE(m.lcPersistFileActual, 1))
			DELETE FILE (m.lcPersistFileActual)
		ENDIF
		this.assertequals(m.lnUsedInitially, AUSED(m.laUsed), "Found more cursors than expected!")
	ENDFUNC
	
	FUNCTION SettingsRestoreTest
		LOCAL lnUsedInitially
		LOCAL ARRAY laUsed[1]
		m.lnUsedInitially=AUSED(m.laUsed)
		
		LOCAL loFxuFrmUser AS fxufrmuser OF "fxu.vcx"
		m.loFxuFrmUser=NEWOBJECT("fxufrmuser", "fxu.vcx", "", This.ioFxuInstance)
		IF !this.assertisobject(m.loFxuFrmUser)
			RETURN
		ENDIF
		
		LOCAL lcPersistFileActual, lcPersistFileExpected
		m.lcPersistFileExpected=FULLPATH(ADDBS(this.iofxuinstance.DataPath) + ".\FXUPersist" + m.loFxuFrmUser.Class + ".xml")
		IF FILE(m.lcPersistFileExpected, 1)
			DELETE FILE (m.lcPersistFileExpected)
		ENDIF
		IF this.assertfalse(m.loFxuFrmUser.SettingsRestore(@m.lcPersistFileActual))
			this.assertequals(m.lcPersistFileExpected, m.lcPersistFileActual, , .T.)
		ENDIF
		IF !this.assertfalse(FILE(m.lcPersistFileActual, 1))
			DELETE FILE (m.lcPersistFileActual)
		ENDIF
		IF this.asserttrue(m.loFxuFrmUser.SettingsSave(@m.lcPersistFileActual))
			this.asserttrue(m.loFxuFrmUser.SettingsRestore(@m.lcPersistFileActual))
		ENDIF
		this.assertequals(m.lnUsedInitially, AUSED(m.laUsed), "Found more cursors than expected!")
		
		m.lcPersistFileActual	= "FXUPersistTest.xml"
		m.lcPersistFileExpected	=FULLPATH(m.lcPersistFileActual)
		IF this.asserttrue(m.loFxuFrmUser.SettingsSave(@m.lcPersistFileExpected))
			IF this.asserttrue(m.loFxuFrmUser.SettingsRestore(@m.lcPersistFileActual))
				this.assertequals(m.lcPersistFileExpected, m.lcPersistFileActual, , .T.)
			ENDIF
		ENDIF
		IF this.asserttrue(FILE(m.lcPersistFileActual, 1))
			DELETE FILE (m.lcPersistFileActual)
		ENDIF
		this.assertequals(m.lnUsedInitially, AUSED(m.laUsed), "Found more cursors than expected!")
	ENDFUNC
	
	FUNCTION OnSettingsSaveTest
		LOCAL lnUsedInitially
		LOCAL ARRAY laUsed[1]
		m.lnUsedInitially=AUSED(m.laUsed)
		
		LOCAL loFxuFrmUser AS fxufrmuser_test OF "fxu_FxuFrmUserTests.prg"
		m.loFxuFrmUser=NEWOBJECT("fxufrmuser_test", "Tests\fxu_FxuFrmUserTests.prg", "", This.ioFxuInstance)
		IF !this.assertisobject(m.loFxuFrmUser)
			RETURN
		ENDIF

		this.assertfalse(m.loFxuFrmUser.onsettingssave_test())
		
		LOCAL lcAliasTest
		m.lcAliasTest="test"+SYS(2015)
		IF this.assertfalse(USED(m.lcAliasTest))
			this.assertfalse(m.loFxuFrmUser.onsettingssave_test(m.lcAliasTest))
		ENDIF
		
		CREATE CURSOR (m.lcAliasTest) (USERID C(15), Setting M)
			this.asserttrue(m.loFxuFrmUser.onsettingssave_test(m.lcAliasTest))
		USE IN SELECT(m.lcAliasTest)
		
		this.assertequals(m.lnUsedInitially, AUSED(m.laUsed), "Found more cursors than expected!")
	ENDFUNC
	
	FUNCTION ioFxuInstance_AssignTest
		LOCAL lnUsedInitially
		LOCAL ARRAY laUsed[1]
		m.lnUsedInitially=AUSED(m.laUsed)
		
		LOCAL loFxuFrmUser AS fxufrmuser OF "fxu.vcx"
		m.loFxuFrmUser=NEWOBJECT("fxufrmuser", "fxu.vcx", "", This.ioFxuInstance)
		IF !this.assertisobject(m.loFxuFrmUser)
			RETURN
		ENDIF
		
		LOCAL loException as Exception
		TRY
			m.loFxuFrmUser.ioFxuInstance=This.ioFxuInstance
			this.asserttrue(.F.,	"An exception was expected to be thrown on any attempt to write to the ioFxuInstance property!")
		CATCH TO m.loException WHEN m.loException.ErrorNo==1740
		CATCH TO m.loException
			this.asserttrue(.F.,	"A different exception was expected to be thrown on any attempt to write to the ioFxuInstance property! " + ;
									"Instead, this exception came up: ErrorNo={" + TRANSFORM(m.loException.ErrorNo) + "}, Message={" + m.loException.Message + "}")
		ENDTRY
	ENDFUNC
**********************************************************************
ENDDEFINE
**********************************************************************

DEFINE CLASS FxuFrmUser_Test as fxufrmuser OF "FXU.VCX"
	FUNCTION OnSettingsSave_Test
		PARAMETERS tcAlias
		RETURN this.OnSettingsSave(@m.tcAlias)
	ENDFUNC
ENDDEFINE