## FoxUnit code sample

Notice that each **Test Class** can contain multiple **Tests**, which are simply individual procedures defined within the class.


	Define Class CustomerTestClass As FxuTestCase Of FxuTestCase.prg

		oObject = .Null.

		Procedure Setup
		This.oObject = Createobject("cCustomerClass")
		Endproc

		Procedure testGetCustomer
			llReturn = This.oObject.GetCustomer("AKSEL")
			This.AssertTrue(llReturn, "Customer number not found.")
			If llReturn
				This.MessageOut("Customer name is  " + This.oObject.CustName)
			Endif
		Endproc

		Procedure testRaiseCreditLimit
			loCustomer = This.oObject
			lnOriginalCreditLimit = loCustomer.oData.credit_limit
			loCustomer.SetCreditLimit(lnOriginalCreditLimit + 100)
			This.AssertTrue(loCustomer.oData.credit_limit > lnOriginalCreditLimit, "Error: Credit limit not increased.")
		Endproc
		
		Procedure TearDown()
		&& Add any cleanup code here.
		Endproc
	EndDefine


**Asserts**
These Assert methods can be used to test actual values against expected values, with output text to be displayed when the Assert statement is not met.

	AssertEquals(tuExpectedValue, tuExpression, tcMessage,tuNonCaseSensitiveStringComparison)
	(AssertEquals now accepts objects as well as scalar variables)
	AssertEqualsArrays(@taArray1, @taArray2, tcMessage)
	AssertNotEqualsArrays(@taArray1, @taArray2, tcMessage)

	AssertTrue(tuExpression, tcMessage)
	AssertFalse(tuExpression, tcMessage)
	AssertNotEmpty(tuExpression, tcMessage)
	AssertNotNull(tuExpression, tcMessage)
	AssertNotNullOrEmpty(tuExpression, tcMessage)

	AssertIsObject(toObject, tcMessage)
	AssertIsNotObject(toObject, tcMessage)

	AssertHasError(tcMessage, toException, taStackInfo)
	AssertHasErrorNo(tcMessage, toException, tnErrorNo, taStackInfo)

	AssertNotImplemented(tcMessage)  (The new default return value for new tests)


**Other methods**
Additionally, these methods are frequently used when creating tests:


	SetUp() && Called automatically at beginning of each test
	TearDown() && Called automatically at the end of each test
	MessageOut(tcMessage) && Message will be displayed in the UI


* **Setup()** method should contain any common code that is needed for each test -- such as setting up paths or instantiating objects.
* **TearDown()** method contains any cleanup code that should be run at the end of each test method.
* **MessageOut()** - Add any text output from your test methods that you wish to display in the Messages pane of the FoxUnit UI.