function [patient, machine, points, beams] = ParsePlanReportPDF(varargin)
% ParsePlanReportPDF scans a ViewRay PDF plan report and extracts data
% such as patient, machine, points, and beam parameters into an array of
% structures. This function uses the xpdf_tools submodule to extract the
% PDF text into a MATLAB structure, then searches through the content and
% identifies which values to store.
%
% This function has been tested with plan reports from versions 3.5, 3.6, 
% and 4.0 of the ViewRay treatment system. For more information, see the
% Software Compatibilty wiki page for this project.
%
% The following variables are required for proper execution: 
%   varargin: string or cell array of strings containing the file name. If
%       provided as a cell array, the fullfile() command is used to
%       concatenate the strings into a single path
%
% The following variables are returned upon successful completion:
%   patient: structure of patient information containing the following
%       fields (note that fields will not be returned if the corresponding 
%       field is not found in the plan report): name, plan, lastmodified, 
%       id, mrn, birthdate, rxapproval, rxapprovaldate, contourapproval, 
%       contourapprovaldate, imageapproval, imageapprovaldate, 
%       planapproval, planapprovaldate, calendarapproval, 
%       calendarapprovaldate, coil, autonormalize, interdigitation, 
%       resolution, deform, deliverytime, position, diagnosis, rxvolume, 
%       rxdose, rxpercent, fractions, doseperfx, prevdose, couch, 
%       densityct, and densityoverrides (name, template, and density)
%   machine: structure of machine information containing the following
%       fields (note that fields will not be returned if the corresponding 
%       field is not found in the plan report): institution, version,
%       isotope, model, calibration (activity, activitydate, strength, and 
%       strengthdate), and planning (activity and strength)
%   points: a cell array of structures for each point in the plan, 
%       containing the following fields (note that fields will not be 
%       returned if the corresponding field is not found in the plan 
%       report): name, coordinates, dose, beams, and couch (coordinates)
%   beams: a cell array of structures for each beam in the plan, containing 
%       the following fields (note that fields will not be returned if the 
%       corresponding field is not found in the plan report): angle, group, 
%       ssd, depth, edepth, oad, type, segments, plantime, iso, 
%       equivsquare, weightpt, and weight
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
patient = struct;
machine = struct;
points = cell(0);
beams = cell(0);

% Validate input arguments
if nargin >= 1
    file = fullfile(varargin{1:nargin});
else
    if exist('Event', 'file') == 2
        Event(['At least one argument must be passed to ', ...
            'ParsePlanReportPDF'], 'ERROR');
    else
        error(['At least one argument must be passed to ', ...
            'ParsePlanReportPDF']);
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

% Concatenate all pages (currently disabled)
% content = cat(2,content{:});

