function varargout = TalkHolo(varargin)
% TALKHOLO M-file for TalkHolo.fig
%      TALKHOLO, by itself, creates a new TALKHOLO or raises the existing
%      singleton*.
%
%      H = TALKHOLO returns the handle to a new TALKHOLO or the handle to
%      the existing singleton*.
%
%      TALKHOLO('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TALKHOLO.M with the given input arguments.
%
%      TALKHOLO('Property','Value',...) creates a new TALKHOLO or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TalkHolo_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TalkHolo_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help TalkHolo

% Last Modified by GUIDE v2.5 18-Apr-2013 21:12:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TalkHolo_OpeningFcn, ...
                   'gui_OutputFcn',  @TalkHolo_OutputFcn, ...
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


% --- Executes just before TalkHolo is made visible.
function TalkHolo_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TalkHolo (see VARARGIN)

% Choose default command line output for TalkHolo
handles.output = hObject;

handles.RootPassword='40Smiles';
set(handles.edtRootPassword,'string',handles.RootPassword);
handles.Interval=1;
set(handles.edtInterval,'string',handles.Interval);
handles.DataDirectory=pwd;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes TalkHolo wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = TalkHolo_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pbGo.
function pbGo_Callback(hObject, eventdata, handles)
% hObject    handle to pbGo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.pbGo,'enable','off')
set(handles.pbConfigure,'enable','off')
set(handles.pbReset,'enable','off')
set(handles.pbDataDir,'enable','off')
set(handles.edtInterval,'enable','off')
set(handles.edtRootPassword,'enable','off')
guidata(hObject, handles);

global abort
abort=0;
root_password=handles.RootPassword;
update_status('Connecting to FTP....',hObject,handles)
try
    f=ftp('192.168.0.150','root',root_password);
catch exception
    catch_routine(exception,hObject,handles);
    return
end
update_status('    Connected.',hObject,handles)
cd(f,'tmp/');
update_status(datestr(now),hObject,handles)
update_status('Starting....',hObject,handles)
try
[~]=urlread('http://192.168.0.150/cgi-bin/handler.cgi?SamplingStart=Start+sampling','timeout',20);
end
update_status('    Start sent.',hObject,handles)
output_dir='Data';

% cd(f,'mnt/flash1/ftp/images/')
warning off
update_status(' ',hObject,handles)
while 1
%     clc
    d=dir(f);
    if length(d)>5
        try
            clc
            update_status([num2str(length(d)) ' files on HOLO. Downloading: ' d(5).name],hObject,handles,1)
            mget(f,d(5).name,handles.DataDirectory);
            drawnow
            delete(f,d(5).name);
        end
    else
        clc
        update_status('Waiting for holograms....',hObject,handles,1)
        axes(handles.axView)
        e=dir([handles.DataDirectory '/*.pgm']);
        if length(e)>1
            imagesc(imread([handles.DataDirectory '/' e(end-1).name]));
            colormap gray
            axis image
            LHinfo=[];
            LHinfo=read_HOLO_info([handles.DataDirectory '/' e(end-1).name]);
            title([e(end-1).name '    ' LHinfo.DateString])
            drawnow
        end
    end
    if abort | length(d)>20
        break
    end
end
% [~]=urlread('http://192.168.0.150/cgi-bin/handler.cgi?SamplingStop=Stop+sampling');
d=dir(f);
update_status('Getting left over files....',hObject,handles)
for i=1:length(d)
    update_status(d(i).name,hObject,handles)
    mget(f,d(i).name,handles.DataDirectory);
end
update_status('Cleaning LISST_Holo....',hObject,handles)
delete(f,'*.pgm')
close(f)
update_status('    Done.',hObject,handles)
update_status(datestr(now),hObject,handles)
set(handles.pbGo,'enable','on')
set(handles.pbConfigure,'enable','on')
set(handles.pbReset,'enable','on')
set(handles.pbDataDir,'enable','on')
set(handles.edtInterval,'enable','on')
set(handles.edtRootPassword,'enable','on')
guidata(hObject, handles);

% --- Executes on button press in pbStop.
function pbStop_Callback(hObject, eventdata, handles)
% hObject    handle to pbStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global abort
abort=1;
update_status('Asking LISST-Holo to stop....',hObject,handles)
try
    [~]=urlread('http://192.168.0.150/cgi-bin/handler.cgi?SamplingStop=Stop+sampling','Timeout',2);
end
update_status('    Stop sent.',hObject,handles)

