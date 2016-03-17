function UnitTestHarness(varargin)
% UnitTestHarness is a function that automatically runs a series of unit 
% tests on the most current and previous versions of this application.  The 
% unit test results are then written to a GitHub Flavored Markdown text 
% file.
% 
% UnitTestHarness was designed to be application-independent, and receives
% the information it needs by executing UnitTest.  Refer to this function
% within the application for information on how the unit tests are
% executed.  This function will automatically update the path to the 
% location of UnitTest.
%
% No input or return arguments are necessary to execute UnitTestHarness. 
% The optional string 'noprofile' may be passed, which will cause the
% profiler HTML save feature to be temporarily disabled.
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

%% Initialize Application Variables
% Add parent directory to path
addpath('..');

% Search for UnitTest
if exist('UnitTest', 'file') ~= 2
    if exist('Event', 'file') == 2
        Event('The dependent function UnitTest could not be found', ...
            'ERROR');
    else
        error('The dependent function UnitTest could not be found');
    end
end

% Log start
if exist('Event', 'file') == 2
    Event('Beginning unit test harness', 'UNIT');
    time = tic;
end

% Retrieve path to UnitTest
[cwd, ~, ~] = fileparts(which('UnitTest'));

% Set current directory to location of UnitTest
cd(cwd);

% Store current working directory
if exist('Event', 'file') == 2
    Event(['UnitTest working directory is ', cwd], 'UNIT');
end

% Execute UnitTest without arguments to get the application name, location
% of reference application, prior applications, test data, and report
[appName, referenceApp, priorApps, testData, report] = UnitTest();

%% Initialize Report
% Retrieve MATLAB version
v = regexp(version, '\((.+)\)', 'tokens');

% Open a write file handle to the report
if exist('Event', 'file') == 2
    Event(['Initializing report file ', ...
        char(fullfile(cwd, strcat(report, '_', v{1}, '.md')))], 'UNIT');
end
fid = fopen(char(fullfile(cwd, strcat(report, '_', v{1}, '.md'))), 'wt');

% If the report file could not be created
if fid < 3
    if exist('Event', 'file') == 2
        Event([char(fullfile(cwd, strcat(report, '_', v{1}, '.md'))), ...
            ' could not be created'], 'ERROR');
    else
        error([char(fullfile(cwd, strcat(report, '_', v{1}, '.md'))), ...
            ' could not be created']);
    end
end

%% Write table of contents
if exist('Event', 'file') == 2
    Event('Writing table of contents', 'UNIT');
end
fprintf(fid, '## Contents\n\n');

% Print link to system configuration
fprintf(fid, '* [System Configuration](#system-configuration)\n');

% Loop through each test suite
for i = 1:size(testData, 1)
    
    % Print link to test suite
    fprintf(fid, '* [%s Test Suite Results](#%s-test-suite-results)\n', ...
        testData{i,1}, strrep(lower(testData{i,1}), ' ', '-'));
end

% Print link to code coverage
fprintf(fid, '* [Code Coverage](#code-coverage)\n\n');

%% Write test system confiruation
if exist('Event', 'file') == 2
    Event('Writing test system configuration', 'UNIT');
end
fprintf(fid, '## Test System Configuration\n\n');
fprintf(fid, ['Computation times are documented based on the ', ...
    'following system configuration and reflect elapsed real time (as ', ...
    'opposed to CPU time). Note, other hardware configurations may also ', ...
    'be run during compatibility testing.\n\n']);

% Start table containing test configuration
fprintf(fid, '| Specification | Configuration |\n');
fprintf(fid, '|----|----|\n');

% Retrieve CPU info
if exist('Event', 'file') == 2
    Event('Retrieving test system CPU status', 'UNIT');
end
info = cpuinfo();

% Write processor information
fprintf(fid, '| Operating System | %s %s |\n', info.OSType, info.OSVersion);
fprintf(fid, '| Processor | %s |\n', info.Name);
fprintf(fid, '| Frequency | %s |\n', info.Clock);
fprintf(fid, '| Number of Cores | %i |\n', info.NumProcessors);
fprintf(fid, '| L2 Cache (per core) | %s |\n', info.Cache);

% Retrieve memory info
if exist('Event', 'file') == 2
    Event('Retrieving test system memory status', 'UNIT');
end
info = meminfo();

% Write memory information
fprintf(fid, '| Memory | %0.2f GB (%0.2f GB available) |\n', ...
    info.Total/1024^3, info.Unused/1024^3);