% Loop through first page
for i = 1:length(content{1})
    
    % Store line, remove duplicate spaces
    tline = strtrim(regexprep(content{1}{i}, '[ ]+', ' '));
    
    % Store patient name
    if ~isempty(strfind(tline, 'Name:')) && ...
            ~isempty(strfind(tline, 'Site:'))
        patient.name = strtrim(tline(strfind(tline, 'Name:')+5:...
            strfind(tline, 'Site:')-1));
    
    % Store plan name and last modification date
    elseif ~isempty(strfind(tline, 'Plan:')) && ...
            ~isempty(strfind(tline, 'Last Modified:'))
        patient.plan = strtrim(tline(strfind(tline, 'Plan:')+5:...
            strfind(tline, 'Last Modified:')-1));
        patient.lastmodified = datenum(tline(...
            strfind(tline, 'Last Modified:')+14:end));
    
    % Store ID, MRN, and DOB
    elseif ~isempty(strfind(tline, 'Patient ID:')) && ...
            ~isempty(strfind(tline, 'MRN:')) && ...
            ~isempty(strfind(tline, 'DOB:'))
        patient.id = strtrim(tline(strfind(tline, 'Patient ID:')+11:...
            strfind(tline, 'MRN:')-1));
        patient.mrn = strtrim(tline(strfind(tline, 'MRN:')+4:...
            strfind(tline, 'DOB:')-1));
        patient.birthdate = datenum(tline(...
            strfind(tline, 'DOB:')+4:end));
    
    % Store institution
    elseif ~isempty(strfind(tline, 'Institution:')) && ...
            ~isempty(strfind(tline, 'Physician:'))
        machine.institution = strtrim(tline(strfind(tline, 'Institution:')...
            +12:strfind(tline, 'Physician:')-1));
        
    % Store software version
    elseif length(tline) > 16 && strcmp(tline(1:16), 'Software Version')
        machine.version = strtrim(tline(17:end));
        
    % Store isotope
    elseif length(tline) > 7 && strcmp(tline(1:7), 'Isotope')
        machine.isotope = strtrim(tline(8:end));    
    
    % Store prescription approval
    elseif length(tline) > 24 && strcmp(tline(1:24), ...
            'Prescription Approved By')
        fields = strsplit(tline(25:end), ',');
        patient.rxapproval = strtrim(fields{1}); 
        if length(fields) > 1
            patient.rxapprovaldate = datenum(strtrim(fields{2})); 
        end
    
    % Store contour approval
    elseif length(tline) > 22 && strcmp(tline(1:22), ...
            'Contouring Approved By')
        fields = strsplit(tline(23:end), ',');
        patient.contourapproval = strtrim(fields{1}); 
        if length(fields) > 1
            patient.contourapprovaldate = datenum(strtrim(fields{2})); 
        end
    
    % Store contour approval
    elseif length(tline) > 30 && strcmp(tline(1:30), ...
            'Image Registration Approved By')
        fields = strsplit(tline(31:end), ',');
        patient.imageapproval = strtrim(fields{1}); 
        if length(fields) > 1
            patient.imageapprovaldate = datenum(strtrim(fields{2})); 
        end
        
    % Store plan approval
    elseif length(tline) > 16 && strcmp(tline(1:16), 'Plan Approved By')
        fields = strsplit(tline(17:end), ',');
        patient.planapproval = strtrim(fields{1}); 
        if length(fields) > 1
            patient.planapprovaldate = datenum(strtrim(fields{2})); 
        end
        
    % Store calendar approval
    elseif length(tline) > 29 && strcmp(tline(1:29), ...
            'Delivery Calendar Approved By')
        fields = strsplit(tline(30:end), ',');
        patient.calendarapproval = strtrim(fields{1}); 
        if length(fields) > 1
            patient.calendarapprovaldate = datenum(strtrim(fields{2})); 
        end
        
    % Store dose model
    elseif length(tline) > 10 && strcmp(tline(1:10), 'Dose Model')
        machine.model = strtrim(tline(11:end));      
    
    % Store coil
    elseif length(tline) > 29 && strcmp(tline(1:29), ...
            'Dose Calculation Imaging Coil')
        patient.coil = strtrim(tline(30:end));   
    
    % Store auto normalize
    elseif length(tline) > 17 && strcmp(tline(1:17), 'Auto-Normalize On')
        patient.autonormalize = strtrim(tline(18:end));   
    
    % Store interdigitation
    elseif length(tline) > 21 && strcmp(tline(1:21), ...
            'Allow Interdigitation')
        patient.interdigitation = strtrim(tline(22:end));   
    
    % Store resolution
    elseif length(tline) > 25 && strcmp(tline(1:25), ...
            'Dose Grid Resolution (cm)')
        patient.resolution = str2double(tline(26:end));  
    
    % Store deform setting
    elseif length(tline) > 38 && strcmp(tline(1:38), ...
            'Deform Images for Treatment Processing')
        patient.deform = strtrim(tline(39:end));  
        
    % Store delivery time
    elseif length(tline) > 40 && strcmp(tline(1:40), ...
            'Treatment Delivery Time (sec) at Nominal')
        patient.deliverytime = strtrim(tline(41:end));  
    end  
end

