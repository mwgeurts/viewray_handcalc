function varargout = HandCalcUI(varargin)
% HandCalcUI launches the graphical user interface for this application.
% The ViewRay Secondary Dose Calculator Tool tool was developed to read in 
% ViewRay fixed conformal plan reports, extract the beam data (angle, field 
% size, depth, etc.), and recalculate the beam time using a two-dimensional 
% (2D) dose calculation algorithm using simplified measured beam data. The
% planned beam time is then compared to the recalculated beam time to check
% for major dosimetric discrepancies. A report can also be printed to 
% document the check.
%
% Following installation, this tool can be launched the application 
% shortcut (if installed as a MATLAB application) or by executing 
% HandCalcUI(). Then, click "Browse" and select a ViewRay plan PDF or text
% report. This tool can only be used with fixed conformal plans or
% optimized conformal if the relative dose from each beam to a reference 
% point is known.
% 
% This function defines several global variables which are used during
% calculation. See the wiki for more information on these variables and
% their function, as well as to learn more about the computational methods.
%
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2016 University of Wisconsin Board of Regents
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

% Last Modified by GUIDE v2.5 25-Feb-2016 21:33:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @HandCalcUI_OpeningFcn, ...
                   'gui_OutputFcn',  @HandCalcUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function HandCalcUI_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version_text of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to HandCalcUI (see VARARGIN)

% Choose default command line output for HandCalcUI
handles.output = hObject;

% Declare default planning source strength, in Gy/min
handles.k = 1.85; 

%% Global variables
% Declare default machine name and serial number
handles.defaultmachine = 'ViewRay MRIdian';
handles.defaultserial = '101';

% Declare Co-60 half life, in days
handles.halflife = 1925.2;

% Set version_text handle
handles.version = '0.9';

%% Prepare path, logs
% Determine path of current application
[path, ~, ~] = fileparts(mfilename('fullpath'));

% Set current directory to location of this application
cd(path);
handles.path = path;

% clear_button temporary variable
clear path;

% Set version_text information.  See LoadVersionInfo for more details.
handles.versionInfo = LoadVersionInfo;

% Store program and MATLAB/etc version_text information as a string cell array
string = {'ViewRay Secondary Dose Calculation'
    sprintf('Version: %s (%s)', handles.version, handles.versionInfo{6});
    sprintf('Author: Mark Geurts <mark.w.geurts@gmail.com>');
    sprintf('MATLAB Version: %s', handles.versionInfo{2});
    sprintf('MATLAB License Number: %s', handles.versionInfo{3});
    sprintf('Operating System: %s', handles.versionInfo{1});
    sprintf('CUDA: %s', handles.versionInfo{4});
    sprintf('Java Version: %s', handles.versionInfo{5})
};

% Add dashed line separators      
separator = repmat('-', 1,  size(char(string), 2));
string = sprintf('%s\n', separator, string{:}, separator);

% Log information
Event(string, 'INIT');

%% Initialize UI
% Set version_text UI text
set(handles.version_text, 'String', sprintf('Version %s', handles.version));

% Specify patient row names
handles.patient_rows = {
    'Patient ID'
    'Name'
    'Birthdate'
    'Diagnosis'
    'Prescription'
    'Fractions'
    'Density Image'
    'Density Overrides'
    'Plan Name'
    'Approved By'
};

% Specify machine row names
handles.machine_rows = {
    'Machine Name'
    'Serial Number'
    'Software Version'
    'Model'
    'Institution'
    'Planning Strength'
};

% Specify calibration rows
handles.cal_rows = {
    'Head 1'
    'Head 2'
    'Head 3'
};

% Specify beam rows
handles.beam_rows = {
    'Angle'
    'Group'
    'Beam Type'
    'Isocenter'
    'Open Field Size'
    'Calc Point (CP)'
    'Total Dose to CP'
    'Weight to CP'
    'SSD to CP'
    'Depth to CP'
    'Effective Depth'
    'OAD to CP'
    'Planned Time'
    'TPR'
    'Scp'
    'OAR'
    'Couch Factor'
    'Calculated Time'
    'Decay Corrected'
    'Difference'
};

% Initialize tables
set(handles.patient_table, 'Data', horzcat(handles.patient_rows, ...
    cell(length(handles.patient_rows), 1)));
set(handles.machine_table, 'Data', horzcat(handles.machine_rows, ...
    cell(length(handles.machine_rows), 1)));
