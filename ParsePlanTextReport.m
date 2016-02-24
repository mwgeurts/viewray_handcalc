function [patient, machine, points, beams] = ParsePlanTextReport(varargin)



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
            'ParsePlanTextReport'], 'ERROR');
    else
        error(['At least one argument must be passed to ', ...
            'ParsePlanTextReport']);
    end
end

% Log start of file load and start timer
if exist('Event', 'file') == 2
    Event(sprintf('Reading file %s', file));
    tic;
end

% Open file handle
fid = fopen(file, 'r', 'n', 'UTF-8');

% Validate handle
if fid < 0
    if exist('Event', 'file') == 2
        Event(sprintf('A file handle could not be opened to %s', file), ...
            'ERROR');
    else
        error('A file handle could not be opened to %s', file);
    end
end

% Get the first line
tline = strtrim(regexprep(fgetl(fid), '[ ]+', ' '));

% Validate first line
if ~strcmp(tline, 'ViewRay Plan Information')
    if exist('Event', 'file') == 2
        Event('The file does not appear to be in the correct format', 'WARN');
    else
        warning('The file does not appear to be in the correct format');
    end
end

% Loop through remaining lines
while ischar(tline)
    
    % Store patient ID
    if length(tline) > 11 && strcmp(tline(1:11), 'Patient ID:')
        patient.id = strtrim(tline(12:end));
        
    % Store patient name
    elseif length(tline) > 13 && strcmp(tline(1:13), 'Patient Name:')
        patient.name = strtrim(tline(14:end));
    
    % Store machine name
    elseif length(tline) > 13 && strcmp(tline(1:13), 'Machine Name:')
        machine.name = strtrim(tline(14:end));
        
    % Store machine serial number
    elseif length(tline) > 14 && strcmp(tline(1:14), 'Serial Number:')
        machine.serial = strtrim(tline(15:end));
    
    % Store points
    elseif length(tline) >= 19 && strcmp(tline(1:19), 'RealTarget Settings')
        
        % Loop through remaining lines
        while ischar(tline)
            
            % Look for next section
            if length(tline) >= 24 && ...
                    strcmp(tline(1:24), 'Optimization Constraints')
                break;
            
            % Store isocenters
            elseif length(tline) > 10 && strcmp(tline(1:10), ...
                    'Isocenter:')
                fields = strsplit(tline, ':');
                subfields = strsplit(fields{2}, ',');
                i = length(points) + 1;
                points{i}.name = strtrim(subfields{1});
                points{i}.coordinates = ...
                    cell2mat(textscan(fields{3}, '(%f, %f, %f)'));
            end
            
            % Get next line
            tline = strtrim(regexprep(fgetl(fid), '[ ]+', ' '));
        end
    
    % Search for electron density
    elseif length(tline) >= 25 && strcmp(tline(1:25), ...
            'Electron Density Settings')
        
        patient.densityCT = '';
        patient.densityOverrides = cell(0);
        
        % Loop through remaining lines
        while ischar(tline)
            
            % Look for next section
             if length(tline) >= 26 && strcmp(tline(1:26), 'Planning Beam Angle Group:')
                fseek(fid, -length(tline)-2, 0);
                break;
            
            % Store density CT
            elseif length(tline) > 18 && strcmp(tline(1:18), ...
                    'CT Base Image UID:')
                patient.densityCT = tline(21:end);
            
            % Store density overrides
            elseif length(tline) >= 28 && strcmp(tline(1:28), ...
                    'Structure Density Overrides:')
                
                % Loop through structures
                tline = strtrim(regexprep(fgetl(fid), '[ ]+', ' '));
                while ischar(tline) && ~isempty(tline)
                    fields = strsplit(tline, {':' '(' ')'});
                    
                    % Retrieve priority
                    i = cell2mat(textscan(fields{3}, 'Priority %f'));
                    
                    % Store name and density
                    patient.densityOverrides{i}.name = strtrim(fields{1});
                    patient.densityOverrides{i}.density = ...
                        str2double(fields{2});
                    
                    % Get next line
                    tline = strtrim(regexprep(fgetl(fid), '[ ]+', ' '));
                end
            end
            
            % Get next line
            tline = strtrim(regexprep(fgetl(fid), '[ ]+', ' '));
        end
        
    % Search for beam angle group
    elseif length(tline) > 26 && strcmp(tline(1:26), ...
            'Planning Beam Angle Group:')
        group = cell2mat(textscan(tline(27:end), 'Group %f'));
        i = 0;
        
        % Get next line
        tline = strtrim(regexprep(fgetl(fid), '[ ]+', ' '));
            
        % Loop through remaining lines
        while ischar(tline)
            
            % Look for next section
            if length(tline) >= 26 && strcmp(tline(1:26), ...
                    'Planning Beam Angle Group:')
                fseek(fid, -length(tline)-2, 0);
                break;
                
            % Store group isocenter point
            elseif length(tline) > 10 && strcmp(tline(1:10), 'Isocenter:')
                iso = regexprep(strtrim(tline(13:end)), '[^\w ]', '');
                
            % Store new field
            elseif length(tline) > 6 && strcmp(tline(1:6), 'Angle:')
                
                % Determine index of new field
                i = length(beams) + 1;
                
                % Store angle, group, and iso
                beams{i}.angle = str2double(tline(11:end-1));
                beams{i}.group = group;
                beams{i}.iso = iso;
                
                % Initialize SSDs, depths, and OADs
                beams{i}.ssd = [];
                beams{i}.depth = [];
                beams{i}.edepth = [];
                beams{i}.oad = [];
            
            % Store beam on time
            elseif length(tline) > 26 && strcmp(tline(1:26), ...
                    '    Fraction Beam-On Time:')
                beams{i}.plantime = cell2mat(textscan(tline(27:end), ...
                    '%f sec'));
            
            % Store beam type
            elseif length(tline) > 14 && strcmp(tline(1:14), ...
                    '    Beam Type:')
                beams{i}.type = strtrim(tline(15:end));   
                
            % Store equivalent square field
            elseif length(tline) > 28 && strcmp(tline(1:28), ...
                    '    Open Field Eq. Sq. (cm):')
                try
                    beams{i}.equivSquare = str2double(tline(29:end));
                catch
                    beams{i}.equivSquare = 0;
                end
            
            % Store weight point
            elseif length(tline) > 17 && strcmp(tline(1:17), ...
                    '    Weight Point:')
                beams{i}.weightpt = regexprep(strtrim(tline(18:end)), ...
                    '[^\w ]', ''); 
                
            % Store weight percentage
            elseif length(tline) > 30 && strcmp(tline(1:30), ...
                    '      Beam Dose Normalization:')
                beams{i}.weight = cell2mat(textscan(tline(31:end), '%f%%'));
                
            % Store SSDs
            elseif length(tline) > 17 && strcmp(tline(1:17), ...
                    '        SSD (cm):')
                beams{i}.ssd(length(beams{i}.ssd)+1) = ...
                    str2double(tline(18:end));
                
            % Store physical depth
            elseif length(tline) > 24 && strcmp(tline(1:24), ...
                    '        - Physical (cm):')
                beams{i}.depth(length(beams{i}.depth)+1) = ...
                    str2double(tline(25:end));
            
            % Store effective depth
            elseif length(tline) > 25 && strcmp(tline(1:25), ...
                    '        - Effective (cm):')
                beams{i}.edepth(length(beams{i}.edepth)+1) = ...
                    str2double(tline(26:end));
                
            % Store OAD
            elseif length(tline) > 17 && strcmp(tline(1:17), ...
                    '        OAD (cm):')
                beams{i}.oad(length(beams{i}.oad)+1) = ...
                    str2double(tline(18:end));
            end
            
            % Get next line
            tline = strtrim(regexprep(fgetl(fid), '[ ]+', ' '));
        end
    end

    % Get next line
    tline = strtrim(regexprep(fgetl(fid), '[ ]+', ' '));
end

% Close file handle
fclose(fid);

% Log completion and image size
if ~isempty(beams)
    if exist('Event', 'file') == 2
        Event(sprintf('%i beams successfully parsed in %0.3f seconds', ...
            length(beams), toc));
    end
end
