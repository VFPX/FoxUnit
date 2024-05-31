# FoxUnit 目录结构

FoxUnit 项目的文件夹层次结构包含五个目录：

`.\Documentation` 包含文本文件，提供有关 FoxUnit 项目的一般信息以及许可证和开发人员信息。

`.\Graphics` 存放整个 FoxUnit 项目中使用的所有图片和图标文件 - 没有屏幕截图或其他文档文件。

`.\Source` FoxUnit 源代码文件。

`.\Text` 包含两个内置测试用例的模板资源文件。

`.\Tests` 提供了一个存储测试的地方 -  FoxUnit 提供的测试可以从一开始就在这里找到。

位于这些子目录中的所有文件都包含在构建的 FoxUnit 应用程序文件中。 如果要将 FoxUnit 部署到开发人员团队，只需提供 FoxUnit 应用程序文件和类工厂基表（见下文）。 您还可以使用 SCC 系统部署 FoxUnit ，因为这些所需的文件都不必是可写的。

## FoxUnit Path

术语 FoxUnit Path 指的是 FoxUnit 项目的主目录或包含 FoxUnit 应用程序文件的目录（例如 FoxUnit.app），具体取决于 FoxUnit 的启动方式。 如果 FoxUnit 是通过执行 FXU.PRG 运行的，那么 FoxUnit Path 就是 FoxUnit.pjx 的路径。 如果 FoxUnit 作为已编译的二进制文件（例如 FoxUnit.app）启动，则 FoxUnit 路径是包含该文件的目录。 根据自述文件中提到的建议，必须在 Visual FoxPro 搜索路径中配置 FoxUnit 路径。 因此，FoxUnit Path 应该是存储可重用测试用例类及其相应模板文件的首选。

## FoxUnit 数据目录

这是存储测试结果和 FoxUnit 设置的地方。 FoxUnit 数据目录始终指向名为 Tests 的目录，但该目录是特定于项目的。 如果有可用的项目，FoxUnit 数据目录是项目主目录的子文件夹 Tests。 如果没有可用的项目，则 FoxUnit 数据路径是当前目录的子文件夹 Tests。

## `FxuClassFactoryBase.dbf`

类工厂基表

这个文件对 FoxUnit 的类工厂至关重要。 它必须位于 FoxUnit Path 中。 它不需要是可写的。 如果它丢失或损坏，FoxUnit 将无法启动。

## `FxuClassFactory.dbf`

类工厂表

FoxUnit 类工厂使用的第二个文件。这个文件也位于 FoxUnit Path，但是如果它不存在会被自动创建。 

## `FXURresults.dbf`

FoxUnit 结果表

测试结果存储在这些表文件中。 由于测试结果在大多数情况下是项目特定的，因此测试结果文件存储在 FoxUnit 数据目录中。

## `FXUPersist*.xml`

FoxUnit 设置文件

FoxUnit 中使用的几种形式将其设置保留在此类文件中。 所有设置都按用户保存，文件存储在 FoxUnit 数据目录中，因此实际上每个用户和每个项目都维护所有设置。 由于它们的易变性，这些文件也没有部署在 FoxUnit 下载包中。