% Test for GPU
if exist('Event', 'file') == 2
    Event('Retrieving compatible GPU status', 'UNIT');
end
try 
    
    % Store GPU information to temporary variable
    g = gpuDevice(1);
    
    % Print GPU information
    fprintf(fid, '| Graphics Card | %s |\n', g.Name);
    fprintf(fid, '| Graphics Memory | %0.0f MB (%0.0f MB available) |\n', ...
        g.TotalMemory / 1024^2, g.FreeMemory / 1024^2);
    fprintf(fid, '| CUDA Version | %s |\n', g.ComputeCapability);
    
    % Clear temporary variable
    clear g;

% Otherwise, a compatible GPU device does not exist
catch 
    fprintf(fid, '| Graphics Card | No compatible GPU device found |\n');
    fprintf(fid, '| Graphics Total Memory | |\n');
    fprintf(fid, '| Graphics Memory Available | |\n');
    fprintf(fid, '| CUDA Version | |\n');
end

% Write MATLAB version
fprintf(fid, '| MATLAB Version | %s |\n', v{1}{1});
fprintf(fid, '\n');

% Clear temporary variables
clear info;

% Write remainder of introduction
if exist('Event', 'file') == 2
    Event('Writing unit test summary', 'UNIT');
end

%% Execute unit tests
% Start profiler
profile off;
profile on -history;

% Retrieve profiler status
S = profile('status');

% Log status information
if exist('Event', 'file') == 2
    Event(sprintf(['Starting MATLAB profiler\nStatus: %s\n', ...
        'Detail level: %s\nTimer: %s\nHistory tracking: ', ...
        '%s\nHistory size: %i'], S.ProfilerStatus, S.DetailLevel, S.Timer, ...
        S.HistoryTracking, S.HistorySize), 'UNIT');
end

% Clear temporary variables
clear S;

% Loop through each test case
for i = 1:size(testData, 1)
    
    % Restore default search path
    if exist('Event', 'file') == 2
        Event('Restoring MATLAB default path', 'UNIT');
    end
    restoredefaultpath;

    % Restore current directory
    if exist('Event', 'file') == 2
        Event('Reverting to unit test working directory', 'UNIT');
    end
    cd(cwd);
    
    % Execute unit test of current/reference version
    if exist('Event', 'file') == 2
        Event(sprintf(['Executing UnitTest(%s) with test dataset %i and ', ...
            'collecting reference'], fullfile(cwd, referenceApp), i), 'UNIT');
    end
    [preamble, t, footnotes, reference] = ...
        UnitTest(fullfile(cwd, referenceApp), fullfile(cwd, testData{i,2}));

    % Pre-allocate results cell array
    results = cell(size(t,1), length(priorApps)+3);

    % Store reference tempresults in first and last columns
    results(:,1) = t(:,1);
    results(:,2) = t(:,2);
    results(:,length(priorApps)+3) = t(:,3);

    % Loop through each prior version
    for j = 1:length(priorApps)

        % Restore default search path
        if exist('Event', 'file') == 2
            Event('Restoring MATLAB default path', 'UNIT');
        end
        restoredefaultpath;
        
        % Restore current directory
        if exist('Event', 'file') == 2
            Event('Reverting to unit test working directory', 'UNIT');
        end
        cd(cwd);
        
        % Execute unit test on prior version
        if exist('Event', 'file') == 2
            Event(sprintf('Executing UnitTest(%s) with test dataset %i', ...
                fullfile(cwd, priorApps{j}), i), 'UNIT');
        end
        [~, t, ~] = UnitTest(fullfile(cwd, priorApps{j}), ...
            fullfile(cwd, testData{i,2}), reference);

        % Store prior version results
        results(:,j+2) = t(:,3);
        
        % Clear temporary variables
        clear t;
    end

    % Print unit test header
    if exist('Event', 'file') == 2
        Event(sprintf('Writing test suite results for dataset %i', i), ...
            'UNIT');
    end
    fprintf(fid, '## %s Test Suite Results\n\n', testData{i,1});
    
    % Print preamble
    if exist('Event', 'file') == 2
        Event('Writing test suite preamble', 'UNIT');
    end
    for j = 1:length(preamble)
        fprintf(fid, '%s\n', preamble{j});
    end
    fprintf(fid, '\n');
    
    % Loop through each table row
    if exist('Event', 'file') == 2
        Event('Writing test suite results table', 'UNIT');
    end
    for j = 1:size(results,1)
        
        % Print table row
        fprintf(fid, '| %s |\n', strjoin(results(j,:), ' | '));
       
        % If this is the first column
        if j == 1
            
            % Also print a separator row
            fprintf(fid, '|%s\n', repmat('----|', 1, size(results,2)));
        end

    end
    fprintf(fid, '\n');
    
    % Print footnotes
    if exist('Event', 'file') == 2
        Event('Writing test suite footnotes', 'UNIT');
    end
    for j = 1:length(footnotes) 
        fprintf(fid, '%s<br>\n', footnotes{j});
    end
    fprintf(fid, '\n');