% --- Executes on button press in pbConfigure.
function pbConfigure_Callback(hObject, eventdata, handles)
% hObject    handle to pbConfigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    update_status('Requesting sampling interval....',hObject,handles);
    [~]=urlread('http://192.168.0.150/cgi-bin/handler.cgi?PrgSelection=1&Prg1BM=0&Prg1BD=1&Prg1BY=2013&Prg1BH=0&Prg1BN=0&Prg1BS=0&Prg1BDly=1&Prg1BDlyU=0&Prg1BGT=0&Prg1Start=5&Prg1Fixed=1&Prg1FSI=+++++1&Prg1SI=+++++1&Prg1IPS=1&Prg1TBS=4&Prg1TBSU=0&Prg1SM=0&Prg1SD=1&Prg1SY=2013&Prg1SH=0&Prg1SN=0&Prg1SS=0&Prg1SDly=0&Prg1SDlyU=0&Prg1SGT=0&Prg1SLT=0&Prg1Stop=6&Prg1SSamples=1&PrgSave=Apply&Prg2Start=0&Prg2BM=0&Prg2BD=1&Prg2BY=2013&Prg2BH=0&Prg2BN=0&Prg2BS=0&Prg2BDly=1&Prg2BDlyU=0&Prg2BGT=0&Prg2FSI=+++++5&Prg2SI=+++++1&Prg2IPS=1&Prg2TBS=4&Prg2TBSU=0&Prg2Stop=0&Prg2SM=0&Prg2SD=1&Prg2SY=2013&Prg2SH=0&Prg2SN=0&Prg2SS=0&Prg2SDly=0&Prg2SDlyU=0&Prg2SGT=0&Prg2SLT=0&Prg2SSamples=1&Prg3Start=0&Prg3BM=0&Prg3BD=1&Prg3BY=2013&Prg3BH=0&Prg3BN=0&Prg3BS=0&Prg3BDly=1&Prg3BDlyU=0&Prg3BGT=0&Prg3FSI=+++++5&Prg3SI=+++++1&Prg3IPS=1&Prg3TBS=4&Prg3TBSU=0&Prg3Stop=0&Prg3SM=0&Prg3SD=1&Prg3SY=2013&Prg3SH=0&Prg3SN=0&Prg3SS=0&Prg3SDly=0&Prg3SDlyU=0&Prg3SGT=0&Prg3SLT=0&Prg3SSamples=1&Prg4Start=0&Prg4BM=0&Prg4BD=1&Prg4BY=2013&Prg4BH=0&Prg4BN=0&Prg4BS=0&Prg4BDly=1&Prg4BDlyU=0&Prg4BGT=0&Prg4FSI=+++++5&Prg4SI=+++++1&Prg4IPS=1&Prg4TBS=4&Prg4TBSU=0&Prg4Stop=0&Prg4SM=0&Prg4SD=1&Prg4SY=2013&Prg4SH=0&Prg4SN=0&Prg4SS=0&Prg4SDly=0&Prg4SDlyU=0&Prg4SGT=0&Prg4SLT=0&Prg4SSamples=1');
    update_status('Stopping write to flash....',hObject,handles);
    [~]=urlread('http://192.168.0.150/cgi-bin/handler.cgi?NewValue=%2Ftmp%2F&ParameterName%3DImageFilePath%26ChangeButton=Change');
catch exception
    catch_routine(exception,hObject,handles)
    return
end
set(handles.pbReset,'enable','on')
set(handles.pbDataDir,'enable','on')
update_status('    Config Done.',hObject,handles);


