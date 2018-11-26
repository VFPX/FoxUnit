## Comparing Results

Christof Wollenhaupt added a feature in version 1.7 that allows FoxUnit to use an external tool to compare the results of unit tests. This makes comparing long actual and expected values, such as JSON or XML, much easier.

Before this feature was added, comparing long values was...difficult:
![Before](FoxUnit_ComparingLongValuesBefore.png)

But clicking the Compare button brings up your favorite 3rd party tool for easy comparison:
![After](FoxUnit_ComparingLongValuesAfter.png)

### Configuring
To configure FoxUnit to use your preferred comparison/diff tool, click Options and choose the Tools tab:
![Configuring](FoxUnit_ConfigureComparisonTool.png)