end

% Stop profiler
stats = profile('info');
if exist('Event', 'file') == 2
    Event(sprintf(['Stopping and retrieving MATLAB profiler status\n', ...
        'Functions profiled: %i'], size(stats.FunctionTable, 1)), 'UNIT');
end

%% Determine file list
% Initialize file list with currentApp
fList = cell(0);
f = matlab.codetools.requiredFilesAndProducts(...
    fullfile(cwd, referenceApp, appName));

% Log number of functions found in current application
if exist('Event', 'file') == 2
    Event(sprintf('%i required functions identified in %s', length(f), ...
        referenceApp), 'UNIT');
end

% Loop through files, saving file names
for i = 1:length(f)
    
    % Retrieve file name
    [~, name, ~] = fileparts(f{i});

    % Store file name
    fList{length(fList)+1} = name;
end

% Loop through priorApps
for i = 1:length(priorApps)

    % Retrieve priorApp file list
    f = matlab.codetools.requiredFilesAndProducts(...
        fullfile(cwd, priorApps{i}, appName));
    
    % Log the number of functions found in prior applications
    if exist('Event', 'file') == 2
        Event(sprintf('%i required functions identified in %s', length(f), ...
            priorApps{i}), 'UNIT');
    end

    % Loop through files, saving file names
    for j = 1:length(f)
        
        % Retrieve file name
        [~, name, ~] = fileparts(f{j});
       
        % Store file name
        fList{length(fList)+1} = name;
    end
end

% Remove duplicates
fList = unique(fList);
if exist('Event', 'file') == 2
    Event(sprintf('%i unique functions identified', length(fList)), 'UNIT');
end

% Sort array
fList = sort(fList);

%% Compute code coverage
% Initialize code coverage table
if exist('Event', 'file') == 2
    Event('Computing code coverage', 'UNIT');
end
executed = zeros(length(fList), size(results, 2)-2);
total = zeros(length(fList), size(results, 2)-2);

% Loop through FunctionTable
for i = 1:size(stats.FunctionTable, 1)
    
    % Initialize column and row indices
    c = 0;
    
    % Extract the filename
    [~, name, ~] = fileparts(stats.FunctionTable(i).FileName);
        
    % If the filename is UnitTestHarness or UnitTest, skip it
    if strcmp(name, 'UnitTestHarness') || strcmp(name, 'UnitTest')
        continue;
    end
    
    % Generate absolute path of currentApp
    cd(fullfile(cwd, referenceApp));
    path = [pwd, filesep];
    cd(cwd);
    
    % If FileName is within the currentApp
    if strncmp(path, stats.FunctionTable(i).FileName, length(path))
        
        % Set column index
        c = size(executed, 2);
    else
        
        % Loop through priorApps
        for j = 1:length(priorApps)
            
            % Generate absolute path of priorApp
            cd(fullfile(cwd, priorApps{j}));
            path = [pwd, filesep];
            cd(cwd);
            
            % If FileName is within priorApps
            if strncmp(path, stats.FunctionTable(i).FileName, length(path))
                
                % Set column index and end for loop
                c = j;
                break;
            end
        end
    end
    
    % If the column index was set
    if c > 0
        
        % Loop through the file list
        for j = 1:length(fList)
           
            % If the current file already exists in the list (this will 
            % happen for subfunctions) or the file list is empty (the file
            % was not found)
            if strcmp(fList{j}, name) || isempty(fList{j})
                
                % Update files cell array
                fList{j} = name;
                
                % Add the number of executed lines
                executed(j, c) = executed(j, c) + ...
                    size(stats.FunctionTable(i).ExecutedLines, 1);
                
                % If the total number of lines has not been computed yet
                if total(j, c) == 0
                    total(j, c) = sloc(stats.FunctionTable(i).FileName);
                    if exist('Event', 'file') == 2
                        Event(sprintf('%i lines counted in %s', total(j, c), ...
                            stats.FunctionTable(i).FileName), 'UNIT');
                    end
                end
                
                % Break from the loop
                break;
            end
        end
    end