% Loop through second page
for i = 1:length(content{2})
    
    % Store line, remove duplicate spaces
    tline = strtrim(regexprep(content{2}{i}, '[ ]+', ' '));
    
    % Store patient position acronym
    if length(tline) > 13 && strcmp(tline(1:13), 'Patient Setup')
        patient.position = regexprep(tline(14:end), '[^A-Z]', ''); 
    end
end

% Initialize calibration cells
machine.calibration.activity = cell(0);
machine.calibration.activitydate = cell(0);
machine.calibration.strength = cell(0);
machine.calibration.strengthdate = cell(0);

% Loop through third page
for i = 1:length(content{3})
    
    % Store line, remove duplicate spaces
    tline = strtrim(regexprep(content{3}{i}, '[ ]+', ' '));
    
    % Store nominal activity/source strength
    if length(tline) > 8 && strcmp(tline(1:8), ...
            'Planning')
        fields = textscan(tline(9:end), '%f Ci %f Gy/min'); 
        machine.planning.activity = fields{1};
        machine.planning.strength = fields{2}; 
    
    % Store calibrated activity
    elseif length(tline) > 11 && strcmp(tline(1:11), ...
            'Certificate')
        fields = textscan(tline(12:end), '%f Ci N/A %f/%f/%f'); 
        machine.calibration.activity...
            {length(machine.calibration.activity)+1} = fields{1};
        machine.calibration.activitydate...
            {length(machine.calibration.activitydate)+1} = ...
            datenum(fields{4}, fields{3}, fields{2});
        
    % Store calibrated strength
    elseif length(tline) > 26 && strcmp(tline(1:26), ...
            'Last Reference Measurement')
        fields = textscan(tline(27:end), '%f Gy/min %f/%f/%f'); 
        machine.calibration.strength...
            {length(machine.calibration.strength)+1}= fields{1};
        machine.calibration.strengthdate...
            {length(machine.calibration.strengthdate)+1}= ...
            datenum(fields{4}, fields{3}, fields{2});
    end  
end

% Loop through fourth page
for i = 1:length(content{4})
    
    % Store line, remove duplicate spaces
    tline = strtrim(regexprep(content{4}{i}, '[ ]+', ' '));
    
    % Store prescription volume
    if length(tline) > 22 && strcmp(tline(1:21), 'Primary Prescription:')
        fields = strsplit(tline(22:end), {'(' ')'});
        patient.rxvolume = strtrim(fields{1});
    
    % Store diagnosis
    elseif ~isempty(strfind(tline, 'Diagnosis:'))
        patient.diagnosis = ...
            strtrim(tline(strfind(tline, 'Diagnosis:')+10:end));
        
    % Store prescription
    elseif ~isempty(tline) 
        
        % Search for volume prescription format
        fields = textscan(tline, '%f/%f/%f %f to %f%% %f %f %f');
        
        % Store fields
        if ~isempty(fields{8})
            patient.rxdose = fields{4};
            patient.rxpercent = fields{5};
            patient.fractions = fields{6};
            patient.doseperfx = fields{7};
            patient.prevdose = fields{8};
        end
        
        % Search for point prescription format
        fields = textscan(tline, '%f/%f/%f %f %f %f %f');
        
        % Store fields
        if ~isempty(fields{7})
            patient.rxdose = fields{4};
            patient.fractions = fields{5};
            patient.doseperfx = fields{6};
            patient.prevdose = fields{7};
        end
    end
end