set(handles.cal_table, 'Data', horzcat(handles.cal_rows, ...
    cell(length(handles.cal_rows), 1)));
set(handles.beam_table, 'Data', horzcat(handles.beam_rows, ...
    cell(length(handles.beam_rows), 1)));

%% Load calibration report
% Define source report directory
handles.sourcefolder = './sourcereport/';

% Retrieve folder contents of source report directory
report = dir(['./', handles.sourcefolder,'*.pdf']);

% If too many files were found, pick first one
if length(report) > 1
    Event('Multiple files were found in source calibration folder', 'WARN');
    report = report(1);
end

% If a file was found
if ~isempty(report)
    
    % Load calibration data
    handles.calibration = ParseSourceTrackingPDF(handles.sourcefolder, ...
        report.name);
    
    % Update calibration table
    Event('Updating calibration table');
    data = get(handles.cal_table, 'Data');
    
    % Loop through calibration strengths
    for i = 1:length(handles.calibration.strength)
        
        % Set strength and calibration date
        data{i,2} = sprintf('%0.3f Gy/min', ...
            handles.calibration.strength{i});
        data{i,3} = datestr(handles.calibration.strengthdate{i}, ...
            'mm/dd/yyyy');
    end
    
    % Set updated values
    set(handles.cal_table, 'Data', data);
    
    % Clear temporary variable
    clear data;

% Otherwise no calibration data was found
else
    Event(['No source calibration reports were found in ', ...
        handles.sourcefolder], 'ERROR');
end


%% Finish up
% Unit test flag. This will be set to 1 if the application is being run as
% part of unit testing (see UnitTest for more information)
handles.unitflag = 0;

% Log completion
Event('Initialization completed. Click Browse to load a plan report.');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = HandCalcUI_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version_text of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function print_button_Callback(~, ~, handles) %#ok<*DEFNU>
% hObject    handle to print_button (see GCBO)
% eventdata  reserved - to be defined in a future version_text of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('Print button selected');

