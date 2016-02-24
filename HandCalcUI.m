function varargout = HandCalcUI(varargin)
% HANDCALCUI MATLAB code for HandCalcUI.fig
%      HANDCALCUI, by itself, creates a new HANDCALCUI or raises the existing
%      singleton*.
%
%      H = HANDCALCUI returns the handle to a new HANDCALCUI or the handle to
%      the existing singleton*.
%
%      HANDCALCUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HANDCALCUI.M with the given input arguments.
%
%      HANDCALCUI('Property','Value',...) creates a new HANDCALCUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before HandCalcUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to HandCalcUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help HandCalcUI

% Last Modified by GUIDE v2.5 24-Feb-2016 10:44:09

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

% Set version_text handle
handles.version = '0.9';

% Determine path of current application
[path, ~, ~] = fileparts(mfilename('fullpath'));

% Set current directory to location of this application
cd(path);

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

% Disable print_button button
set(handles.print_button, 'enable', 'off');

% Disable clear_button button
set(handles.clear_button, 'enable', 'off');

% Specify Row Names
handles.patient_rows = {
    'Patient ID'
    'Name'
    'Birthdate'
    'Diagnosis'
    'Prescription'
    'Fractions'
    'Plan Name'
    'Approved By'
};
handles.machine_rows = {
    'Machine Name'
    'Serial Number'
    'Software Version'
    'Model'
    'Institution'
};
handles.cal_rows = {
    'Head 1'
    'Head 2'
    'Head 3'
};
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
    'Difference'
    'Decay Corrected Time'
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

% Otherwise no calibration data was found
else
    Event(['No source calibration reports were found in ', ...
        handles.sourcefolder], 'ERROR');
end


%% Finish up
% Log completion
Event('Initialization completed. Click Browse to load a plan report.');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = HandCalcUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version_text of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function print_button_Callback(hObject, eventdata, handles)
% hObject    handle to print_button (see GCBO)
% eventdata  reserved - to be defined in a future version_text of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function clear_button_Callback(hObject, eventdata, handles)
% hObject    handle to clear_button (see GCBO)
% eventdata  reserved - to be defined in a future version_text of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function report_Callback(hObject, eventdata, handles)
% hObject    handle to report (see GCBO)
% eventdata  reserved - to be defined in a future version_text of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function report_CreateFcn(hObject, eventdata, handles)
% hObject    handle to report (see GCBO)
% eventdata  reserved - to be defined in a future version_text of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function browse_button_Callback(hObject, eventdata, handles)
% hObject    handle to browse_button (see GCBO)
% eventdata  reserved - to be defined in a future version_text of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function figure1_SizeChangedFcn(hObject, eventdata, handles)
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
    {floor(0.4*pos(3))-4 floor(0.6*pos(3))-4});

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