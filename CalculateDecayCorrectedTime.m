function decay = CalculateDecayCorrectedTime(varargin)
% CalculateDecayCorrectedTime corrects a planning strength beam on time
% for source decay given source strength calibration, planning strength,
% and Co-60 half life. The default planning strength and Co-60 half life
% for the ViewRay system is included.
%
% If the Event() function exists in the defined path, upon completion of
% this function it will be called with a string containing a summary of the
% calculation.
%
% The following key and value pairs can be passed to this function:
%   time: planning strength time to be decay-corrected
%   cal: calibrated source strength, in Gy/min
%   date: date/time of source strength calibration, as a serial date number
%       or string in mm/dd/yyyy format
%   planning (optional): source strength assumed during planning, in Gy/min
%   halflife (optional): radioactive source half life, in days
%
% The following values are returned upon successful completion:
%   time: decay corrected time
%
% Below is an example of how this function is used:
%
%   % Define inputs to CalculateDecayCorrectedTime()
%   t = 100; % seconds
%   c = 1.54; % Gy/min on 07/01/2014
%   d = datenum('07/01/2014', 'mm/dd/yyyy');
%
%   % Calculate decay corrected time
%   decay = CalculateDecayCorrectedTime('time', t, 'cal', c, 'date', d);
%
%   % Print decay corrected time to stdout
%   sprintf('Decay Corrected Time = %0.1f sec', decay);
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

% Declare Co-60 half life, in days
halflife = 1925.2;

% Declare ViewRay default planning strength
planning = 1.85; % Gy/min

% Load data structure from varargin
for i = 1:2:nargin
    
    % Load time
    if strcmp(varargin{i}, 'time')
        time = varargin{i+1};  
    
    % Load calibration strength
    elseif strcmp(varargin{i}, 'cal')
        cal = varargin{i+1};  
     
    % Load calibration date
    elseif strcmp(varargin{i}, 'date')
        if ischar(varargin{i+1})
            date = datenum(varargin{i+1}, 'mm/dd/yyyy');
        else
            date = varargin{i+1};  
        end
        
    % Load planning strength
    elseif strcmp(varargin{i}, 'planning')
        planning = varargin{i+1};  
    
    % Load half life
    elseif strcmp(varargin{i}, 'halflife')
        halflife = varargin{i+1};  
    end
end

% Calculate decay corrected time
decay = time * planning/cal * 1 / exp(-log(2)/halflife * (now() - date));

% Log result
if exist('Event', 'file') == 2
    Event(sprintf('Beam on time decay-corrected to %0.3f sec\n', decay));
end

% Clear temporary variables
clear time planning cal halflife date;
