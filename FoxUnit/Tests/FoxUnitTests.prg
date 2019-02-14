**********************************************************************
DEFINE CLASS FoxUnitTests as FxuTestCase OF FxuTestCase.prg
**********************************************************************
	#IF .f.
	*
	*  this LOCAL declaration enabled IntelliSense for
	*  the THIS object anywhere in this class
	*
	LOCAL THIS AS TestClass1 OF TestClass1.PRG
	#ENDIF
	
	*  
	*  declare properties here that are used by one or
	*  more individual test methods of this class
	*
	*  for example, if you create an object to a custom
	*  THIS.Property in THIS.Setup(), estabish the property
	*  here, where it will be available (to IntelliSense)
	*  throughout:
	*
*!*		ioObjectToBeTested = .NULL.
*!*		icSetClassLib = SPACE(0)


	* the icTestPrefix property in the base FxuTestCase class defaults
	* to "TEST" (not case sensitive). There is a setting on the interface
	* tab of the options form (accessible via right-clicking on the
	* main FoxUnit form and choosing the options item) labeld as
	* "Load and run only tests with the specified icTestPrefix value in test classes"
	*
	* If this is checked, then only tests in any test class that start with the
	* prefix specified with the icTestPrefix property value will be loaded
	* into FoxUnit and run. You can override this prefix on a per-class basis.
	*
	* This makes it possible to create ancillary methods in your test classes
	* that can be shared amongst other test methods without being run as
	* tests themselves. Additionally, this means you can quickly and easily 
	* disable a test by modifying it and changing it's test prefix from
	* that specified by the icTestPrefix property
	
	* Additionally, you could set this in the INIT() method of your derived class
	* but make sure you dodefault() first. When the option to run only
	* tests with the icTestPrefix specified is checked in the options form,
	* the test classes are actually all instantiated individually to pull
	* the icTestPrefix value.

*!*		icTestPrefix = "<Your preferred prefix here>"
	
	********************************************************************
	FUNCTION Setup
	********************************************************************
	*
	*  put common setup code here -- this method is called
	*  whenever THIS.Run() (inherited method) to run each
	*  of the custom test methods you add, specific test
	*  methods that are not inherited from FoxUnit
	*
	*  do NOT call THIS.Assert..() methods here -- this is
	*  NOT a test method
	*
    *  for example, you can instantiate all the object(s)
    *  you will be testing by the custom test methods of 
    *  this class:
*!*		THIS.icSetClassLib = SET("CLASSLIB")
*!*		SET CLASSLIB TO MyApplicationClassLib.VCX ADDITIVE
*!*		THIS.ioObjectToBeTested = CREATEOBJECT("MyNewClassImWriting")

	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION TearDown
	********************************************************************
	*
	*  put common cleanup code here -- this method is called
	*  whenever THIS.Run() (inherited method) to run each
	*  of the custom test methods you add, specific test
	*  methods that are not inherited from FoxUnit
	*
	*  do NOT call THIS.Assert..() methods here -- this is
	*  NOT a test method
	*
    *  for example, you can release  all the object(s)
    *  you will be testing by the custom test methods of 
    *  this class:
*!*	    THIS.ioObjectToBeTested = .NULL.
*!*		LOCAL lcSetClassLib
*!*		lcSetClassLib = THIS.icSetClassLib
*!*		SET CLASSLIB TO &lcSetClassLib        

	********************************************************************
	ENDFUNC
	********************************************************************	

	*
	*  test methods can use any method name not already used by
	*  the parent FXUTestCase class
	*    MODIFY COMMAND FXUTestCase
	*  DO NOT override any test methods except for the abstract 
	*  test methods Setup() and TearDown(), as described above
	*
	*  the three important inherited methods that you call
	*  from your test methods are:
	*    THIS.AssertTrue("Failure message",<Expression>)
	*    THIS.AssertEquals("Failure message",<ExpectedValue>,<Expression>)
	*    THIS.AssertNotNull("Failure message",<Expression>)
	*  all test methods either pass or fail -- the assertions
	*  either succeed or fail
    
	*
	*  here's a simple AssertNotNull example test method
	*
*!*		*********************************************************************
*!*		FUNCTION TestObjectWasCreated
*!*		*********************************************************************
*!*		THIS.AssertNotNull(THIS.ioObjectToBeTested, ;
*!*			"Object was not instantiated during Setup()")
*!*		*********************************************************************
*!*		ENDFUNC
*!*		*********************************************************************

	*
	*  here's one for AssertTrue
	*
*!*		*********************************************************************
*!*		FUNCTION TestObjectCustomMethod 
*!*		*********************************************************************
*!*		THIS.AssertTrue(THIS.ioObjectToBeTested.CustomMethod()), ;
			"Object.CustomMethod() failed")
*!*		*********************************************************************
*!*		ENDFUNC
*!*		*********************************************************************

	*
	*  and one for AssertEquals
	*
