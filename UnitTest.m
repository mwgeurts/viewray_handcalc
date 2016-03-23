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
        './'
    };

    % Declare location of test data. Column 1 is the name of the 
    % test suite, column 2 is the absolute path to the file(s)
    varargout{4} = {
        'v4.0 Text'     {'../test_data/source/SourceTracking_2016_2_24.pdf' 
                      '../test_data/statvr/PlanOverview_STATVR3.txt'}
        'v4.0 PDF'     {'../test_data/source/SourceTracking_2016_2_24.pdf' 
                      '../test_data/statvr/ViewRayReport_STATVR1.pdf'}
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
% RELEVANT REQUIREMENTS: U001, F001, P001
%
% INPUT DATA: No input data required
%
% CONDITION A (+): With the appropriate submodules present, opening the
%   application andloads without error in the required time
%
% CONDITION B (-): With the xpdf_tools submodule missing, opening the 
%   application throws an error
%
% CONDITION C (+): Report application load time

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
% c = regexp(data.version, '^([0-9]+)\.([0-9]+)\.*([0-9]*)', 'tokens');
% version = str2double(c{1}{1})*10000 + str2double(c{1}{2})*100 + ...
%     max(str2double(c{1}{3}),0);

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
    data.calibration = ParseSourceTrackingPDF(varargin{2}{1});

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
    
% Store guidata
guidata(h, data);

% Add success message
results{size(results,1)+1,1} = '5';
results{size(results,1),2} = 'Source Calibration Report Loads Successfully';
results{size(results,1),3} = pf;

%% TEST 6: Source Calibration Information Identical
%
% DESCRIPTION: This unit test verifies that the ParseSourceTrackingPDF
% function extracts consistent information from the source PDF, including 
% system name, serial number, and source ID, activity, and strength for 
% each source.
%
% RELEVANT REQUIREMENTS: F008
%
% INPUT DATA: Validated source calibration report (varargin{2}{1})
%
% CONDITION A (+): The extracted reference data matches expected data
%
% CONDITION B (-): The extracted reference data is not empty

% If reference data exists
if nargin == 3

    % If current value equals the reference and is not empty
    if ~isempty(data.calibration.sourceid) && ...
            isequal(data.calibration.sourceid, reference.calibration.sourceid) && ...
            isequal(data.calibration.activity, reference.calibration.activity) && ...
            isequal(data.calibration.activitydate, reference.calibration.activitydate) && ...
            isequal(data.calibration.strength, reference.calibration.strength) && ...
            isequal(data.calibration.strengthdate, reference.calibration.strengthdate) && ...
            isequal(data.calibration.system, reference.calibration.system) && ...
            isequal(data.calibration.serial, reference.calibration.serial)
        pf = pass;

    % Otherwise, it failed
    else
        pf = fail;
    end

% Otherwise, no reference data exists
else

    % Set current value as reference
    reference.calibration = data.calibration;

    % Assume pass
    pf = pass;
    
    % Extract filename
    [~, name, ext] = fileparts(varargin{2}{1});
    
    % Add source calibration report to preamble
    preamble{length(preamble)+1} = ['| Source&nbsp;Calibration&nbsp;Report', ...
        ' | ', name, ext, ' |'];
end

% Add result
results{size(results,1)+1,1} = '6';
results{size(results,1),2} = 'Source Calibration Report Identical';
results{size(results,1),3} = pf;

%% TEST 7/8: Browse Loads Report Successfully/Load Time
%
% DESCRIPTION: This unit test verifies a callback exists for the browse
%   button and executes it under unit test conditions (such that a file 
%   selection dialog box is skipped), simulating the process of a user
%   selecting input data.  The time necessary to load the file is also
%   checked.
%
% RELEVANT REQUIREMENTS: U006, F002, F003, F004, F005, P002, P003 
%
% INPUT DATA: Validated text and PDF plan report (varargin{2}{2})
%
% CONDITION A (+): The callback for the report browse button can be 
%   executed without error when a valid filename is provided
%
% CONDITION B (-): The callback will throw an error if an invalid filename
%   is provided
%
% CONDITION C (+): The callback will return without error when no filename
%   is provided
%
% CONDITION D (+): Upon receiving a valid filename, the filename will be
%   displayed on the user interface
%
% CONDITION E (+): Report the time taken to execute the browse callback and 
%   parse the data

% Retrieve guidata
data = guidata(h);
    
% Retrieve callback to browse button
callback = get(data.browse_button, 'Callback');

% Set empty unit path/name
data.unitpath = '';
data.unitname = '';

% Store guidata
guidata(h, data);

% Execute callback in try/catch statement
try
    pf = pass;
    callback(data.browse_button, data);

% If it errors, record fail
catch
    pf = fail;
end

% Set invalid unit path/name
data.unitpath = '/';
data.unitname = 'asd';

% Store guidata
guidata(h, data);

% Execute callback in try/catch statement (this should fail)
try
    callback(data.browse_button, data);
    pf = fail;
    
% If it errors
catch
	% The test passed
end

% Set unit path/name
[path, name, ext] = fileparts(varargin{2}{2});
data.unitpath = path;
data.unitname = [name, ext];

% Store guidata
guidata(h, data);

% Execute callback in try/catch statement
try
    t = tic;
    callback(data.browse_button, data);

% If it errors, record fail
catch
    pf = fail;
end

% Record completion time
time = sprintf('%0.1f sec', toc(t));

% Retrieve guidata
data = guidata(h);

% Verify that the file name matches the input data
if strcmp(pf, pass) && strcmp(data.report.String, fullfile(varargin{2}{2}))
    pf = pass;
else
    pf = fail;
end

% Add result
results{size(results,1)+1,1} = '7';
results{size(results,1),2} = 'Browse Loads Report Successfully';
results{size(results,1),3} = pf;

% Add result
results{size(results,1)+1,1} = '8';
results{size(results,1),2} = 'Browse Callback Load Time';
results{size(results,1),3} = time;

%% TEST 9: Parsed Report Data Identical
%
% DESCRIPTION: This unit test compares the parsed text and PDF report data
% and compares it to reference data. The patient, machine, point, and beams
% structures are compared
%
% RELEVANT REQUIREMENTS: F006, F007
%
% INPUT DATA: Validated text and PDF plan report (varargin{2}{2})
%
% CONDITION A (+): Extracted structures are identical
%
% CONDITION B (-): Extracted structures are not empty

% Retrieve guidata
data = guidata(h);

% If reference data exists and this is a text file
if nargin == 3 && ~isempty(regexpi(name, '.txt$'))

    % If current value equals the reference and is not empty
    if ~isempty(data.patient.id) && ~isempty(data.machine) && ...
            ~isempty(data.points) && ~isempty(data.beams) && ...
            isequal(data.patient.id, reference.patient.id) && ...
            isequal(data.patient.name, reference.patient.name) && ...
            isequal(data.patient.birthdate, reference.patient.birthdate) && ...
            isequal(data.patient.diagnosis, reference.patient.diagnosis) && ...
            isequal(data.patient.prescription, reference.patient.prescription) && ...
            isequal(data.patient.plan, reference.patient.plan) && ...
            isequal(data.patient.planapproval, reference.patient.planapproval) && ...
            isequal(data.patient.planid, reference.patient.planid) && ...
            isequal(data.patient.lastmodified, reference.patient.lastmodified) && ...
            isequal(data.patient.rxvolume, reference.patient.rxvolume) && ...
            isequal(data.patient.rxdose, reference.patient.rxdose) && ...
            isequal(data.patient.rxpercent, reference.patient.rxpercent) && ...
            isequal(data.patient.fractions, reference.patient.fractions) && ...
            isequal(data.patient.position, reference.patient.position) && ...
            isequal(data.patient.couch, reference.patient.couch) && ...
            isequal(data.patient.densityct, reference.patient.densityct) && ...
            isequal(data.patient.densityoverrides, reference.patient.densityoverrides) && ...
            isequal(data.machine.name, reference.machine.name) && ...
            isequal(data.machine.serial, reference.machine.serial) && ...
            isequal(data.machine.version, reference.machine.version) && ...
            isequal(data.machine.model, reference.machine.model) && ...
            isequal(data.machine.institution, reference.machine.institution) && ...
            isequal(data.machine.department, reference.machine.department) && ...
            isequal(data.machine.timespec, reference.machine.timespec) && ...
            isequal(data.points{1}.name, reference.points{1}.name) && ...
            isequal(data.points{1}.coordinates, reference.points{1}.coordinates) && ...
            isequal(data.beams{1}.angle, reference.beams{1}.angle) && ...
            isequal(data.beams{1}.group, reference.beams{1}.group) && ...
            isequal(data.beams{1}.iso, reference.beams{1}.iso) && ...
            isequal(data.beams{1}.ssd, reference.beams{1}.ssd) && ...
            isequal(data.beams{1}.depth, reference.beams{1}.depth) && ...
            isequal(data.beams{1}.edepth, reference.beams{1}.edepth) && ...
            isequal(data.beams{1}.oad, reference.beams{1}.oad) && ...
            isequal(data.beams{1}.plantime, reference.beams{1}.plantime) && ...
            isequal(data.beams{1}.type, reference.beams{1}.type) && ...
            isequal(data.beams{1}.equivsquare, reference.beams{1}.equivsquare) && ...
            isequal(data.beams{1}.weightpt, reference.beams{1}.weightpt) && ...
            isequal(data.beams{1}.weight, reference.beams{1}.weight)
        pf = pass;

    % Otherwise, it failed
    else
        pf = fail;
    end

% If reference data exists and this is a PDF file
elseif nargin == 3 && ~isempty(regexpi(name, '.pdf$'))

    % If current value equals the reference and is not empty
    if ~isempty(data.patient.id) && ~isempty(data.machine) && ...
            ~isempty(data.points) && ~isempty(data.beams) && ...
            isequal(data.patient.name, reference.patient.name) && ...
            isequal(data.patient.plan, reference.patient.plan) && ...
            isequal(data.patient.lastmodified, reference.patient.lastmodified) && ...
            isequal(data.patient.id, reference.patient.id) && ...
            isequal(data.patient.mrn, reference.patient.mrn) && ...
            isequal(data.patient.birthdate, reference.patient.birthdate) && ...
            isequal(data.patient.rxapproval, reference.patient.rxapproval) && ...
            isequal(data.patient.rxapprovaldate, reference.patient.rxapprovaldate) && ...
            isequal(data.patient.contourapproval, reference.patient.contourapproval) && ...
            isequal(data.patient.contourapprovaldate, reference.patient.contourapprovaldate) && ...
            isequal(data.patient.imageapproval, reference.patient.imageapproval) && ...
            isequal(data.patient.imageapprovaldate, reference.patient.imageapprovaldate) && ...
            isequal(data.patient.planapproval, reference.patient.planapproval) && ...
            isequal(data.patient.planapprovaldate, reference.patient.planapprovaldate) && ...
            isequal(data.patient.calendarapproval, reference.patient.calendarapproval) && ...
            isequal(data.patient.calendarapprovaldate, reference.patient.calendarapprovaldate) && ...
            isequal(data.patient.coil, reference.patient.coil) && ...
            isequal(data.patient.autonormalize, reference.patient.autonormalize) && ...
            isequal(data.patient.interdigitation, reference.patient.interdigitation) && ...
            isequal(data.patient.resolution, reference.patient.resolution) && ...
            isequal(data.patient.deform, reference.patient.deform) && ...
            isequal(data.patient.deliverytime, reference.patient.deliverytime) && ...
            isequal(data.patient.position, reference.patient.position) && ...
            isequal(data.patient.diagnosis, reference.patient.diagnosis) && ...
            isequal(data.patient.rxvolume, reference.patient.rxvolume) && ...
            isequal(data.patient.rxdose, reference.patient.rxdose) && ...
            isequal(data.patient.rxpercent, reference.patient.rxpercent) && ...
            isequal(data.patient.fractions, reference.patient.fractions) && ...
            isequal(data.patient.doseperfx, reference.patient.doseperfx) && ...
            isequal(data.patient.prevdose, reference.patient.prevdose) && ...
            isequal(data.patient.couch, reference.patient.couch) && ...
            isequal(data.patient.densityct, reference.patient.densityct) && ...
            isequal(data.patient.densityoverrides, reference.patient.densityoverrides) && ...
            isequal(data.machine.institution, reference.machine.institution) && ...
            isequal(data.machine.version, reference.machine.version) && ...
            isequal(data.machine.isotope, reference.machine.isotope) && ...
            isequal(data.machine.model, reference.machine.model) && ...
            isequal(data.machine.calibration, reference.machine.calibration) && ...
            isequal(data.machine.planning, reference.machine.planning) && ...
            isequal(data.points{1}.name, reference.points{1}.name) && ...
            isequal(data.points{1}.coordinates, reference.points{1}.coordinates) && ...
            isequal(data.points{1}.dose, reference.points{1}.dose) && ...
            isequal(data.points{1}.beams, reference.points{1}.beams) && ...
            isequal(data.points{1}.couch, reference.points{1}.couch) && ...
            isequal(data.beams{1}.angle, reference.beams{1}.angle) && ...
            isequal(data.beams{1}.group, reference.beams{1}.group) && ...
            isequal(data.beams{1}.iso, reference.beams{1}.iso) && ...
            isequal(data.beams{1}.ssd, reference.beams{1}.ssd) && ...
            isequal(data.beams{1}.depth, reference.beams{1}.depth) && ...
            isequal(data.beams{1}.edepth, reference.beams{1}.edepth) && ...
            isequal(data.beams{1}.oad, reference.beams{1}.oad) && ...
            isequal(data.beams{1}.plantime, reference.beams{1}.plantime) && ...
            isequal(data.beams{1}.type, reference.beams{1}.type) && ...
            isequal(data.beams{1}.equivsquare, reference.beams{1}.equivsquare) && ...
            isequal(data.beams{1}.weightpt, reference.beams{1}.weightpt) && ...
            isequal(data.beams{1}.weight, reference.beams{1}.weight)
        pf = pass;

    % Otherwise, it failed
    else
        pf = fail;
    end
    
% Otherwise, no reference data exists
else

    % Set current value as reference
    reference.patient = data.patient;
    reference.machine = data.machine;
    reference.points = data.points;
    reference.beams = data.beams;

    % Assume pass
    pf = pass;
    
    % Extract filename
    [~, name, ext] = fileparts(varargin{2}{2});
    
    % Add plan report to preamble
    preamble{length(preamble)+1} = ['| Plan&nbsp;Report', ...
        ' | ', name, ext, ' |'];
    
    % Add number of beams
    preamble{length(preamble)+1} = ['| Number&nbsp;of&nbsp;Beams', ...
        ' | ', length(data.beams), ' |'];
    
    % Add beam type
    preamble{length(preamble)+1} = ['| Beam&nbsp;Type', ...
        ' | ', data.beams{1}.type, ' |'];
end

% Add result
results{size(results,1)+1,1} = '9';
results{size(results,1),2} = 'Plan Report Identical';
results{size(results,1),3} = pf;

%% TEST 10/11: CalculateBeamTime results, time
%
% DESCRIPTION: This unit test validates the different function input
%   combinations available when executing CalculateBeamTime().
%
% RELEVANT REQUIREMENTS: F009, F010, F011
%
% INPUT DATA: A beams structure from ParsePlanReportPDF or
%   ParsePlanReportText
%
% CONDITION A (+): CalculateBeamTime() will execute successfully and return
%   a consistent answer when provided dose, depth, and field size inputs
%
% CONDITION B (-): CalculateBeamTime() will fail if provided too few inputs
%
% CONDITION C (+): CalculateBeamTime() will execute successfully and return
%   a consistent answer when provided OAD, beam angle, calibration factor, 
%   couch attenuation magnitude, SAD, SCD, TPR, and Scp factors
%
% CONDITION D (+): CalculateBeamTime() will execute successfully and return
%   a consistent answer when provided a beams structure
%
% CONDITION E (+): Report the average time taken to execute the function
%   CalculateBeamTime() for the above conditions

% Start timer
t = tic;

% Execute CalculateBeamTime() in try/catch statement
try
    pf = pass;
    calc1 = CalculateBeamTime('dose', 1.5, 'depth', 10, 'r', 10);

% If it errors, record fail
catch
    pf = fail;
end

% If reference data exists
if nargin == 3 
    
    % If the beam on time matches the reference
    if ~isequal(calc1.time, reference.calc1.time)
        pf = fail;
    end
else
    reference.calc1 = calc1;
end

% Execute CalculateBeamTime() in try/catch statement (this should fail)
try
    CalculateBeamTime();
    pf = fail;
    
% If it errors
catch
	% The test passed
end

% Execute CalculateBeamTime() in try/catch statement with extra inputs
try
    calc2 = CalculateBeamTime('dose', 1.8, 'depth', 10, 'r', [8 14], 'oad', ...
        12, 'angle', 180, 'k', 2, 'cf', 0.75, 'sad', 100, 'scd', 90);

% If it errors, record fail
catch
    pf = fail;
end

% If reference data exists
if nargin == 3 
    
    % If the beam on time matches the reference
    if ~isequal(calc2.time, reference.calc2.time)
        pf = fail;
    end
else
    reference.calc2 = calc2;
end

% Execute CalculateBeamTime() in try/catch statement with beam input
try

    calc3 = CalculateBeamTime('dose', 2, 'beam', struct('edepth', 20, ...
        'equivsquare', 20, 'oad', 8, 'angle', 150, 'ssd', 100, 'depth', 15));

% If it errors, record fail
catch
    pf = fail;
end

% If reference data exists
if nargin == 3 
    
    % If the beam on time matches the reference
    if ~isequal(calc3.time, reference.calc3.time)
        pf = fail;
    end
else
    reference.calc3 = calc3;
end

% Record completion time
time = sprintf('%0.1f sec', toc(t)/3);

% Add result
results{size(results,1)+1,1} = '10';
results{size(results,1),2} = 'CalculateBeamTime() computes correctly';
results{size(results,1),3} = pf;

% Add result
results{size(results,1)+1,1} = '11';
results{size(results,1),2} = 'CalculateBeamTime() Average Execution Time';
results{size(results,1),3} = time;


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