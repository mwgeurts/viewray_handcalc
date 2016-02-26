function varargout = PrintReport(varargin)
% 
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

% Last Modified by GUIDE v2.5 25-Feb-2016 10:44:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PrintReport_OpeningFcn, ...
                   'gui_OutputFcn',  @PrintReport_OutputFcn, ...
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
function PrintReport_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to PrintReport (see VARARGIN)

% Choose default command line output for PrintReport
handles.output = hObject;

% Log start of printing and start timer
Event('Printing report');
tic;

% Load data structure from varargin
for i = 1:length(varargin)
    if strcmp(varargin{i}, 'Data')
        data = varargin{i+1}; 
        break; 
    end
end

% Set logo
axes(handles.logo);
rgb = imread('UWCrest_4c.png', 'BackgroundColor', [1 1 1]);
image(rgb);
axis equal;
axis off;
clear rgb;

% Get user name
[s, cmdout] = system('whoami');
if s == 0
    user = strtrim(cmdout);
else
    % If run as an automated unit test, do not prompt
    if data.unitflag == 0
        cmdout = inputdlg('Enter your name:', 'Username', [1 50]);
    else
        cmdout{1} = 'Unit test';
    end
    user = cmdout{1};
end
clear s cmdout;

% Clip report if it is too long
report = get(data.report, 'String');
if length(report) > 80
    report = sprintf('%s\n%s', report(1:80), report(81:end));
end

% Set report date/time, username, and version
set(handles.text12, 'String', sprintf('%s\n\n%s\n\n%s (%s)\n\n%s', ...
    datestr(now), user, data.version, data.versionInfo{6}, report));

% Set patient information
table = get(data.patient_table, 'Data');
set(handles.text19, 'String', sprintf('%s\n\n', table{1:size(table,1),1}));
set(handles.text20, 'String', sprintf('%s\n\n', table{1:size(table,1),2}));

% Set machine information
table = get(data.machine_table, 'Data');
set(handles.text46, 'String', sprintf('%s\n\n', table{1:size(table,1),1}));
set(handles.text47, 'String', sprintf('%s\n\n', table{1:size(table,1),2}));

% Set calibration information
table = get(data.cal_table, 'Data');
set(handles.text48, 'String', sprintf('%s Calibration\n\n', ...
    table{1:size(table,1),1}));
set(handles.text49, 'String', sprintf('%s\n\n', table{1:size(table,1),2}));
set(handles.text52, 'String', sprintf('%s\n\n', table{1:size(table,1),3}));

% Set beam information
table = get(data.beam_table, 'Data');
set(handles.text50, 'String', sprintf('%s\n\n', table{1:size(table,1),1}));
for i = 1:6
    if size(table,2) > i
        set(handles.(sprintf('text%i',i+53)), 'String', sprintf('%s\n\n', ...
            table{1:size(table,1),i+1}));
    else
        set(handles.(sprintf('text%i',i+53)), 'String', '');
    end
end

% Update handles structure
guidata(hObject, handles);

% Get temporary file name
temp = [tempname, '.pdf'];

% Print report
Event(['Saving report to ', temp]);
saveas(hObject, temp);

% Open file (if not running as an automated unit test)
if data.unitflag == 0
    Event(['Opening file ', temp]);
    open(temp);
else
    Event('Skipping file open in unit test framework', 'UNIT');
end

% Clear temporary variables
clear table data user headers;

% Log completion
Event(sprintf('Report saved successfully in %0.3f seconds', toc));

% Close figure
close(hObject);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function PrintReport_OutputFcn(~, ~, ~) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
