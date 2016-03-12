function calc = CalculateBeamTime(varargin)
% CalculateBeamTime calculates the treatment time to deliver a given dose
% using a two-dimensional SAD calculation. Input arguments such as depth,
% field size, off axis distance, and beam angle can be provided. Other
% necessary calculation factors, such as Tissue-Phantom Ratios (TPR) and
% output (Scp) tables are loaded upon execution.
%
% Default values for Source to Axis Distance (SAD), Couch Factor (CF), and 
% reference conditions (Source to Calibration Distance and K) are included
% for the ViewRay treatment system. These values can be adjusted during
% function execution by passing them as input arguments (see below).
%
% A table of Tissue-Phantom Ratios (TPR) and output factors (Scp) are 
% loaded during execution using the csvread() function. TPR factors should
% be formatted such that the first row contains comma separated field sizes
% with the first index empty. Subsequent rows should contain the depth in 
% the first index followed by comma separated TPR factors for each field
% size listed in the first row. Output factors should be formatted such
% that the first row contains comma separated field sizes and the second
% row contains the corresponding comma separated output factors.
%
% If a beam angle is provided and is between 130 and 240 degrees, the Couch
% Factor will be applied during beam on time calculation.
%
% The calculation inputs and results are returned as a structure. The time
% field contains the calculated beam on time in seconds. More information
% on the return structure contents is described below.
%
% If the Event() function exists in the defined path, upon completion of
% this function it will be called with a string containing a summary of the
% calculation inputs and results.
%
% The following key and value pairs can be passed to this function:
%   dose: double containing prescribed dose in Gy
%   depth: double containing the prescribed depth in cm
%   r: double containing the equivalent square field size or 2x1 array of
%       doubles containing the rectangular field size in cm
%   oad (optional): double containing the Off Axis Distance (OAD) in cm
%   angle (optional): double containing the beam angle, in degrees. The 
%       beam angle is used to determine whether the couch factor should be 
%       applied. 
%   k (optional): double containing the calibration factor in Gy/min
%   cf (optional): double containing the couch factor
%   sad (optional): double containing the Source-Axis Distance in cm
%   scd (optional): double containing the Source-Calibration Distance in cm
%
% The following structure fields are returned upon successful completion:
%   calc.sad: double containing the Source-Axis Distance in cm
%   calc.scd: double containing the Source-Calibration Distance in cm
%   calc.k: double containing the calibration factor in Gy/min
%   calc.cf: double containing the Couch Factor
%   calc.tpr_data: 2D array of doubles containing the TPR table
%   calc.scp_data: 2D array of doubles containing the Scp table
%   calc.dose: double containing the prescription dose in Gy
%   calc.r: double containing the equivalent square field size in cm
%   calc.depth: double containing the prescription depth in cm
%   calc.angle: double containing the beam angle in degrees
%   calc.oad: double containing the off axis distance in cm
%   calc.tpr: double containing the calculated TPR
%   calc.scp: double containing the calculated Scp
%   calc.oar: double containing the calcualted Off Axis Ratio
%   calc.time: double containing the calculated beam on time in seconds
%
% Below is an example of how this function is used:
%
%   % Define inputs to CalculateBeamTime()
%   depth = 5; % 5 cm
%   dose = 2; % 2 Gy
%   r = [4 10]; % 4 cm x 10 cm field size
%   
%   % Calculate beam on time
%   calc = CalculateBeamTime('depth', d, 'dose', d, 'r', r);
%
%   % Print beam on time to stdout
%   sprintf('Time = %0.1f sec', calc.time);
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

% Define scalar factors
calc.sad = 105; % cm
calc.scd = 100 + 5; % cm
calc.k = 1.85; % Gy/min
calc.cf = 1/1.21;

% Load tabulated factors
calc.tpr_data = csvread('./calcdata/ViewRay_TPR.csv');
calc.scp_data = csvread('./calcdata/ViewRay_Scp.csv');

% Initialize provided factors
calc.dose = 0;
calc.r = 0;
calc.depth = 0;
calc.angle = 0;
calc.oad = 0;

