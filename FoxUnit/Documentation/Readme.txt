
FAQ

Q. What is FoxUnit?
A. FoxUnit is an open-source unit testing framework for Microsoft Visual FoxPro®. It is based on unit testing frameworks as described in Kent Beck's book "Test Driven Development by Example" but takes a more pragmatic approach to unit testing for Visual FoxPro than a more purist xUnit implementation would.


Q.  What is required to run FoxUnit?
A.  FoxUnit requires Microsoft Visual FoxPro® 8 or higher. If running VFP 9, there are UI enhancements that take advantage of new features in VFP 9.


Q.  Why did we do it?
A.  It is our hope that FoxUnit will promote the growth of Test-Driven Development with Visual FoxPro in order to expand interest in Visual FoxPro development.



FoxUnit QuickStart 	

Steps to getting up and running with FoxUnit:

1. Download and Unzip the current FoxUnit zip file into your root project folder (make sure you "use folder names" when unzipping unless you first create a FoxUnit folder underneath your project root.You will need to add the FoxUnit folder to your VFP path. You may also install FoxUnit using Thor.

As a best practice, add a \Tests folder underneath your project root and add it to your path as well. You should include your tests folder to your project in whatever source control repository you are using for your project. It is vital to the test-driven process that your tests should always stay with your source both for refactoring, and to document the intent of the code that is being tested.

2. Do FXU.prg or FoxUnit.app from a command window. If using Thor's custom menus, assign a keystroke to invoke FoxUnit.app (eg. Ctrl+Alt_U).

3. To add your first test class, click the [Create New Test Class] button in the toolbar. If you are putting your test in the tests folder, then include the path in the inputbox (e.g., Tests\MyFirstTestClass) and click the [OK] button.

A test class will load into code editing window for you. Any method name that is not already declared in the FxuTestCase superclass will be recognized by the FoxUnit form when it's loaded in. Add a method to the class, add an assert or several asserts to the method in addition to the functionality you want to test drive. Remember... little (baby) steps.

There are three important methods to use at this point. AssertEquals, AssertTrue, and AssertNotNull. There are many others, but these are good starting assertions. Use these methods to show the intent of, and then test, the code to be tested. Intellisense should bring up this methods along with their arguments. An example would be this.AssertEquals(1,1,'Does one equal one?'). This assertion would be successful (and give us the green bar!!!). 

It is a good idea to create one "test class" (.prg) for every FoxPro class (object), and write multiple assertions for every method of that class. Instantiate the object once in the Setup() method of your test class. If you have cleanup that needs to be performed after the test, do this in the TearDown() method of your test class.