end

% Print code coverage header
if exist('Event', 'file') == 2
    Event('Writing code coverage results', 'UNIT');
end
fprintf(fid, '## Code Coverage\n\n');

% Print table header row
fprintf(fid, '| Function |');
fprintf(fid, ' %s |', results{1, 3:end});
fprintf(fid, '\n');

% Print a separator row
fprintf(fid, '|%s', repmat('----|', 1, size(results,2)-1));

% Loop through each file
for i = 1:length(fList)
    
    % If a file name exists and filename is not userpath
    if ~isempty(fList{i}) && ~strcmp(fList{i}, 'userpath')
       
        % Write the file name
        fprintf(fid, '\n| %s |', fList{i});
        
        % Loop through the results
        for j = 1:size(executed, 2)
            
            % If the total number of lines were computed
            if total(i,j) > 0
                
                % Printf the coverage
                fprintf(fid, ' %0.1f%% |', executed(i,j)/total(i,j) * 100);
            else
                
                % Otherwise, print an empty cell
                fprintf(fid, '   |');
            end
        end
    end
end

% Close file handle
fclose(fid);

%% Save profiler results
if nargin == 0 || ~strcmp(varargin{1}, 'noprofile')
    
    % Retrieve path to report directory
    [path, ~, ~] = fileparts(char(fullfile(cwd, report)));

    % If a folder for this MATLAB version already exists in the report
    % directory
    if isdir(fullfile(path, v{1}{1}))

        % Log event
        if exist('Event', 'file') == 2
            Event(['Clearing results in ', fullfile(path, v{1}{1})], ...
                'UNIT');
        end

        % Delete the directory
        rmdir(fullfile(path, v{1}{1}), 's');
    end

    % Make a new directory for this MATLAB version
    mkdir(fullfile(path, v{1}{1}));

    % Save the profiler results to HTML files in the new directory
    if exist('Event', 'file') == 2
        Event(['Saving profiler results to ', fullfile(path, v{1}{1})], ...
            'UNIT');
    end
    profsave(stats, fullfile(path, v{1}{1}));

else
    % Otherwise log skip
    if exist('Event', 'file') == 2
        Event('Profiler results were not saved', 'UNIT');
    end
end

% Restore current directory
if exist('Event', 'file') == 2
    Event('Reverting to unit test working directory', 'UNIT');
end
cd(cwd);

%% Finish up
% Log completion and time
if exist('Event', 'file') == 2
    Event(sprintf('Unit test harness completed successfully in %0.1f minutes', ...
        toc(time)/60), 'UNIT');
end

% Clear temporary variables
clear c i j v f t fid fList preamble results footnotes reference cwd ...
    executed total name currentApp priorApps report stats testData time;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = meminfo()
%MEMINFO  return system physical memory information
%
%   info = MEMINFO() returns a structure containing various bits of
%   information about the system memory. This information includes:
%     * TOTAL Memory in bytes
%     * USED Memory in bytes
%     * UNUSED Memory in bytes
%
%   See also: COMPUTER, ISUNIX, ISMAC

info = struct();

