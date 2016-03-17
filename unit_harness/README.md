## Automated Unit Test Harness

by Mark Geurts <mark.w.geurts@gmail.com>
<br>Copyright &copy; 2015, University of Wisconsin Board of Regents

## Description

The Automated Unit Test Harness is a function that automatically runs a series of unit tests on the most current and previous versions of an application.  The unit test results are then written to a GitHub Flavored Markdown text file.  This function was designed to be application-independent, and receives the information it needs by executing `UnitTest()`.  Refer to this function within the application for information on how the unit tests are executed. 

This tool is used in various applications, including [viewray_mlc](https://github.com/mwgeurts/viewray_mlc), [viewray_fielduniformity](https://github.com/mwgeurts/viewray_fielduniformity), and [viewray_radiso](https://github.com/mwgeurts/viewray_radiso).
 
## Installation

To install the Automated Unit Test Harness, copy UnitTestHarness.m files from this repository into your MATLAB path.  If installing as a submodule into another git repository, execute `git submodule add https://github.com/mwgeurts/unit_harness`.

## Usage and Documentation

No input or return arguments are necessary to execute `UnitTestHarness()`. The optional string 'noprofile' may be passed, which will cause the profiler HTML save feature to be temporarily disabled.

The Automated Unit Test Harness requires the function `UnitTest()` with three different arrangements of input and output arguments.  First, during initialization `UnitTest()` is called with no input arguments, shown below.  Here, `name` is a string containing the application name (with .m extension), `referenceApp` is a string containing the path to the version application whose results will be used as reference, `priorApps` is a 1 x _n_ cell array of strings containing paths to the other _n_ applications which will be tested, `testData` contains a 2 x _m_ cell array of strings containing the name of each test suite (first column) and path to the test data (second column), and `report` is a string containing the path and name of report file (will be appended by _R201XX.md based on the MATLAB version).

```matlab
[name, referenceApp, priorApps, testData, report] = UnitTest();
```

In the second form, `UnitTest()` is called with only two input arguments and four output arguments, shown below.  The first input argument is the path to the version of the application to be executed (in this case `referenceApp`), and the second is the path to the test suite data `testData{i,2}`.  The return argument `preamble` is a cell array of strings to be printed above the results table, `t` is an 2 x _u_ cell array of strings containing the test name (first column) and result (second column), `footnotes` is a cell array of strings to be printed below the results table, and `reference` is a structure containing reference data.

```matlab
[preamble, t, footnotes, reference] = ...
     UnitTest(fullfile(cwd, referenceApp), fullfile(cwd, testData{i,2}));
```

In the third form, `UnitTest()` is called with three input arguments and three output arguments, shown below.  The first two input arguments are the same as above, but this time the `reference` structure generated from `referenceApp` above is provided back to the unit test function.  The three output variables are the same as above (note that `reference` is not returned again.

```matlab
[preamble, t, footnotes] = UnitTest(fullfile(cwd, priorApps{j}), ...
     fullfile(cwd, testData{i,2}), reference);
```

## License

Released under the GNU GPL v3.0 License.  See the [LICENSE](LICENSE) file for further details.
