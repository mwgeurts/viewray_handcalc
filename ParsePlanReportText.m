function [patient, machine, points, beams] = ParsePlanReportText(varargin)



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
            'ParsePlanReportText'], 'ERROR');
    else
        error(['At least one argument must be passed to ', ...
            'ParsePlanReportText']);
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
tline = fgetl(fid);

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
    
    % Parse line
    tline = strtrim(regexprep(tline, '[ ]+', ' '));
    
    % Store patient ID
    if length(tline) > 11 && strcmp(tline(1:11), 'Patient ID:')
        patient.id = strtrim(tline(12:end));
        
    % Store patient name
    elseif length(tline) > 13 && strcmp(tline(1:13), 'Patient Name:')
        patient.name = strtrim(tline(14:end));
        
    % Store patient birthdate
    elseif length(tline) > 18 && strcmp(tline(1:18), 'Patient Birthdate:')
        patient.birthdate = datenum(tline(19:end));
        
    % Store diagnosis
    elseif length(tline) > 10 && strcmp(tline(1:10), 'Diagnosis:')
        patient.diagnosis = strtrim(tline(11:end));
        
    % Store prescription name
    elseif length(tline) > 13 && strcmp(tline(1:13), 'Prescription:')
        patient.prescription = strtrim(tline(14:end));
        
    % Store plan name
    elseif length(tline) > 10 && strcmp(tline(1:10), 'Plan Name:')
        patient.plan = strtrim(tline(11:end));
        
    % Store plan approval
    elseif length(tline) > 17 && strcmp(tline(1:17), 'Plan Approved By:')
        patient.planapproval = strtrim(tline(18:end));
        
    % Store plan ID
    elseif length(tline) > 8 && strcmp(tline(1:8), 'Plan ID:')
        patient.planid = strtrim(tline(9:end));
    
    % Store patient birthdate
    elseif length(tline) > 19 && strcmp(tline(1:19), 'Plan Last Modified:')
        patient.lastmodified = datenum(tline(20:end));
        
    % Store physician
    elseif length(tline) > 10 && strcmp(tline(1:10), 'Physician:')
        patient.physician = strtrim(tline(11:end));
        
    % Store physicist
    elseif length(tline) > 10 && strcmp(tline(1:10), 'Physicist:')
        patient.physicist = strtrim(tline(11:end));
        
    % Store dosimetrist
    elseif length(tline) > 12 && strcmp(tline(1:12), 'Dosimetrist:')
        patient.dosimetrist = strtrim(tline(13:end));
        
    % Store machine name
    elseif length(tline) > 13 && strcmp(tline(1:13), 'Machine Name:')
        machine.name = strtrim(tline(14:end));
        
    % Store machine serial number
    elseif length(tline) > 14 && strcmp(tline(1:14), 'Serial Number:')
        fields = strsplit(tline(15:end), '-');     
        machine.serial = strtrim(fields{1});
        
    % Store software version
    elseif length(tline) > 17 && strcmp(tline(1:17), 'Software Version:')
        fields = strsplit(tline(18:end), '-');
        if length(fields) > 1
            machine.version = strtrim(fields{2});
        else
            machine.version = strtrim(fields{1});
        end
    
    % Store dose model
    elseif length(tline) > 16 && strcmp(tline(1:16), 'Equipment Model:')
        machine.model = strtrim(tline(17:end));
        
    % Store institution
    elseif length(tline) > 12 && strcmp(tline(1:12), 'Institution:')
        machine.institution = strtrim(tline(13:end));
        
    % Store department
    elseif length(tline) > 11 && strcmp(tline(1:11), 'Department:')
        machine.department = strtrim(tline(12:end));
        
    % Store beam on time specification
    elseif length(tline) > 25 && strcmp(tline(1:25), ...
            'Beam-On Time Reported As:')
        machine.timespec = strtrim(tline(26:end));
        
    % Store prescription
    elseif length(tline) > 23 && strcmp(tline(1:23), ...
            'Total Prescription Dose')
        [tokens,~] = regexp(tline, ['''([^'']+)'': ([0-9\.]+) Gy', ...
            '( to )?([0-9\.]+)?'], 'tokens', 'match');
        if ~isempty(tokens)
            patient.rxvolume = strtrim(tokens{1}{1});
            patient.rxdose = str2double(tokens{1}{2});
            if length(tokens{1}) == 4
                patient.rxpercent = str2double(tokens{1}{4});
            end
        end
        
    % Store number of fractions
    elseif length(tline) > 30 && strcmp(tline(1:30), ...
            'Prescription Dose Per Fraction')
        [tokens,~] = regexp(tline, '([0-9\.]+) Gy', 'tokens', 'match');
        if ~isempty(tokens)
            patient.fractions = str2double(tokens{1}{1}) / patient.rxdose;
        end
    
     % Store patient position acronym
    elseif length(tline) > 20 && strcmp(tline(1:20), ...
            'Patient Orientation:')
        patient.position = regexprep(tline(21:end), '[^A-Z]', ''); 
        
    % Store couch position
    elseif length(tline) > 28 && strcmp(tline(1:28), ...
            'Couch Position (cm) (x,y,z):')
        patient.couch = cell2mat(textscan(tline(29:end), '%f, %f, %f')); 
    
    % Store points
    elseif length(tline) >= 19 && strcmp(tline(1:19), 'RealTarget Settings')
        
        % Loop through remaining lines
        while ischar(tline)
            
            % Parse line
            tline = strtrim(regexprep(tline, '[ ]+', ' '));
    
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
            tline = fgetl(fid);
        end
    
    % Search for electron density
    elseif length(tline) >= 25 && strcmp(tline(1:25), ...
            'Electron Density Settings')
        
        patient.densityct = '';
        patient.densityoverrides = cell(0);
        
        % Loop through remaining lines
        while ischar(tline)
            
            % Parse line
            tline = strtrim(regexprep(tline, '[ ]+', ' '));
    
            % Look for next section
             if length(tline) >= 26 && strcmp(tline(1:26), 'Planning Beam Angle Group:')
                fseek(fid, -length(tline)-2, 0);
                break;
            
            % Store density CT
            elseif length(tline) > 18 && strcmp(tline(1:18), ...
                    'CT Base Image UID:')
                patient.densityct = tline(21:end);
            
            % Store density overrides
            elseif length(tline) >= 28 && strcmp(tline(1:28), ...
                    'Structure Density Overrides:')
                
                % Loop through structures
                tline = fgetl(fid);
                
                while ischar(tline) && ~isempty(tline)
                    fields = strsplit(tline, {':' '(' ')'});
                    
                    % Retrieve priority
                    i = cell2mat(textscan(fields{3}, 'Priority %f'));
                    
                    % Store name and density
                    patient.densityoverrides{i}.name = strtrim(fields{1});
                    patient.densityoverrides{i}.density = ...
                        str2double(fields{2});
                    
                    % Get next line
                    tline = fgetl(fid);
                end
            end
            
            % Get next line
            tline = fgetl(fid);
        end
        
    % Search for beam angle group
    elseif length(tline) > 26 && strcmp(tline(1:26), ...
            'Planning Beam Angle Group:')
        group = cell2mat(textscan(tline(27:end), 'Group %f'));
        i = 0;
        
        % Get next line
        tline = fgetl(fid);
            
        % Loop through remaining lines
        while ischar(tline)
            
            % Parse line
            tline = strtrim(regexprep(tline, '[ ]+', ' '));
    
            % Look for next section
            if length(tline) >= 26 && strcmp(tline(1:26), ...
                    'Planning Beam Angle Group:')
                fseek(fid, -40, 0);
                break;
                
            % Store group isocenter point
            elseif length(tline) > 10 && strcmp(tline(1:10), 'Isocenter:')
                iso = regexprep(strtrim(tline(13:end)), '[^\w ]', '');
                
            % Store new field
            elseif length(tline) > 6 && strcmp(tline(1:6), 'Angle:')
                
                % Determine index of new field
                i = length(beams) + 1;
                
                % Store angle, group, and iso
                beams{i}.angle = str2double(tline(7:end-1));
                beams{i}.group = group;
                beams{i}.iso = iso;
                
                % Initialize SSDs, depths, and OADs
                beams{i}.ssd = [];
                beams{i}.depth = [];
                beams{i}.edepth = [];
                beams{i}.oad = [];
            
            % Store beam on time
            elseif length(tline) > 22 && strcmp(tline(1:22), ...
                    'Fraction Beam-On Time:')
                beams{i}.plantime = cell2mat(textscan(tline(23:end), ...
                    '%f sec'));
            
            % Store beam type
            elseif length(tline) > 10 && strcmp(tline(1:10), ...
                    'Beam Type:')
                beams{i}.type = strtrim(tline(11:end));   
                
            % Store equivalent square field
            elseif length(tline) > 24 && strcmp(tline(1:24), ...
                    'Open Field Eq. Sq. (cm):')
                try
                    beams{i}.equivsquare = str2double(tline(25:end));
                catch
                    beams{i}.equivsquare = 0;
                end
            
            % Store weight point
            elseif length(tline) > 13 && strcmp(tline(1:13), ...
                    'Weight Point:')
                beams{i}.weightpt = regexprep(strtrim(tline(14:end)), ...
                    '[^\w ]', ''); 
                
            % Store weight percentage
            elseif length(tline) > 24 && strcmp(tline(1:24), ...
                    'Beam Dose Normalization:')
                beams{i}.weight = cell2mat(textscan(tline(25:end), '%f%%'));
                
            % Store SSDs
            elseif length(tline) > 9 && strcmp(tline(1:9), ...
                    'SSD (cm):')
                beams{i}.ssd(length(beams{i}.ssd)+1) = ...
                    str2double(tline(10:end));
                
            % Store physical depth
            elseif length(tline) > 16 && strcmp(tline(1:16), ...
                    '- Physical (cm):')
                beams{i}.depth(length(beams{i}.depth)+1) = ...
                    str2double(tline(17:end));
            
            % Store effective depth
            elseif length(tline) > 17 && strcmp(tline(1:17), ...
                    '- Effective (cm):')
                beams{i}.edepth(length(beams{i}.edepth)+1) = ...
                    str2double(tline(18:end));
                
            % Store OAD
            elseif length(tline) > 9 && strcmp(tline(1:9), ...
                    'OAD (cm):')
                beams{i}.oad(length(beams{i}.oad)+1) = ...
                    str2double(tline(10:end));
            end
            
            % Get next line
            tline = fgetl(fid);
        end
    end

    % Get next line
    tline = fgetl(fid);
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