if isunix
    if ismac
        [~, text] = unix('top -l 1');
        fields = textscan(text, '%s', 'Delimiter', '\n' ); 
        fields = fields{1};
        fields( cellfun( 'isempty', fields ) ) = [];
        for i = 1:length(fields)
            tokens = regexp(fields{i}, ['^PhysMem[^0-9]+([0-9]+)([MGk]) used', ...
                '[^0-9]+([0-9]+)([MGk]) wired[^0-9]+([0-9]+)([MGk]) unused'], ...
                'tokens');
            if ~isempty(tokens)
                if strcmp(tokens{1}{2}, 'G') 
                    tokens{1}{1} = str2double(tokens{1}{1})*1024^3;
                elseif strcmp(tokens{1}{2}, 'M') 
                    tokens{1}{1} = str2double(tokens{1}{1})*1024^2;
                elseif strcmp(tokens{1}{2}, 'k') 
                    tokens{1}{1} = str2double(tokens{1}{1})*1024;
                end
                if strcmp(tokens{1}{4}, 'G') 
                    tokens{1}{3} = str2double(tokens{1}{3})*1024^3;
                elseif strcmp(tokens{1}{4}, 'M') 
                    tokens{1}{3} = str2double(tokens{1}{3})*1024^2;
                elseif strcmp(tokens{1}{4}, 'k') 
                    tokens{1}{3} = str2double(tokens{1}{3})*1024;
                end
                if strcmp(tokens{1}{6}, 'G') 
                    tokens{1}{5} = str2double(tokens{1}{5})*1024^3;
                elseif strcmp(tokens{1}{6}, 'M') 
                    tokens{1}{5} = str2double(tokens{1}{5})*1024^2;
                elseif strcmp(tokens{1}{6}, 'k') 
                    tokens{1}{5} = str2double(tokens{1}{5})*1024;
                end
                info = struct('Used', tokens{1}{1}, ...
                    'Wired', tokens{1}{3}, ...
                    'Unused', tokens{1}{5}, ...
                    'Total', tokens{1}{1} + tokens{1}{3});
                break;
            end
        end
    else
        [~, text] = unix('top -n 1');
        fields = textscan(text, '%s', 'Delimiter', '\n' ); 
        fields = fields{1};
        fields( cellfun( 'isempty', fields ) ) = [];
        for i = 1:length(fields)
            tokens = regexp(fields{i}, ['^Mem[^0-9]+([0-9]+)([MGk]) total', ...
                '[^0-9]+([0-9]+)([MGk]) used[^0-9]+([0-9]+)([MGk]) free'], ...
                'tokens');
            if ~isempty(tokens)
                if strcmp(tokens{1}{2}, 'G') 
                    tokens{1}{1} = str2double(tokens{1}{1})*1024^3;
                elseif strcmp(tokens{1}{2}, 'M') 
                    tokens{1}{1} = str2double(tokens{1}{1})*1024^2;
                elseif strcmp(tokens{1}{2}, 'k') 
                    tokens{1}{1} = str2double(tokens{1}{1})*1024;
                end
                if strcmp(tokens{1}{4}, 'G') 
                    tokens{1}{3} = str2double(tokens{1}{3})*1024^3;
                elseif strcmp(tokens{1}{4}, 'M') 
                    tokens{1}{3} = str2double(tokens{1}{3})*1024^2;
                elseif strcmp(tokens{1}{4}, 'k') 
                    tokens{1}{3} = str2double(tokens{1}{3})*1024;
                end
                if strcmp(tokens{1}{6}, 'G') 
                    tokens{1}{5} = str2double(tokens{1}{5})*1024^3;
                elseif strcmp(tokens{1}{6}, 'M') 
                    tokens{1}{5} = str2double(tokens{1}{5})*1024^2;
                elseif strcmp(tokens{1}{6}, 'k') 
                    tokens{1}{5} = str2double(tokens{1}{5})*1024;
                end
                info = struct('Total', tokens{1}{1}, ...
                    'Used', tokens{1}{3}, ...
                    'Unused', tokens{1}{5});
                break;
            end
        end
    end
else
    [~, sys] = memory;
    info = struct('Total', sys.PhysicalMemory.Total, 'Used', ...
        sys.PhysicalMemory.Total - sys.PhysicalMemory.Available, ...
        'Unused', sys.PhysicalMemory.Available);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = cpuinfo()
%CPUINFO  read CPU configuration
%
%   info = CPUINFO() returns a structure containing various bits of
%   information about the CPU and operating system as provided by /proc/cpu
%   (Unix), sysctl (Mac) or WMIC (Windows). This information includes:
%     * CPU name
%     * CPU clock speed
%     * CPU Cache size (L2)
%     * Number of physical CPU cores
%     * Operating system name & version
%
%   See also: COMPUTER, ISUNIX, ISMAC

%   Author: Ben Tordoff
%   Copyright 2011 The MathWorks, Inc.

if isunix
    if ismac
        info = cpuInfoMac();
    else
        info = cpuInfoUnix();
    end
else
    info = cpuInfoWindows();
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = cpuInfoWindows()
sysInfo = callWMIC( 'cpu' );
osInfo = callWMIC( 'os' );

info = struct( ...
    'Name', sysInfo.Name, ...
    'Clock', [sysInfo.MaxClockSpeed,' MHz'], ...
    'Cache', [sysInfo.L2CacheSize,' KB'], ...
    'NumProcessors', str2double( sysInfo.NumberOfCores ), ...
    'OSType', 'Windows', ...
    'OSVersion', osInfo.Caption );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = callWMIC( alias )
