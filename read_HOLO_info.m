function LHinfo=read_HOLO_info(filename)

% Function: read_HOLO_info
%
% Description: Function to read the non-image information from a LISST_HOLO
% image. Pressure and temperature raw values are converted using the 
% calibration coefficients embedded in the image. Basic error checking of
% the derived values is performed within the limits specified.
%
% Usage: LHinfo=read_HOLO_info(filename)
%   where "filename" is a string containing the filename of the image
%   and LHinfo is a structure containing the main information
% 
% Revisions:
% v1 Alex Nimmo Smith (alex.nimmo.smith@plymouth.ac.uk) 18/05/2011
%
%
% License:
% Copyright (c) 2011 Alex Nimmo Smith
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.



%%%%%% 

    minTemp=-4;
    maxTemp=100;
    minDepth=-1;
    maxDepth=500;
    minDate='01-Jan-2010';
    maxDate='01-Jan-2025';
    auxdatalength=1024;

%%%%%%
    
    LHinfo.Filename=filename;
    fid=fopen(filename);
    tmp=fgetl(fid);
    if(tmp(1:2)~='P5')
        disp('Error: Input not an image file')
        LHinfo=NaN;
        return
    end
    tmp=sscanf(fgetl(fid),'%d %d %d');
    if(isempty(tmp))
        disp('Error: Image not from LISST-HOLO')
        LHinfo=NaN;
        return
    end
    LHinfo.ImageWidth=tmp(1);
    LHinfo.ImageHeight=tmp(2);
    if(fseek(fid,LHinfo.ImageWidth*LHinfo.ImageHeight,'cof')~=0)
        disp('Error: Image corrupt')
        LHinfo=NaN;
        return
    end
    if(fseek(fid,auxdatalength,'cof')~=0)
        disp('Error: Image not from LISST-HOLO')
        LHinfo=NaN;
        return
    end
    fseek(fid,-auxdatalength,'cof');
    LHinfo.Timestamp=fread(fid,1,'uint64');
    LHinfo.Datenum=(LHinfo.Timestamp/(24*60*60))+datenum('01-Jan-1970');
    if(LHinfo.Datenum>datenum(minDate) && LHinfo.Datenum<datenum(maxDate))  
        LHinfo.DateString = datestr(LHinfo.Datenum);
    else
        LHinfo.DateString = NaN;
        LHinfo.Datenum = NaN;
    end
    LHinfo.PressureCounts=fread(fid,1,'uint64');
    LHinfo.TemperatureCounts=fread(fid,1,'uint16');
    LHinfo.BatteryCounts=fread(fid,1,'uint16');
    LHinfo.ExposureMicroSecond=0.6*fread(fid,1,'uint16');
    LHinfo.LaserPowerCounts=fread(fid,1,'uint16');
    LHinfo.LaserDiodeCounts=fread(fid,1,'uint16');
    LHinfo.CameraBrightness=fread(fid,1,'uint16');
    fseek(fid,4,'cof');
    LHinfo.CameraShutter=fread(fid,1,'uint16');
    fseek(fid,4,'cof');
    LHinfo.CameraGain=fread(fid,1,'uint16');

    if(fseek(fid,76,'cof')~=0)
        disp('Error: Image corrupt')
        return
    end
    DepthA=fread(fid,1,'single');
    DepthB=fread(fid,1,'single');
    DepthC=fread(fid,1,'single');
    LHinfo.DepthMeters=(DepthA*LHinfo.PressureCounts^2) + (DepthB*LHinfo.PressureCounts) + DepthC;
    if(LHinfo.DepthMeters<minDepth || LHinfo.DepthMeters>maxDepth)
        LHinfo.DepthMeters=NaN;
    end

    TemperatureA=fread(fid,1,'single');
    TemperatureB=fread(fid,1,'single');
    TemperatureC=fread(fid,1,'single');
    TemperatureSlope=fread(fid,1,'single');
    TemperatureOffset=fread(fid,1,'single');
    TemperatureVoltsPerCount=0.001;

    % Convert A/D counts to volts.
    V=LHinfo.TemperatureCounts * TemperatureVoltsPerCount;
    % Calculate resistance of thermistor
    Rt= (10000.0*V)/(4.096-V);
    % Convert to natural log of resistance.
    if( Rt==0) 
        LHinfo.TemperatureCelsius=NaN;
    else        
        LRt=log( Rt);
        % Calculate temperature in Celsius.
        Temperature=  ( 1/(TemperatureA + TemperatureB*LRt + TemperatureC*(LRt*LRt*LRt))) - 273.15;   
        % Apply slope and offset.
        LHinfo.TemperatureCelsius= Temperature * TemperatureSlope+ TemperatureOffset;
        if(LHinfo.TemperatureCelsius<minTemp || LHinfo.TemperatureCelsius>maxTemp)
           LHinfo.TemperatureCelsius=NaN;
        end
    end
    LHinfo.BatteryVolts=LHinfo.BatteryCounts * TemperatureVoltsPerCount * 5.545;


    fclose(fid);
end