*!*		*********************************************************************
*!*		FUNCTION TestObjectCustomMethod100ReturnValue 
*!*		*********************************************************************
*!*
*!*		* Please note that string Comparisons with AssertEquals are
*!*		* case sensitive. 
*!*
*!*		THIS.AssertEquals("John Smith", ;
*!*			            THIS.ioObjectToBeTested.Object.CustomMethod100(), ;
*!*			            "Object.CustomMethod100() did not return 'John Smith'",
*!*		*********************************************************************
*!*		ENDFUNC
*!*		*********************************************************************



FUNCTION testAssertTrue
this.AssertTrue(.t., "This is not true.")


FUNCTION testAssertFalse
this.AssertFalse(.f., "This is not false.")

FUNCTION testAssertNotNull
This.AssertNotNull("Not Null", "This is null")

FUNCTION testAssertNotEmpty
This.AssertNotEmpty(1, "This is empty")

FUNCTION testAssertNotNullOrEmpty
This.AssertNotNullOrEmpty(1, "This is null or empty")

FUNCTION testAssertEquals
this.assertequals("Test String 1","Test String 1","These strings don't match")

  FUNCTION testEscapeWorks
	* 1. Change the name of the test to reflect its purpose. Test one thing only.
	* 2. Implement the test by removing these comments and the default assertion and writing your own test code.
	* Give time to hit Escape
	* Long running test
	FOR x = 1 TO 10000000
		x = x + 1 
	NEXT
	
  RETURN This.AssertFalse(.f. , "Escape Key was Hit")
  
  
FUNCTION testAssertEqualsCaseInsensitive
this.assertequals("Test String 1", "TEST STRING 1","These strings don't match", .t.)

FUNCTION testAssertEqualsNumbers
this.assertequals(100,100,"These numbers don't match")

FUNCTION testAssertEqualsBoolean
this.assertequals(.f.,.f.,"These boolean don't match")

FUNCTION testAssertEqualsObjects
LOCAL o1, o2
o1 = CREATEOBJECT("Empty")
o2 = CREATEOBJECT("Empty")
ADDPROPERTY(o1,"Property1",100)
ADDPROPERTY(o2,"Property1",100)

this.assertequals(o1,o2,"These objects are not equal.")



  ENDFUNC


  FUNCTION testAssertEqualsArrays
  DIMENSION a1[2,2], a2[2,2]
  a1[1,1]=DATETIME()
  a1[1,2]=TIME()
  a1[2,1]=RAND()
  a1[2,2]=_vfp  
  a2[1,1]=a1[1,1]
  a2[1,2]=a1[1,2]
  a2[2,1]=a1[2,1]
  a2[2,2]=a1[2,2]

	This.assertEqualsArrays(@a1,@a2,"These arrays are not equal")
	

  FUNCTION testAssertNotEqualsArrays
  DIMENSION a1[2,2], a2[2,2]
  a1[1,1]=DATETIME()
  a1[1,2]=TIME()
  a1[2,1]=RAND()
  a2[2,2]=_vfp  
  a2[1,1]=DATETIME()
  a2[1,2]=TIME()
  a2[2,1]=RAND()
  a2[2,2]=_screen
  This.assertNotEqualsArrays(@a1,@a2,"These arrays are actually equal")
		  

  ENDFUNC


  FUNCTION testAssertIsObject
	LOCAL o1
	o1 = CREATEOBJECT("Empty")
	This.assertIsObject(o1, "This is not an object")
	  
  ENDFUNC

  FUNCTION testAssertIsNotObject
	This.assertIsNotObject(DATETIME(), "This is an object")
  ENDFUNC


  FUNCTION testCompareJSON
	* 1. Change the name of the test to reflect its purpose. Test one thing only.
	* 2. Implement the test by removing these comments and the default assertion and writing your own test code.
	
  * This.MessageOut("Getting ready to run this test!")
  TEXT TO cExpected 
  [
	{
		color: "red",
		value: "#f00"
	},
	{
		color: "green",
		value: "#0f0"
	},
	{
		color: "blue",
		value: "#00f"
	},
	{
		color: "cyan",
		value: "#0ff"
	},
	{
		color: "magenta",
		value: "#f0f"
	},
	{
		color: "yellow",
		value: "#ff0"
	},
	{
		color: "black",
		value: "#000"
	}
]
ENDTEXT
TEXT TO cActual
[
	{
		color: "red",
		value: "#f00"
	},
	{
		color: "green",
		value: "#0f0"
	},
	{
		color: "bleu",
		value: "#00f"
	},
	{
		color: "cyan",
		value: "#0ff"
	},
	{
		color: "magenta",
		value: "#f0f"
	},
	{
		color: "yellow",
		value: "#ff0"
	},
	{
		color: "black",
		value: "#000"
	}
]
ENDTEXT
	This.assertEquals(cExpected, cActual, "As expected, they don't match.")
  ENDFUNC
  
  Dimension testTheory_Data[3,2]
  testTheory_Data[1,1] = 1
  testTheory_Data[1,2] = 2
  testTheory_Data[2,1] = 3
  testTheory_Data[2,2] = 6
  testTheory_Data[3,1] = 5
  testTheory_Data[3,2] = 10
  Procedure testTheory (tnValue, tnResult)
  	this.AssertEquals (m.tnResult, 2*m.tnValue)
  EndProc

**********************************************************************
ENDDEFINE
**********************************************************************
