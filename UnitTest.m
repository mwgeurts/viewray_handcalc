function varargout = UnitTest(varargin)
% UnitTest executes the unit tests for this application, and can be called 
% either independently (when testing just the latest version) or via 
% UnitTestHarness (when testing for regressions between versions).  Either 
% two or three input arguments can be passed to UnitTest as described 
% below.
%
% The following variables are required for proper execution: 
%   varargin{1}: string containing the path to the main function
%   varargin{2}: string containing the path to the test data
%   varargin{3} (optional): structure containing reference data to be used
%       for comparison.  If not provided, it is assumed that this version
%       is the reference and therefore all comparison tests will "Pass".
%
% The following variables are returned upon succesful completion when input 
% arguments are provided:
%   varargout{1}: cell array of strings containing preamble text that
%       summarizes the test, where each cell is a line. This text will
%       precede the results table in the report.
%   varargout{2}: n x 3 cell array of strings containing the test ID in
%       the first column, name in the second, and result (Pass/Fail or 
%       numerical values typically) of the test in the third.
%   varargout{3}: cell array of strings containing footnotes referenced by
%       the tests, where each cell is a line.  This text will follow the
%       results table in the report.
%   varargout{4} (optional): structure containing reference data created by 
%       executing this version.  This structure can be passed back into 
%       subsequent executions of UnitTest as varargin{3} to compare results
%       between versions (or to a priori validated reference data).
%
% The following variables are returned when no input arguments are
% provided (required only if called by UnitTestHarness):
%   varargout{1}: string containing the application name (with .m 
%       extension)
%   varargout{2}: string containing the path to the version application 
%       whose results will be used as reference
%   varargout{3}: 1 x n cell array of strings containing paths to the other 
%       applications which will be tested
%   varargout{4}: 2 x m cell array of strings containing the name of each 
%       test suite (first column) and path to the test data (second column)
%   varargout{5}: string containing the path and name of report file (will 
%       be appended by _R201XX.md based on the MATLAB version)
%
% Below is an example of how this function is used:
%
%   % Declare path to application and test suite
%   app = '/path/to/application';
%   test = '/path/to/test/data/';
%
%   % Load reference data from .mat file
%   load('referencedata.mat', '-mat', reference);
%
%   % Execute unit test, printing the test results to stdout
%   UnitTest(app, test, reference);
%
%   % Execute unit test, storing the test results
%   [preamble, table, footnotes] = UnitTest(app, test, reference);
%
%   % Execute unit test again but without reference data, this time storing 
%   % the output from UnitTest as a new reference file
%   [preamble, table, footnotes, newreference] = UnitTest(app, test);
%
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2015 University of Wisconsin Board of Regents
%
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the  
% Free Software Foundation, either version 3 of the License, or (at your 
% option) any later version.
%
% This program is distributed in the hope that it will be useful, but 
% WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General 
% Public License for more details.
% 
% You should have received a copy of the GNU General Public License along 
% with this program. If not, see http://www.gnu.org/licenses/.

%% Return Application Information
% If UnitTest was executed without input arguments
if nargin == 0
    
    % Declare the application filename
    varargout{1} = 'HandCalcUI.m';

    % Declare current version directory
    varargout{2} = './';

    % Declare prior version directories
    varargout{3} = {
        
    };

    % Declare location of test data. Column 1 is the name of the 
    % test suite, column 2 is the absolute path to the file(s)
    varargout{4} = {
        'STATVR'     '../test_data/statvr/ViewRayReport_STATVR1.pdf'
    };

    % Declare name of report file (will be appended by _R201XX.md based on 
    % the MATLAB version)
    varargout{5} = '../test_reports/unit_test';
    
    % Return to invoking function
    return;
end

%% Initialize Unit Testing
% Initialize static test result text variables
pass = 'Pass';
fail = 'Fail';
unk = 'N/A'; %#ok<NASGU>

% Initialize preamble text
preamble = {
    '| Input Data | Value |'
    '|------------|-------|'
};

% Initialize results cell array
results = cell(0,3);

% Initialize footnotes cell array
footnotes = cell(0,1);

% Initialize reference structure
if nargin == 3
    reference = varargin{3};
else
    reference = struct;
end

%% TEST 1/2: Application Loads Successfully, Time
%
% DESCRIPTION: This unit test attempts to execute the main application
%   executable and times how long it takes.  This test also verifies that
%   errors are present if the required submodules do not exist and that the
%   print report button is initially disabled.
%
% RELEVANT REQUIREMENTS: U001, F001
%
% INPUT DATA: No input data required
%
% CONDITION A (+): With the appropriate submodules present, opening the
%   application andloads without error in the required time
%
% CONDITION B (-): With the xpdf_tools submodule missing, opening the 
%   application throws an error

% Change to directory of version being tested
cd(varargin{1});

% Start with fail
pf = fail;

% Attempt to open application without submodule
try
    HandCalcUI('unitXpdfTools');

% If it fails to open, the test passed
catch
    pf = pass;
end

% Close all figures
close all force;

% Open application again with submodule, this time storing figure handle
try
    t = tic;
    h = HandCalcUI;
    time = sprintf('%0.1f sec', toc(t));

% If it fails to open, the test failed  
catch
    pf = fail;
end

% Retrieve guidata
data = guidata(h);

