function cal = ParseSourceTrackingPDF(varargin)
% ParseSourceTrackingPDF scans a ViewRay Source Tracking PDF report
% and extracts information about the sources, including activity and
% strengths. The data is returned as a structure. This function uses the
% xpdf_tools submodule.
%
% The following variables are required for proper execution: 
%   varargin: string or cell array of strings containing the file name. If
%       provided as a cell array, the fullfile() command is used to
%       concatenate the strings into a single path
%
% The following structure fields are returned upon successful completion:
%   cal.sourceid: cell array of strings containing each source ID
%   cal.activity: cell array of doubles containing each source activity in 
%       Curies
%   cal.activitydate: cell array of timestamps for each source
%   cal.strenth: cell array fo doubles containing each source calibration
%       strength in Gy/min
%   cal.strengthdate: cell array of timestamps for each strength
%       calibration
%   cal.system: string containing the system name
%   cal.serial: string containing the ViewRay machine serial number
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

% Initialize return variables
cal = struct;
cal.sourceid = cell(0);
cal.activity = cell(0);
cal.activitydate = cell(0);
cal.strength = cell(0);
cal.strengthdate = cell(0);

% Validate input arguments
if nargin >= 1
    file = fullfile(varargin{1:nargin});
else
    if exist('Event', 'file') == 2
        Event(['At least one argument must be passed to ', ...
            'ParseSourceTrackingPDF'], 'ERROR');
    else
        error(['At least one argument must be passed to ', ...
            'ParseSourceTrackingPDF']);
    end
end

% Add xpdf_tools submodule to search path
addpath('./xpdf_tools');

% Check if MATLAB can find XpdfText
if exist('XpdfText', 'file') ~= 2
    
    % If not, throw an error
    Event(['The xpdf_tools submodule does not exist in the search path. ', ...
        'Use git clone --recursive or git submodule init followed by git ', ...
        'submodule update to fetch all submodules'], 'ERROR');
end

% Log start of file load and start timer
if exist('Event', 'file') == 2
    Event(sprintf('Reading file %s', file));
    tic;
end

% Read PDF text contents
content = XpdfText(file);

% Loop through results
for i = 1:length(content{1})
    
    % Store line, remove duplicate spaces
    tline = strtrim(regexprep(content{1}{i}, '[ ]+', ' '));
    
    % Store system name
    if length(tline) > 7 && strcmp(tline(1:7), 'System:')
        fields = strsplit(tline(8:end), {'(', ')'});
        cal.system = strtrim(fields{1});
        cal.serial = strtrim(fields{2});
    
    % Store source ID
    elseif length(tline) > 10 && strcmp(tline(1:10), 'Source ID:')
        cal.sourceid{length(cal.sourceid)+1} = ...
            strtrim(tline(11:end));
    
    % Store source activity date
    elseif length(tline) > 17 && strcmp(tline(1:17), 'Certificate Date:')
        cal.activitydate{length(cal.activitydate)+1} = ...
            datenum(strtrim(tline(18:end)));
        
    % Store source activity
    elseif length(tline) > 31 && strcmp(tline(1:31), ...
            'Certificate Strength in Curies:')
        cal.activity{length(cal.activity)+1} = ...
            cell2mat(textscan(tline(32:end), '%f Curies'));
    
    % Store source strength
    elseif length(tline) > 32 && strcmp(tline(1:32), ...
            'Measured Dose Per Minute (TG51):')
        cal.strength{length(cal.strength)+1} = ...
            cell2mat(textscan(tline(33:end), '%f Gy/min'));
        
    % Store source strength date
    elseif length(tline) > 24 && strcmp(tline(1:24), ...
            'Measurement Date (TG51):')
        cal.strengthdate{length(cal.strengthdate)+1} = ...
            datenum(strtrim(tline(25:end)));
    end
end

% Log completion and image size
if ~isempty(cal.strength)
    if exist('Event', 'file') == 2
        Event(sprintf(['Source calibration data for %i heads parsed in ', ...
            '%0.3f seconds'], length(cal.strength), toc));
    end
end

% Clear temporary variables
clear file fields content i tline;