% Call the MS-DOS WMIC (Windows Management) command
olddir = pwd();
cd( tempdir );
sysinfo = evalc( sprintf( '!wmic %s get /value', alias ) );
cd( olddir );
fields = textscan( sysinfo, '%s', 'Delimiter', '\n' ); 
fields = fields{1};
fields( cellfun( 'isempty', fields ) ) = [];
% Each line has "field=value", so split them
values = cell( size( fields ) );
for ff=1:numel( fields )
    idx = find( fields{ff}=='=', 1, 'first' );
    if ~isempty( idx ) && idx>1
        values{ff} = strtrim( fields{ff}(idx+1:end) );
        fields{ff} = strtrim( fields{ff}(1:idx-1) );
    end
end

% Remove any duplicates (only occurs for dual-socket PC's and we will
% assume that all sockets have the same processors in them).
numResults = sum( strcmpi( fields, fields{1} ) );
if numResults>1
    % If we are counting cores, sum them.
    numCoresEntries = find( strcmpi( fields, 'NumberOfCores' ) );
    if ~isempty( numCoresEntries )
        cores = cellfun( @str2double, values(numCoresEntries) );
        values(numCoresEntries) = {num2str( sum( cores ) )};
    end
    % Now remove the duplicate results
    [fields,idx] = unique(fields,'first');
    values = values(idx);
end

% Convert to a structure
info = cell2struct( values, fields );

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = cpuInfoMac()
machdep = callSysCtl( 'machdep.cpu' );
hw = callSysCtl( 'hw' );
info = struct( ...
    'Name', machdep.brand_string, ...
    'Clock', [num2str(str2double(hw.cpufrequency_max)/1e6),' MHz'], ...
    'Cache', [machdep.cache.size,' KB'], ...
    'NumProcessors', str2double( machdep.core_count ), ...
    'OSType', 'Mac OS X', ...
    'OSVersion', getOSXVersion() );

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = callSysCtl( namespace )
infostr = evalc( sprintf( '!sysctl -a %s', namespace ) );
% Remove the prefix
infostr = strrep( infostr, [namespace,'.'], '' );
% Now break into a structure
infostr = textscan( infostr, '%s', 'delimiter', '\n' );
infostr = infostr{1};
info = struct();
for ii=1:numel( infostr )
    colonIdx = find( infostr{ii}==':', 1, 'first' );
    if isempty( colonIdx ) || colonIdx==1 || colonIdx==length(infostr{ii})
        continue
    end
    prefix = infostr{ii}(1:colonIdx-1);
    value = strtrim(infostr{ii}(colonIdx+1:end));
    while ismember( '.', prefix )
        dotIndex = find( prefix=='.', 1, 'last' );
        suffix = prefix(dotIndex+1:end);
        prefix = prefix(1:dotIndex-1);
        value = struct( suffix, value );
    end
    info.(prefix) = value;
    
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function vernum = getOSXVersion()
% Extract the OS version number from the system software version output.
ver = evalc('system(''sw_vers'')');
vernum = ...
    regexp(ver, 'ProductVersion:\s([1234567890.]*)', 'tokens', 'once');
vernum = strtrim(vernum{1});

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = cpuInfoUnix()
txt = readCPUInfo();
cpuinfo = parseCPUInfoText( txt );

txt = readOSInfo();
osinfo = parseOSInfoText( txt );

% Merge the structures
info = cell2struct( [struct2cell( cpuinfo );struct2cell( osinfo )], ...
    [fieldnames( cpuinfo );fieldnames( osinfo )] );

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = parseCPUInfoText( txt )
% Now parse the fields
lookup = {
    'model name', 'Name'
    'cpu Mhz', 'Clock'
    'cpu cores', 'NumProcessors'
    'cache size', 'Cache'
    };
info = struct( ...
    'Name', {''}, ...
    'Clock', {''}, ...
    'Cache', {''} );
