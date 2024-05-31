# FoxUnit 1.5 完整更新历史

## FXU.PRG 

* 更改版本信息常量 C_Version 以反映完整的次要版本信息(1.2  - > 1.5)。
* 添加了有关通过 EXTERNAL 构建时需要的文件的编译器信息(仍然不完整)。
* 重写在交互式启动期间的代码和调用(例如，不会两次调用GetFoxUnitForm())。
* 使类 fxu 使用 FxUInstance 并清理无用的注释代码。
* 添加了 GetFoxUnitPath() 函数。
* 删除了函数 ManageFxuClassFactory() 。
* 删除了函数 CheckPath() 。
* 删除了函数 GetTestsDir() 。
* 添加了 FXUShowForm() 功能(取自FXUShowForm.prg)。
* 使函数 createFxuResultsAddAllTestsAndRun() 使用 FxuInstance 修复 bug，引入新变量 lnTest 来替换循环中的变量I，因为它与子调用中具有相同名称的变量冲突。

## FXUAssertions.prg 

* 使类 FxuAssertions 使用 FxuInstance。
* 增加新属性 ioFxuInstance。
* 强制将 FxuInstance 对象传递给 Init()，该对象存储在 ioFxuInstance 中。

##  FXUNewObject.prg, FXUShowForm.prg 

* 从项目中移除/排除 

##  FXUResultData.prg 

* 与 FXUAssertions 基本相同。

##  FXUTestCase.prg 

* 与 FXUAssertions 基本相同。
* 与 ilSuccess 属性相关的 BugFix。

## FXUTestCaseEnumerator.prg 

* 与 FXUAssertions 基本相同。 

##  FXUTestResult.prg 

* 与 ilCurrentResult 相关的 BugFix。 
 

##  FXUTestSuite.prg 

* 与 FXUAssertions 基本相同。 

## Fxu.vcx 

* 增加类 FxuInstance 
* 类 FrmFoxUnit 
	* 使表单可以使用 FxuInstance。
	* 增加新属性 ioFxuInstance。
	* 强制将 FxuTestBroker 对象传递给 Init()，该对象存储在 ioTestBroker 中，其 FxuInstance 对象 ioFxuInstance 也存储在 FrmFoxUnit 的 ioFxuInstance 中。
	* 将 Load() 中的一半代码移动到 Init()(依赖于或者可以使用 FxuInstance 进行优化，而 FxuInstance 在 Load() 中尚不可用)。
	* 实验：使 DetailsZoom() 在 VFP 内置的备注编辑窗口中打开详细信息而不是 ,frmShowInfo。 目标是改善体验并保存代码。
	* 与 BINDEVENTS() 一起使用的方法使用正确的数据工作期。
	* 更改了多个控件的 Picture 属性以直接指向图形文件，因此编译时需要这些图形文件。
	* 使一些控件的 Init() 等到 thisform.icgridrs 有效(他们的 Init() 在 form 的 Init() 之前被调用,但是一些东西从 Load() 移到了Init() ,所以并不是所有在控件的 Init() 的都可用)。
	
* 类 FrmNewTestClass 
	* 使表单使用 FxuInstance 。
	* 增加新属性 ioFxuInstance 。
	* 强制将 FxuInstance 对象传递给 Init()，该对象存储在 ioFxuInstance 中。
	* 将所有代码移离 Load()。
	* 重构了 SaveSettings() 和 RestoreSettings() 方法，使它们处理最多包含15个字符(而不是之前只有10个字符)的用户名，而不会丢失存储在文件中的现有设置。
	* 更改了 txtTestClassName.Valid() 事件中的代码，仅更改 cmdCreate 的启用状态，而不是强制用户键入一些字符以便能够离开该字段。

* 类 FxuFrmLoadClass 
	* 更改了多个控件的 Picture 属性以直接指向图形文件，因此编译时需要这些图形文件 

* 类 FxuFrmTestBroker 
	* 使表单使用 FxuInstance 。
	* 增加新属性 FxuInstance 。
	* 强制将 FxuInstance 对象传递给Init()，该对象存储在 FxuInstance 中。