% Load data structure from varargin
for i = 1:2:nargin
    
    % Load dose
    if strcmp(varargin{i}, 'dose')
        calc.dose = varargin{i+1};  
       
    % Load depth
    elseif strcmp(varargin{i}, 'depth')
        calc.depth = varargin{i+1};  
   
    % Load field size
    elseif strcmp(varargin{i}, 'r')
        
        % If a single value is provided, assume it is the equivalent square
        if length(varargin{i+1}) == 1   
            calc.r = varargin{i+1};
        
        % Otherwise calculate the equivalent square field size
        else
            calc.r = 2 * varargin{i+1}(1) * varargin{i+1}(2) / ...
                (varargin{i+1}(1) + varargin{i+1}(2));
        end
    
    % Load the OAD
    elseif strcmp(varargin{i}, 'oad')
        calc.oad = varargin{i+1}; 
    
    % Load the beam angle
    elseif strcmp(varargin{i}, 'angle')
        calc.angle = varargin{i+1}; 
    
    % Load the calibration factor
    elseif strcmp(varargin{i}, 'k')
        calc.k = varargin{i+1}; 
       
    % Load the couch factor
    elseif strcmp(varargin{i}, 'cf')
        calc.cf = varargin{i+1}; 
            
    % Load the SAD
    elseif strcmp(varargin{i}, 'sad')
        calc.sad = varargin{i+1}; 
        
    % Load the SCD
    elseif strcmp(varargin{i}, 'scd')
        calc.scd = varargin{i+1}; 
    end
end

% If dose, depth, or field size are still zero, throw an exception
if calc.dose <= 0
    if exist('Event', 'file') == 2
        Event('A prescription dose input must be provided', 'ERROR');
    else
        error('A prescription dose input must be provided');
    end
elseif calc.depth <= 0
    if exist('Event', 'file') == 2
        Event('A prescription depth input must be provided', 'ERROR');
    else
        error('A prescription depth input must be provided');
    end
elseif calc.r <= 0
    if exist('Event', 'file') == 2
        Event('A field size must be provided', 'ERROR');
    else
        error('A field size must be provided');
    end
end

% Calculate couch factor
if calc.angle > 240 || calc.angle < 130
    calc.cf = 1;
end

% Calculate an interpolation mesh for the TPR data
[x, y] = meshgrid(calc.tpr_data(2:end,1), calc.tpr_data(1,2:end));

% Interpolate the TPR using linear interpolation
calc.tpr = interp2(x, y, calc.tpr_data(2:end, 2:end)', calc.depth, ...
    calc.r, 'linear', 0);

% Interpolate the Scp using linear interpolation
calc.scp = interp1(calc.scp_data(1,:), calc.scp_data(2,:), calc.r, ...
    'linear', 0);

% If TPR or Scp are  zero, throw an exception
if calc.tpr <= 0
    if exist('Event', 'file') == 2
        Event('TPR could not be computed in the provided table', 'ERROR');
    else
        error('TPR could not be computed in the provided table');
    end
elseif calc.scp <= 0
    if exist('Event', 'file') == 2
        Event('Scp could not be computed in the provided table', 'ERROR');
    else
        error('Scp could not be computed in the provided table');
    end
end

% Calculate the OAR (not currently functional)
calc.oar = 1;

% Compute beam time
calc.time = calc.dose/(calc.k*calc.tpr*calc.scp*calc.oar*calc.cf*...
    (calc.scd/calc.sad)^2)*60;

% Log result
if exist('Event', 'file') == 2
    Event(sprintf(['Beam on time calculation:\nEnergy = Co-60\nK = %g ', ...
        'Gy/sec\nSCD = %g cm\nSAD = %g cm\nDose = %g cGy\nDepth = %g cm\n', ...
        'Field Size (r) = %g cm x %g cm (equiv)\nOAD = %g cm\nTPR = %g\n', ...
        'Scp = %g\nOAR = %g\nCF = %g\nTime = %0.3f sec\n'], calc.k, ...
        calc.scd, calc.sad, calc.dose, calc.depth, calc.r, ...
        calc.r, calc.oad, calc.tpr, calc.scp, calc.oar, calc.cf, ...
        calc.time));
end