% --- Executes on button press in pbReset.
function pbReset_Callback(hObject, eventdata, handles)
% hObject    handle to pbReset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
update_status('Reset write path....',hObject,handles);
[~]=urlread('http://192.168.0.150/cgi-bin/handler.cgi?NewValue=%2Fmnt%2Fflash1%2Fftp%2Fimages%2F&ParameterName%3DImageFilePath%26ChangeButton=Change','timeout',60);
pause(1)
update_status('Requesting sampling interval of 10sec....',hObject,handles);
[~]=urlread('http://192.168.0.150/cgi-bin/handler.cgi?PrgSelection=1&Prg1BM=0&Prg1BD=1&Prg1BY=2013&Prg1BH=0&Prg1BN=0&Prg1BS=0&Prg1BDly=1&Prg1BDlyU=0&Prg1BGT=0&Prg1Start=5&Prg1Fixed=1&Prg1FSI=+++++10&Prg1SI=+++++1&Prg1IPS=1&Prg1TBS=4&Prg1TBSU=0&Prg1SM=0&Prg1SD=1&Prg1SY=2013&Prg1SH=0&Prg1SN=0&Prg1SS=0&Prg1SDly=0&Prg1SDlyU=0&Prg1SGT=0&Prg1SLT=0&Prg1Stop=6&Prg1SSamples=1&PrgSave=Apply&Prg2Start=0&Prg2BM=0&Prg2BD=1&Prg2BY=2013&Prg2BH=0&Prg2BN=0&Prg2BS=0&Prg2BDly=1&Prg2BDlyU=0&Prg2BGT=0&Prg2FSI=+++++5&Prg2SI=+++++1&Prg2IPS=1&Prg2TBS=4&Prg2TBSU=0&Prg2Stop=0&Prg2SM=0&Prg2SD=1&Prg2SY=2013&Prg2SH=0&Prg2SN=0&Prg2SS=0&Prg2SDly=0&Prg2SDlyU=0&Prg2SGT=0&Prg2SLT=0&Prg2SSamples=1&Prg3Start=0&Prg3BM=0&Prg3BD=1&Prg3BY=2013&Prg3BH=0&Prg3BN=0&Prg3BS=0&Prg3BDly=1&Prg3BDlyU=0&Prg3BGT=0&Prg3FSI=+++++5&Prg3SI=+++++1&Prg3IPS=1&Prg3TBS=4&Prg3TBSU=0&Prg3Stop=0&Prg3SM=0&Prg3SD=1&Prg3SY=2013&Prg3SH=0&Prg3SN=0&Prg3SS=0&Prg3SDly=0&Prg3SDlyU=0&Prg3SGT=0&Prg3SLT=0&Prg3SSamples=1&Prg4Start=0&Prg4BM=0&Prg4BD=1&Prg4BY=2013&Prg4BH=0&Prg4BN=0&Prg4BS=0&Prg4BDly=1&Prg4BDlyU=0&Prg4BGT=0&Prg4FSI=+++++5&Prg4SI=+++++1&Prg4IPS=1&Prg4TBS=4&Prg4TBSU=0&Prg4Stop=0&Prg4SM=0&Prg4SD=1&Prg4SY=2013&Prg4SH=0&Prg4SN=0&Prg4SS=0&Prg4SDly=0&Prg4SDlyU=0&Prg4SGT=0&Prg4SLT=0&Prg4SSamples=1','timeout',60);
pause(1)
set(handles.pbGo,'enable','off')
set(handles.pbDataDir,'enable','off')
update_status('    Config Done.',hObject,handles);

% --- Executes on button press in pbDataDir.
function pbDataDir_Callback(hObject, eventdata, handles)
% hObject    handle to pbDataDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
DataDir=uigetdir(handles.DataDirectory);
if ~isnumeric(DataDir)
    handles.DataDirectory=DataDir;
    guidata(hObject, handles);
    update_status('Data will be saved in:',hObject,handles);
    update_status(['    ' handles.DataDirectory],hObject,handles);
end
set(handles.pbGo,'enable','on')
    


function edtRootPassword_Callback(hObject, eventdata, handles)
% hObject    handle to edtRootPassword (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edtRootPassword as text
%        str2double(get(hObject,'String')) returns contents of edtRootPassword as a double
handles.RootPassword=get(hObject,'String');
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edtRootPassword_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtRootPassword (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end



function edtInterval_Callback(hObject, eventdata, handles)
% hObject    handle to edtInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edtInterval as text
%        str2double(get(hObject,'String')) returns contents of edtInterval as a double
handles.Interval=get(hObject,'String');
% set(handles.pbGo,'enable','off')
% set(handles.pbDataDir,'enable','off')
update_status('Now press ''Configure LISST-Holo''',hObject,handles)
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edtInterval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end

% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function update_status(string,hObject,handles,r)

%     oldtext=get(handles.lbStatus,'String');
%     set(handles.lbStatus,'String',[oldtext ; varin]);
%     set(handles.lbStatus,'ListboxTop',max([1 length(oldtext)-10]))
%     drawnow;
old_text=get(handles.status,'string');
if exist('r','var')
    set(handles.status,'string',[old_text(1:end-1,:) ; string])
else
    set(handles.status,'string',[old_text ; string])
end
set(handles.status,'ListboxTop',max([1 length(old_text)-5]))
set(handles.status,'ForegroundColor','w')
drawnow
guidata(hObject, handles);

function catch_routine(exception,hObject,handles)
    update_status('****',hObject,handles)
    update_status('ERROR:',hObject,handles)
    update_status(exception.message,hObject,handles)
    update_status('****',hObject,handles)
    set(handles.status,'ForegroundColor','r')
%     set(handles.status,'fontcolor','r')
