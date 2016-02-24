function calibration = ParseSourceTrackingPDF(varargin)

% Initialize return variables
calibration = struct;
calibration.sourceid = cell(0);
calibration.activity = cell(0);
calibration.activitydate = cell(0);
calibration.strength = cell(0);
calibration.strengthdate = cell(0);

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
        calibration.system = strtrim(fields{1});
        calibration.serial = strtrim(fields{2});
    
    % Store source ID
    elseif length(tline) > 10 && strcmp(tline(1:10), 'Source ID:')
        calibration.sourceid{length(calibration.sourceid)+1} = ...
            strtrim(tline(11:end));
    
    % Store source activity date
    elseif length(tline) > 17 && strcmp(tline(1:17), 'Certificate Date:')
        calibration.activitydate{length(calibration.activitydate)+1} = ...
            datestr(strtrim(tline(18:end)));
        
    % Store source activity
    elseif length(tline) > 31 && strcmp(tline(1:31), 'Certificate Strength in Curies:')
        calibration.activity{length(calibration.activity)+1} = ...
            cell2mat(textscan(tline(32:end), '%f Curies'));
    
    % Store source strength
    elseif length(tline) > 32 && strcmp(tline(1:32), 'Measured Dose Per Minute (TG51):')
        calibration.strength{length(calibration.strength)+1} = ...
            cell2mat(textscan(tline(33:end), '%f Gy/min'));
        
    % Store source strength date
    elseif length(tline) > 24 && strcmp(tline(1:24), 'Measurement Date (TG51):')
        calibration.strengthdate{length(calibration.strengthdate)+1} = ...
            datestr(strtrim(tline(25:end)));
    
    end
end