% Set unit test flag to 1 (to avoid uigetfile/questdlg/user input)
data.unitflag = 1; 

% Compute numeric version (equal to major * 10000 + minor * 100 + bug)
c = regexp(data.version, '^([0-9]+)\.([0-9]+)\.*([0-9]*)', 'tokens');
version = str2double(c{1}{1})*10000 + str2double(c{1}{2})*100 + ...
    max(str2double(c{1}{3}),0);

% Add version to results
results{size(results,1)+1,1} = 'ID';
results{size(results,1),2} = 'Test Case';
results{size(results,1),3} = sprintf('Version&nbsp;%s', data.version);

% Update guidata
guidata(h, data);

% Add application load result
results{size(results,1)+1,1} = '1';
results{size(results,1),2} = 'Application Loads Successfully';
results{size(results,1),3} = pf;

% Add application load time
results{size(results,1)+1,1} = '2';
results{size(results,1),2} = 'Application Load Time';
results{size(results,1),3} = time;

%% TEST 3/4: Code Analyzer Messages, Cumulative Cyclomatic Complexity
%
% DESCRIPTION: This unit test uses the checkcode() MATLAB function to check
%   each function used by the application and return any Code Analyzer
%   messages that result.  The cumulative cyclomatic complexity is also
%   computed for each function and summed to determine the total
%   application complexity.  Although this test does not reference any
%   particular requirements, it is used during development to help identify
%   high risk code.
%
% RELEVANT REQUIREMENTS: none 
%
% INPUT DATA: No input data required
%
% CONDITION A (+): Report any code analyzer messages for all functions
%   called by HandCalcUI
%
% CONDITION B (+): Report the cumulative cyclomatic complexity for all
%   functions called by HandCalcUI

% Search for required functions
fList = matlab.codetools.requiredFilesAndProducts('HandCalcUI.m');

% Initialize complexity and messages counters
comp = 0;
mess = 0;

% Loop through each dependency
for i = 1:length(fList)
    
    % Execute checkcode
    inform = checkcode(fList{i}, '-cyc');
    
    % Loop through results
    for j = 1:length(inform)
       
        % Check for McCabe complexity output
        c = regexp(inform(j).message, ...
            '^The McCabe complexity .+ is ([0-9]+)\.$', 'tokens');
        
        % If regular expression was found
        if ~isempty(c)
            
            % Add complexity
            comp = comp + str2double(c{1});
            
        else
            
            % If not an invalid code message
            if ~strncmp(inform(j).message, 'Filename', 8)
                
                % Log message
                Event(sprintf('%s in %s', inform(j).message, fList{i}), ...
                    'CHCK');

                % Add as code analyzer message
                mess = mess + 1;
            end
        end
        
    end
end

% Add code analyzer messages counter to results
results{size(results,1)+1,1} = '3';
results{size(results,1),2} = 'Code Analyzer Messages';
results{size(results,1),3} = sprintf('%i', mess);

% Add complexity results
results{size(results,1)+1,1} = '4';
results{size(results,1),2} = 'Cumulative Cyclomatic Complexity';
results{size(results,1),3} = sprintf('%i', comp);

%% TEST 5: Source Report PDF Loads Successfully
%
% DESCRIPTION: This unit test verifies that the source calibration report
% parser subfunction runs without error.
%
% RELEVANT REQUIREMENTS: F008
%
% INPUT DATA: ViewRay Source Calibration Report PDF
%
% CONDITION A (+): Execute ParseSourceTrackingPDF with a valid source
% calibration report and verify that it executes without error
%
% CONDITION B (-): Execute the same function with invalid inputs and verify
%   that the function fails.

% Retrieve guidata
data = guidata(h);
    
% Execute ParseSourceTrackingPDF in try/catch statement
try
    
    pf = pass;
    ParseSourceTrackingPDF('../test_data/sourcereport/', ...
        'SourceTracking_2016_2_24.pdf');

% If it errors, record fail
catch
    pf = fail;
end

% Execute ParseSourceTrackingPDF with no inputs in try/catch statement
try
    ParseSourceTrackingPDF();
    pf = fail;
catch
    % If it fails, test passed
end
    
% Add success message
results{size(results,1)+1,1} = '5';
results{size(results,1),2} = 'Source Calibration Report Loads Successfully';
results{size(results,1),3} = pf;


%% Finish up
% Close all figures
close all force;

% If no return variables are present, print the results
if nargout == 0
    
    % Print preamble
    for j = 1:length(preamble)
        fprintf('%s\n', preamble{j});
    end
    fprintf('\n');
    
    % Loop through each table row
    for j = 1:size(results,1)
        
        % Print table row
        fprintf('| %s |\n', strjoin(results(j,:), ' | '));
       
        % If this is the first column
        if j == 1
            
            % Also print a separator row
            fprintf('|%s\n', repmat('----|', 1, size(results,2)));
        end

    end
    fprintf('\n');
    
    % Print footnotes
    for j = 1:length(footnotes) 
        fprintf('%s<br>\n', footnotes{j});
    end
    
% Otherwise, return the results as variables    
else

    % Store return variables
    if nargout >= 1; varargout{1} = preamble; end
    if nargout >= 2; varargout{2} = results; end
    if nargout >= 3; varargout{3} = footnotes; end
    if nargout >= 4; varargout{4} = reference; end
end