% Loop through eighth page
for i = 1:length(content{8})
    
    % Store line, remove duplicate spaces
    tline = strtrim(regexprep(content{8}{i}, '[ ]+', ' '));
    
    % Store lateral coordinate
    if length(tline) > 8 && strcmp(tline(1:8), 'Lateral:')
        lateral = str2double(tline(9:end));
    
    % Store vertical coordinate
    elseif length(tline) > 9 && strcmp(tline(1:9), 'Vertical:')
        points{idx}.couch(3) = str2double(tline(10:end));
        
        % Store first isocenter point under patient couch field
        if ~isfield(patient, 'couch') || isempty(patient.couch)
            patient.couch = points{idx}.couch;
        end
        
    % Store point
    else
        
        % Match point fields
        [tokens,~] = regexp(tline, ['^(.+) (Yes|No) ([0-9\.-]+), ', ...
            '([0-9\.-]+), ([0-9\.-]+) ([\,0-9\. -]+|N\/A) ', ...
            '([0-9\.-]+)? (Yes|No) ([0-9]+) (Longitudinal\:|N\/A) ([0-9\.-]+)?'], ...
            'tokens', 'match');
        
        % If match was found
        if ~isempty(tokens)
            idx = length(points)+1;
            points{idx}.name = strtrim(tokens{1}{1});
            points{idx}.coordinates(1) = str2double(tokens{1}{3});
            points{idx}.coordinates(2) = str2double(tokens{1}{4});
            points{idx}.coordinates(3) = str2double(tokens{1}{5});
            points{idx}.dose = str2double(tokens{1}{7});
            points{idx}.beams = str2double(tokens{1}{9});
            if length(tokens{1}) > 10
                points{idx}.couch(1) = lateral;
                points{idx}.couch(2) = str2double(tokens{1}{11});
            end
        end
    end
end

% Initialize density settings
patient.densityct = '';

% Loop through ninth page
for i = 1:length(content{9})
    
    % Store line, remove duplicate spaces
    tline = strtrim(regexprep(content{9}{i}, '[ ]+', ' '));
    
    % Store density CT
    if length(tline) > 5 && strcmp(tline(1:5), 'Using')
        
        % Search for UID
        idx = strfind(tline, 'UID:');
        if idx > 0
            fields = strsplit(tline, {':', '(', ')'});
            patient.densityct = strtrim(fields{3});
        end
    
    % Store density overrides
    else
        
        % Match point fields
        [tokens,~] = regexp(tline, ['^([a-zA-Z0-9_\+]+) ([a-zA-Z]+) ', ...
            '([0-9\.]+) ([0-9]{1,2})'], 'tokens', 'match');
        
        % If match was found
        if ~isempty(tokens)
            idx = str2double(tokens{1}{4});
            patient.densityoverrides{idx}.name = strtrim(tokens{1}{1});
            patient.densityoverrides{idx}.template = strtrim(tokens{1}{2});
            patient.densityoverrides{idx}.density = str2double(tokens{1}{3});
        end
    end
end