% Execute PrintReport, passing current handles structure as data
PrintReport('Data', handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function clear_button_Callback(hObject, ~, handles)
% hObject    handle to clear_button (see GCBO)
% eventdata  reserved - to be defined in a future version_text of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('Clearing all data');

% Clear patient table
data = get(handles.patient_table, 'Data');
for i = 1:size(data,1)
    data{i,2} = [];
end
set(handles.patient_table, 'Data', data);

% Clear machine table
data = get(handles.machine_table, 'Data');
for i = 1:size(data,1)
    data{i,2} = [];
end
set(handles.machine_table, 'Data', data);

% Clear beams table
data = get(handles.beam_table, 'Data');
for i = 1:size(data,1)
    for j = 2:size(data,2)
        data{i,j} = [];
    end
end
set(handles.beam_table, 'Data', data);

% Clear report
set(handles.report, 'String', '');

% Clear difference
set(handles.difference, 'Enable', 'off');
set(handles.difference, 'BackgroundColor', [1 1 1]);
set(handles.difference, 'Enable', 'on');
set(handles.difference, 'String', '');

% Clear internal variables
handles.patient = struct;
handles.machine = struct;
handles.beams = cell(0);
handles.points = cell(0);
handles.calcs = cell(0);
handles.meandiff = [];

% Clear temporary variable
clear data

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function report_Callback(~, ~, ~)
% hObject    handle to report (see GCBO)
% eventdata  reserved - to be defined in a future version_text of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function report_CreateFcn(hObject, ~, ~)
% hObject    handle to report (see GCBO)
% eventdata  reserved - to be defined in a future version_text of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Set background color
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function browse_button_Callback(hObject, ~, handles)
% hObject    handle to browse_button (see GCBO)
% eventdata  reserved - to be defined in a future version_text of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('Report browse button selected');

% Request the user to select the plan report
Event('UI window opened to select file');
[name, path] = uigetfile({'*.pdf', 'Plan PDF Report (.pdf)'; '*.txt', ...
    'Plan Text Report (.txt)'}, 'Select the plan report PDF or text file', ...
    handles.path);

% If a file was selected
if iscell(name) || sum(name ~= 0)
    
    % Update text box with file name
    set(handles.report, 'String', fullfile(path, name));
           
    % Log names
    Event([fullfile(path, name),' selected']);
    
    % Update default path
    handles.path = path;
    Event(['Default file path updated to ', path]);
    
    % If the user selected PDF data
    if ~isempty(regexpi(name, '.pdf$'))
        
        % Parse text file using ParsePlanTextReport
        [handles.patient, handles.machine, handles.points, handles.beams] ...
            = ParsePlanReportPDF(path, name);
        
    % Or if the user selected TXT data    
    elseif ~isempty(regexpi(name, '.txt$'))
        
        % Parse text file using ParsePlanTextReport
        [handles.patient, handles.machine, handles.points, handles.beams] ...
            = ParsePlanReportText(path, name);
    
    % Otherwise throw an error
    else
        Event('An unknown file format was selected', 'ERROR');
    end
    
    % Get the number of fractions, if not provided
    if ~isfield(handles.patient, 'fractions')
        handles.patient.fractions = str2double(inputdlg(...
            'Enter the number of fractions'));
    end
    
    %% Set patient data
    % Get patient table contents
    data = get(handles.patient_table, 'Data');
    
    % Update patient ID
    data{1,2} = handles.patient.id;
    
    % Update name
    data{2,2} = handles.patient.name;
    
    % Update birthdate if present
    if isfield(handles.patient, 'birthdate')
        data{3,2} = datestr(handles.patient.birthdate, 'mm/dd/yyyy');
    end
    
    % Update diagnosis if present
    if isfield(handles.patient, 'diagnosis')
        data{4,2} = handles.patient.diagnosis;
    end
    
    % Update prescription if all fields are present
    if isfield(handles.patient, 'rxvolume') && ...
            isfield(handles.patient, 'rxdose') && ...
            isfield(handles.patient, 'rxpercent')
        
        % Write prescription as "Dose to % of Structure"
        data{5,2} = sprintf('%0.1f Gy to %0.1f%% of %s', ...
            handles.patient.rxdose, handles.patient.rxpercent, ...
            handles.patient.rxvolume);
    end
    
    % Update number of fractions
    data{6,2} = sprintf('%i', handles.patient.fractions);
    
    % Update density CT information if present
    if isfield(handles.patient, 'densityct')
        
        % If no CT UID exists, state 'None'
        if isempty(handles.patient.densityct)
            data{7,2} = 'None';
            
        % Otherwise state 'CT'
        else
            data{7,2} = 'CT';
        end
    end
    
    % Update list of structure density overrides, in prioritized order
    if isfield(handles.patient, 'densityoverrides')
        
        % Start with an empty cell
        data{8,2} = '';
        
        % Loop through structures list, in reverse order of priority
        for i = length(handles.patient.densityoverrides):-1:1
            
            % If a structure exists at this priority
            if ~isempty(handles.patient.densityoverrides{i})
                
                % If this is the first structure, just write the structure
                % and overridden density
                if isempty(data{8,2})
                    data{8,2} = sprintf('%s (%0.3f g/cc)', ...
                        handles.patient.densityoverrides{i}.name, ...
                        handles.patient.densityoverrides{i}.density);
                
                % Otherwise, append the existing cell contents using a
                % comma
                else
                    data{8,2} = sprintf('%s (%0.3f g/cc), %s', ...
                        handles.patient.densityoverrides{i}.name, ...
                        handles.patient.densityoverrides{i}.density, ...
                        data{8,2});
                end
            end
        end
    end
    
    % Update plan name if present
    if isfield(handles.patient, 'plan')
        data{9,2} = handles.patient.plan;
    end
    
    % Update plan approval date if present
    if isfield(handles.patient, 'planapproval')
        data{10,2} = handles.patient.planapproval;
    end
    
    % Set patient table with updated data
    set(handles.patient_table, 'Data', data);
    
    %% Set machine data
    % Get machine table contents
    data = get(handles.machine_table, 'Data');
    
    % Update machine name with the global default value
    data{1,2} = handles.defaultmachine;
    
    % If a serial number exists, update with that
    if isfield(handles.machine, 'serial')
        data{2,2} = handles.machine.serial;
        
    % Otherwise, use the global default value
    else
        data{2,2} = handles.defaultserial;
    end
    
    % Update the machine version if present
    if isfield(handles.machine, 'version')
        data{3,2} = handles.machine.version;
    end
    
    % Update the dose model if present
    if isfield(handles.machine, 'model')
        data{4,2} = handles.machine.model;
    end
    
    % Update the institution if present
    if isfield(handles.machine, 'institution')
        
        % If the institution is too long, crop it
        if length(handles.machine.institution) > 23
            data{5,2} = handles.machine.institution(1:23);
        else
            data{5,2} = handles.machine.institution;
        end
    end
    
    % Update the planning strength using the global default value
    data{6,2} = sprintf('%0.2f Gy/min', handles.k);
    
    % Set the machine table with the updated cells
    set(handles.machine_table, 'Data', data);
    
    %% Set beam column information
    % Update the editable flags boolean array given the number of beams to
    % be displayed
    set(handles.beam_table, 'ColumnEditable', logical(horzcat(0, ...
        ones(1,length(handles.beams)))));
    
    % Update the column format using an empty array given the number of
    % beams to be displayed
    set(handles.beam_table, 'ColumnFormat', ...
        cell(1, length(handles.beams) + 1));
    
    % Initialize a new column names array
    names = cell(1, length(handles.beams)+1);
    
    % Initialize a new column widths array
    widths = cell(1, length(handles.beams)+1);
    
    % Set the first column name and width
    names{1} = 'Specification';
    widths{1} = 150;
    
    % Loop through a column for each beam
    for i = 1:length(handles.beams)
        
        % Set the beam column name and width
        names{i+1} = sprintf('Beam %i', i);
        widths{i+1} = 80;
    end
    
    % Update the column names and widths array
    set(handles.beam_table, 'ColumnName', names);
    set(handles.beam_table, 'ColumnWidth', widths);
    
    % Clear temporary variables
    clear names widths;
    
    %% Set beam report data
    % Get the beam table cell contents
    data = get(handles.beam_table, 'Data');
    
    % If only one point exists, use that one as the default calc point
    if length(handles.points) == 1
        defaultcalcpt = 1;
    
    % Otherwise, initialize an empty flag to store the selected calc point
    else
        defaultcalcpt = 0;
    end

    % Loop through each beam
    for i = 1:length(handles.beams)
        
        % Initialize point indices
        isopt = 1;
        calcpt = defaultcalcpt;
        
        % Get the calc point index from the beams array, if it exists
        if isfield(handles.beams{i}, 'weightpt') && ...
                ~isempty(handles.beams{i}.weightpt)
            
            % Loop through each point
            for j = 1:length(handles.points)
                if strcmp(handles.beams{i}.weightpt, handles.points{j}.name)
                    calcpt = j;
                    break;
                end
            end
        end
        
        % Get the iso point index
        for j = 1:length(handles.points)
            if strcmp(handles.beams{i}.iso, handles.points{j}.name)
                isopt = j;
                break;
            end
        end
        
        % If a default calc point was not set
        if calcpt == 0

            % Initialize point names list
            names = cell(1, length(handles.points));
            
            % Loop through each calc point
            for j = 1:length(handles.points)
                names{j} = handles.points{j}.name;
            end
            
            % Prompt user to select a calc point
            [calcpt, selected] = listdlg('PromptString', ...
                'Select a point to use for calculation', 'SelectionMode', ...
                'single', 'ListString', names, 'ListSize', [300 50]);
            
            % Make sure the user selected something
            if selected == 0
                Event('A calculation point must be selected to continue', ...
                    'ERROR');
            end
            
            % Update the default calc point to the selected one
            defaultcalcpt = calcpt;
        end
        
        % Get the calc point dose, if not set
        if ~isfield(handles.points{calcpt}, 'dose')
            handles.points{calcpt}.dose = str2double(inputdlg(sprintf(...
            'Enter the total dose, from all fractions, to %s in Gy', ...
            handles.points{calcpt}.name)));
        end
        
        % Get calc point weight, if not set
        if ~isfield(handles.beams{i}, 'weight') || ...
                isempty(handles.beams{i}.weight)
            handles.beams{i}.weight = str2double(inputdlg(sprintf(...
            'Enter the weight of beam %i to %s as a percent', ...
            i, handles.points{calcpt}.name)));
        end
        
        % Set input fields
        data{1,1+i} = sprintf('%g°', handles.beams{i}.angle);
        data{2,1+i} = sprintf('Group %i', handles.beams{i}.group);
        data{3,1+i} = strrep(handles.beams{i}.type, ' Conformal', '');
        data{4,1+i} = handles.beams{i}.iso;
        data{5,1+i} = sprintf('%0.2f cm', handles.beams{i}.equivsquare);
        data{6,1+i} = handles.points{calcpt}.name;
        data{7,1+i} = sprintf('%0.3f Gy', handles.points{calcpt}.dose);
        data{8,1+i} = sprintf('%0.2f%%', handles.beams{i}.weight);
        data{9,1+i} = sprintf('%0.2f cm', handles.beams{i}.ssd(calcpt));
        data{10,1+i} = sprintf('%0.2f cm', handles.beams{i}.depth(calcpt));
        data{11,1+i} = sprintf('%0.2f cm', handles.beams{i}.edepth(calcpt));
        data{12,1+i} = sprintf('%0.2f cm', handles.beams{i}.oad(isopt));
        data{13,1+i} = sprintf('%0.2f sec', handles.beams{i}.plantime);
    end
    set(handles.beam_table, 'Data', data);
    
    % Calculate dose for each beam
    tic;
    patient = get(handles.patient_table, 'Data');
    beams = get(handles.beam_table, 'Data');
    cal = get(handles.cal_table, 'Data');
    ss = zeros(1,size(cal,2));
    sds = zeros(1,size(cal,2));
    for i = 1:size(cal,2)
        ss(i) = cell2mat(textscan(cal{i,2}, '%f Gy/min'));
        sds(i) = datenum(cal{i,3});
    end
    for i = 1:length(handles.beams)
        
        % Validate inputs
        if ValidateCalcInputs(patient, beams, i)
            
            % Calculate dose for beam
            handles.calcs{i} = CalculateBeamTime('k', handles.k, 'angle', ...
                handles.beams{i}.angle, 'r', handles.beams{i}.equivsquare, ...
                'dose', handles.points{calcpt}.dose * ...
                handles.beams{i}.weight / 100 / handles.patient.fractions, ...
                'depth', handles.beams{i}.edepth(calcpt), 'oad', ...
                handles.beams{i}.oad(isopt));
            
            % Set calculated fields
            beams{14,1+i} = sprintf('%0.4f', handles.calcs{i}.tpr);
            beams{15,1+i} = sprintf('%0.4f', handles.calcs{i}.scp);
            beams{16,1+i} = sprintf('%0.4f', handles.calcs{i}.oar);
            beams{17,1+i} = sprintf('%0.4f', handles.calcs{i}.cf);
            beams{18,1+i} = sprintf('%0.2f sec', handles.calcs{i}.time);
            beams{20,1+i} = sprintf('%0.2f%%', 100*(handles.calcs{i}.time - ...
                handles.beams{i}.plantime)/handles.beams{i}.plantime);
            
            % Calculate decay-corrected time
            if (handles.beams{i}.angle >= 30 && ...
                    handles.beams{i}.angle < 150)
                s = ss(1);
                d = sds(1);
            elseif (handles.beams{i}.angle >= 150 && ...
                    handles.beams{i}.angle < 270)
                s = ss(2);
                d = sds(2);
            else
                s = ss(3);
                d = sds(3);
            end
            beams{19,1+i} = sprintf('%0.2f sec', handles.calcs{i}.time * ...
                handles.k / s * 1 / exp(-log(2) / handles.halflife * ...
                (now() - d)));
        else
            Event(sprintf(['Secondary dose calculation inputs are not ', ...
                'valid for beam %i'], i), 'WARN');
        end
    end
    set(handles.beam_table, 'Data', beams);
    
    % Calculate weighted mean difference
    ws = 0;
    s = 0;
    for i = 2:size(beams,2)
        s = s + str2double(strrep(beams{8,i},'%',''));
        ws = ws + str2double(strrep(beams{8,i},'%','')) * ...
            str2double(strrep(beams{20,i},'%',''));
    end
    handles.meandiff = ws / s;
    
    % Update difference field on UI
    set(handles.difference, 'Enable', 'off');
    if abs(handles.meandiff) < 5
        set(handles.difference, 'BackgroundColor', [0.8 1 0.8]);
    elseif abs(handles.meandiff) < 10
        set(handles.difference, 'BackgroundColor', [1 1 0.8]);
    else
        set(handles.difference, 'BackgroundColor', [1 0.8 0.8]);
    end
    set(handles.difference, 'Enable', 'on');
    set(handles.difference, 'String', sprintf('%0.2f%%', handles.meandiff));
    
    % Log result
    Event(['Weighted mean calculation difference computed as ', ...
        sprintf('%0.2f%%', handles.meandiff)]);
    
    Event(sprintf(['Report calculations completed successfully in %0.3f ', ...
        'seconds'], toc));
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function figure1_SizeChangedFcn(hObject, ~, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Set units to pixels
set(hObject,'Units','pixels') 

% Get patient table width
pos = get(handles.uipanel1, 'Position') .* ...
    get(handles.patient_table, 'Position') .* ...
    get(hObject, 'Position');

% Update patient column widths to scale to new table size
set(handles.patient_table, 'ColumnWidth', ...
    {floor(0.4*pos(3))-4 floor(0.6*pos(3))-6});

% Get machine table width
pos = get(handles.uipanel2, 'Position') .* ...
    get(handles.machine_table, 'Position') .* ...
    get(hObject, 'Position');

% Update machine column widths to scale to new table size
set(handles.machine_table, 'ColumnWidth', ...
    {floor(0.4*pos(3))-4 floor(0.6*pos(3))-6});

% Get calibration table width
pos = get(handles.uipanel2, 'Position') .* ...
    get(handles.cal_table, 'Position') .* ...
    get(hObject, 'Position');

% Update calibration column widths to scale to new table size
set(handles.cal_table, 'ColumnWidth', ...
    {floor(0.33*pos(3)) floor(0.33*pos(3))-4 floor(0.33*pos(3))-4});

% Clear temporary variables
clear pos;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function patient_table_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to patient_table (see GCBO)
% eventdata  structure with the following fields
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty 
%       if Data was not changed
%	Error: error string when failed to convert EditData to appropriate 
%       value for Data
% handles    structure with handles and user data (see GUIDATA)

if ~isempty(eventdata.NewData)
    data = get(hObject, 'Data');
    data{eventdata.Indices(1), eventdata.Indices(2)} = ...
        eventdata.PreviousData;
    set(hObject, 'Data', data);
    
    Event(['Patient data cannot be edited at this time. Use Browse to ', ...
        'load a plan report'], 'WARN');
    clear data;
end
    
% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function machine_table_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to patient_table (see GCBO)
% eventdata  structure with the following fields
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty 
%       if Data was not changed
%	Error: error string when failed to convert EditData to appropriate 
%       value for Data
% handles    structure with handles and user data (see GUIDATA)

if ~isempty(eventdata.NewData)
    data = get(hObject, 'Data');
    data{eventdata.Indices(1), eventdata.Indices(2)} = ...
        eventdata.PreviousData;
    set(hObject, 'Data', data);
    
    Event(['Machine data cannot be edited at this time. Use Browse to ', ...
        'load a plan report'], 'WARN');
    clear data;
end
    
% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cal_table_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to patient_table (see GCBO)
% eventdata  structure with the following fields
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty 
%       if Data was not changed
%	Error: error string when failed to convert EditData to appropriate 
%       value for Data
% handles    structure with handles and user data (see GUIDATA)

if ~isempty(eventdata.NewData)
    data = get(hObject, 'Data');
    data{eventdata.Indices(1), eventdata.Indices(2)} = ...
        eventdata.PreviousData;
    set(hObject, 'Data', data);
    
    Event(['Calibration data cannot be edited at this time. Use Browse to ', ...
        'load a plan report'], 'WARN');
    clear data;
end
    
% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function beam_table_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to patient_table (see GCBO)
% eventdata  structure with the following fields
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty 
%       if Data was not changed
%	Error: error string when failed to convert EditData to appropriate 
%       value for Data
% handles    structure with handles and user data (see GUIDATA)

if ~isempty(eventdata.NewData)
    data = get(hObject, 'Data');
    data{eventdata.Indices(1), eventdata.Indices(2)} = ...
        eventdata.PreviousData;
    set(hObject, 'Data', data);
    
    Event(['Beam data cannot be edited at this time. Use Browse to ', ...
        'load a plan report'], 'WARN');
    clear data;
end
    
% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function difference_Callback(hObject, ~, handles)
% hObject    handle to difference (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Revert to stored value
set(hObject, 'String', sprintf('%0.2f%%', handles.meandiff));

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function difference_CreateFcn(hObject, ~, ~)
% hObject    handle to difference (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