for ii=1:numel( txt )
    if isempty( txt{ii} )
        continue;
    end
    % Look for the colon that separates the property name from the value
    colon = find( txt{ii}==':', 1, 'first' );
    if isempty( colon ) || colon==1 || colon==length( txt{ii} )
        continue;
    end
    fieldName = strtrim( txt{ii}(1:colon-1) );
    fieldValue = strtrim( txt{ii}(colon+1:end) );
    if isempty( fieldName ) || isempty( fieldValue )
        continue;
    end
    
    % Is it one of the fields we're interested in?
    idx = find( strcmpi( lookup(:,1), fieldName ) );
    if ~isempty( idx )
        newName = lookup{idx,2};
        info.(newName) = fieldValue;
    end
end

% Convert clock speed
info.Clock = [info.Clock, ' MHz'];

% Convert num cores
info.NumProcessors = str2double( info.NumProcessors );

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = parseOSInfoText( txt )
info = struct( ...
    'OSType', 'Linux', ...
    'OSVersion', '' );
% find the string "linux version" then look for the bit in brackets
[~,b] = regexp( txt, '[^\(]*\(([^\)]*)\).*', 'match', 'tokens', 'once' );
info.OSVersion = b{1}{1};

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function txt = readCPUInfo()

fid = fopen( '/proc/cpuinfo', 'rt' );
if fid<0
    error( 'cpuinfo:BadPROCCPUInfo', ...
        'Could not open /proc/cpuinfo for reading' );
end
out = onCleanup( @() fclose( fid ) );

txt = textscan( fid, '%s', 'Delimiter', '\n' );
txt = txt{1};

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function txt = readOSInfo()

fid = fopen( '/proc/version', 'rt' );
if fid<0
    error( 'cpuinfo:BadProcVersion', ...
        'Could not open /proc/version for reading' );
end
out = onCleanup( @() fclose( fid ) );

txt = textscan( fid, '%s', 'Delimiter', '\n' );
txt = txt{1};

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sl = sloc(file)
%SLOC Counts number source lines of code.
%   SL = SLOC(FILE) returns the line count for FILE.  If there are multiple
%   functions in one file, subfunctions are not counted separately, but
%   rather together.
%
%   The following lines are not counted as a line of code:
%   (1) The "function" line
%   (2) A line that is continued from the previous line --> ...
%   (3) A comment line, a line that starts with --> % or a line that is
%       part of a block comment (   %{...%}   )
%   (4) A blank line
%   (5) An array or cell array line
%
%   Note: If more than one statement is on the line, it counts that as one
%   line of code.  For instance the following is considered to be one line 
%   of code:
%
%        minx = 32; maxx = 100;
%
%   Copyright 2004-2005 MathWorks, Inc.
%   Raymond S. Norris (rayn@mathworks.com)
%   $Revision: 1.4 $ $Date: 2006/03/08 19:50:30 $
%   Modified by Mark Geurts

% Check to see if the ".m" is missing from the M-file name
file = deblank(file);
if length(file)<3 || ~strcmp(file(end-1:end),'.m')
   file = [file '.m'];
end

% Open read handle to file
fid = fopen(file, 'r');

% If file handle is unavailable, return 0
if fid < 3
   sl = 0;
   return;
end

% Initialize variables
sl = 0;
previous_line = '-99999';
inblockcomment = false;

% Loop through file contents
while ~feof(fid)

    % Get the next line, stripping white characters
    m_line = strtrim(fgetl(fid));

    % The Profiler doesn't include the "function" line of a function, so
    % skip it.  Because nested functions may be indented, trim the front of
    % the line of code.  Since we are string trimming the line, we may as 
    % well check here if the resulting string it empty.  If any of the above
    % is true, just continue onto the next line.
    
    if strncmp(m_line,'function ', 9) || isempty(m_line)
        continue
    end

    % Check for block comments ( %{...%} )
    if length(m_line)>1 && strcmp(m_line(1:2),'%{')
        inblockcomment = true;
    elseif length(previous_line)>1 && strcmp(previous_line(1:2),'%}')
        inblockcomment = false;
    end

    % Check if comment line or if line continued from previous line
    if ~strcmp(m_line(1),'%') &&  ~strcmp(m_line(1),'''') && ...
             ~strcmp(m_line(1),']') && ~strcmp(m_line(1),'}') && ...
            ~(length(previous_line)>2 && ...
            strcmp(previous_line(end-2:end),'...') && ...
            ~strcmp(previous_line(1),'%')) && ...
            isempty(regexp(m_line(1), '[0-9]', 'once')) && ~inblockcomment
        sl = sl+1;
    end

    % Keep track of current line to see if the next line is a continuation
    % of the current
    previous_line = m_line;
end

% Close file handle
fclose(fid);

end