% Loop through remaining pages
for i = 10:length(content)
    
    % Store 11th line, remove duplicate spaces
    tline = strtrim(regexprep(content{i}{11}, '[ ]+', ' '));
     
    % If beam details exist
    if length(tline) > 29 && strcmp(tline(1:29), ...
            'Details for Beam Angle Group:')

        % Store group
        group = cell2mat(textscan(tline(30:end), 'Group %f'));
        
        % Store current beam number
        idx = length(beams);
        
        % Loop through remaining page content
        for j = 12:length(content{i})
            
            % Store line, remove duplicate spaces
            tline = strtrim(regexprep(content{i}{j}, '[ ]+', ' '));
            
            % Store beam angles
            if length(tline) > 20 && strcmp(tline(1:20), ...
                    'Planning Beam Number')
                fields = textscan(tline(21:end), ...
                    '%f (%f°) %f (%f°) %f (%f°)');
                beams{idx+1}.angle = fields{2};
                beams{idx+2}.angle = fields{4};
                beams{idx+3}.angle = fields{6};
                beams{idx+1}.group = group;
                beams{idx+2}.group = group;
                beams{idx+3}.group = group;
            
                % Initialize SSDs, depths, and OADs
                beams{idx+1}.ssd = [];
                beams{idx+1}.depth = [];
                beams{idx+1}.edepth = [];
                beams{idx+1}.oad = [];
                beams{idx+2}.ssd = [];
                beams{idx+2}.depth = [];
                beams{idx+2}.edepth = [];
                beams{idx+2}.oad = [];
                beams{idx+3}.ssd = [];
                beams{idx+3}.depth = [];
                beams{idx+3}.edepth = [];
                beams{idx+3}.oad = [];
                
            % Store beam types
            elseif length(tline) > 9 && strcmp(tline(1:9), 'Beam Type')
                [tokens,~] = regexp(tline(10:end), ...
                    ['(Fixed Conformal|Optimized Conformal|IMRT) (\([^\)]+\) )?', ...
                    '(Fixed Conformal|Optimized Conformal|IMRT) (\([^\)]+\) )?', ...
                    '(Fixed Conformal|Optimized Conformal|IMRT)( \([^\)]+\))?'], ...
                    'tokens', 'match');
                if length(tokens{1}) == 6
                    beams{idx+1}.type = tokens{1}{1};
                    if ~isempty(tokens{1}{2})
                        beams{idx+1}.segments = ...
                            cell2mat(textscan(tokens{1}{2}, '(%f segments)'));
                    end
                    beams{idx+2}.type = tokens{1}{3};
                    if ~isempty(tokens{1}{4})
                        beams{idx+1}.segments = ...
                            cell2mat(textscan(tokens{1}{4}, '(%f segments)'));
                    end
                    beams{idx+3}.type = tokens{1}{5};
                    if ~isempty(tokens{1}{6})
                        beams{idx+1}.segments = ...
                            cell2mat(textscan(tokens{1}{6}, '(%f segments)'));
                    end
                end
            
            % Store beam on times
            elseif length(tline) > 21 && strcmp(tline(1:21), ...
                    'Fraction Beam-On Time')
                fields = textscan(tline(22:end), ...
                    '%f sec %f sec %f sec');
                beams{idx+1}.plantime = fields{1};
                beams{idx+2}.plantime = fields{2};
                beams{idx+3}.plantime = fields{3};
            
            % Store isocenters
            elseif length(tline) > 9 && strcmp(tline(1:9), 'Isocenter')
                [tokens,~] = regexp(tline(10:end), ['''([^'']+)''[^'']+''', ...
                    '([^'']+)''[^'']+''([^'']+)''[^'']+'], 'tokens', ...
                    'match');
                beams{idx+1}.iso = tokens{1}{1};
                beams{idx+2}.iso = tokens{1}{2};
                beams{idx+3}.iso = tokens{1}{3};
            
            % Store equivalent square field
            elseif length(tline) > 18 && strcmp(tline(1:18), ...
                    'Open Field Eq. Sq.')
                fields = textscan(tline(19:end), ...
                    '%f cm %f cm %f cm');
                if ~isempty(fields)
                    beams{idx+1}.equivsquare = fields{1};
                    beams{idx+2}.equivsquare = fields{2};
                    beams{idx+3}.equivsquare = fields{3};
                else
                    beams{idx+1}.equivsquare = 0;
                    beams{idx+2}.equivsquare = 0;
                    beams{idx+3}.equivsquare = 0;
                end
                
            % Store weight points
            elseif length(tline) > 23 && strcmp(tline(1:23), ...
                    'Fixed Conf Weight Point')
                [tokens,~] = regexp(tline(24:end), ['''([^'']+)''[^'']+''', ...
                    '([^'']+)''[^'']+''([^'']+)''[^'']+'], 'tokens', ...
                    'match');
                if ~isempty(tokens)
                    beams{idx+1}.weightpt = tokens{1}{1};
                    beams{idx+2}.weightpt = tokens{1}{2};
                    beams{idx+3}.weightpt = tokens{1}{3};
                end
            
            % Store weight percentages
            elseif length(tline) > 10 && strcmp(tline(1:10), 'Beam Dose:')
                fields = strsplit(tline, 'Beam Dose:');
                for k = 2:length(fields)
                    tokens = textscan(fields{k}, '%f Gy / %f%%');
                    if ~isempty(tokens)
                        beams{idx+k-1}.weight = tokens{2};
                    end
                end
                
            % Store SSDs
            elseif length(tline) > 20 && strcmp(tline(1:20), ...
                    'Source to Skin (SSD)')
                
                % Loop remaining lines until Depths is found
                for k = j:length(content{i})
                    
                    % Store line, remove duplicate spaces
                    tline = strtrim(regexprep(content{i}{k}, '[ ]+', ' '));
            
                    if length(tline) > 6 && strcmp(tline(1:6), 'Depths')
                        break;
                    end
                    
                    [tokens,~] = regexp(tline, '([0-9\.]+) cm', ...
                        'tokens', 'match');
                    if length(tokens) == 3
                        beams{idx+1}.ssd(length(beams{idx+1}.ssd)+1) = ...
                            str2double(tokens{1});
                        beams{idx+2}.ssd(length(beams{idx+2}.ssd)+1) = ...
                            str2double(tokens{2});
                        beams{idx+3}.ssd(length(beams{idx+3}.ssd)+1) = ...
                            str2double(tokens{3});
                    end
                end
            
            % Store depths
            elseif length(tline) > 6 && strcmp(tline(1:6), ...
                    'Depths')
                
                % Loop remaining lines until OAD is found
                for k = j:length(content{i})
                    
                    % Store line, remove duplicate spaces
                    tline = strtrim(regexprep(content{i}{k}, '[ ]+', ' '));
            
                    if length(tline) > 24 && strcmp(tline(1:24), ...
                            'Off-Axis Distances (OAD)')
                        break;
                    end
                    
                    [tokens,~] = regexp(tline, 'Physical: ([0-9\.]+) cm', ...
                        'tokens', 'match');
                    if length(tokens) == 3
                        beams{idx+1}.depth(length(beams{idx+1}.depth)+1) = ...
                            str2double(tokens{1});
                        beams{idx+2}.depth(length(beams{idx+2}.depth)+1) = ...
                            str2double(tokens{2});
                        beams{idx+3}.depth(length(beams{idx+3}.depth)+1) = ...
                            str2double(tokens{3});
                    end
                    
                    [tokens,~] = regexp(tline, 'Effective: ([0-9\.]+) cm', ...
                        'tokens', 'match');
                    if length(tokens) == 3
                        beams{idx+1}.edepth(length(beams{idx+1}.edepth)+1) = ...
                            str2double(tokens{1});
                        beams{idx+2}.edepth(length(beams{idx+2}.edepth)+1) = ...
                            str2double(tokens{2});
                        beams{idx+3}.edepth(length(beams{idx+3}.edepth)+1) = ...
                            str2double(tokens{3});
                    end
                end
            
            % Store OADs
            elseif length(tline) > 24 && strcmp(tline(1:24), ...
                    'Off-Axis Distances (OAD)')
                
                % Loop remaining lines until Fluence Map is found
                for k = j:length(content{i})
                    
                    % Store line, remove duplicate spaces
                    tline = strtrim(regexprep(content{i}{k}, '[ ]+', ' '));

                    if length(tline) > 11 && strcmp(tline(1:11), ...
                            'Fluence Map')
                        break;
                    end
                    
                    [tokens,~] = regexp(tline, '([0-9\.]+) cm', ...
                        'tokens', 'match');
                    if length(tokens) == 3
                        beams{idx+1}.oad(length(beams{idx+1}.oad)+1) = ...
                            str2double(tokens{1});
                        beams{idx+2}.oad(length(beams{idx+2}.oad)+1) = ...
                            str2double(tokens{2});
                        beams{idx+3}.oad(length(beams{idx+3}.oad)+1) = ...
                            str2double(tokens{3});
                    end
                end
            end
        end
    end
end

% Remove empty beams
for i = 1:length(beams)
    
    % If the planned beam time is empty, clear structure from cell
    if beams{i}.plantime == 0
        beams{i} = [];
    end
end

% Remove empty cells
beams = beams(~cellfun('isempty',beams)); 

% Log completion and image size
if ~isempty(beams)
    if exist('Event', 'file') == 2
        Event(sprintf('%i beams successfully parsed in %0.3f seconds', ...
            length(beams), toc));
    end
end

% Clear temporary variables
clear content fields file group i idx j k lateral tline tokens;