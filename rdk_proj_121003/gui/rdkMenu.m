function varargout = rdkMenu(varargin)
% RDKMENU M-file for rdkMenu.fig
%      RDKMENU, by itself, creates a new RDKMENU or raises the existing
%      singleton*.
%
%      H = RDKMENU returns the handle to a new RDKMENU or the handle to
%      the existing singleton*.
%
%      RDKMENU('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RDKMENU.M with the given input arguments.
%
%      RDKMENU('Property','Value',...) creates a new RDKMENU or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before rdkMenu_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to rdkMenu_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help rdkMenu

% Last Modified by GUIDE v2.5 30-Dec-2008 13:43:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @rdkMenu_OpeningFcn, ...
                   'gui_OutputFcn',  @rdkMenu_OutputFcn, ...
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
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% --- Executes just before rdkMenu is made visible.
function rdkMenu_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rdkMenu (see VARARGIN)

% Choose default command line output for rdkMenu
handles.output = hObject;

%----   Get display structure from input or generate
if nargin == 1
    poss_disp_struct = varargin{1};
    % See if has screens field, if so, probably display struct
    if isfield( poss_param_struct, 'display')
        params = varargin{1};
        handles.params = params;
    end
else
    handles.params.control.verbose = 1;
    handles.params.control.debug = 1;
    handles.params.display = rdkGetDisplayParams( handles.params );
end
    
%----   Choose default values from GUI

%----   Expt structure

contents = get(handles.ExptType_popupmenu,'String');
params.exp.type = contents{get(handles.ExptType_popupmenu,'Value')};

contents = get(handles.GenerateMode_popupmenu,'String');
params.exp.generate_mode = contents{get(handles.GenerateMode_popupmenu,'Value')};

params.exp.nblocks = str2double(get(handles.Nblocks_edit,'String'));

%----   Blocks, trial, dotstim
for b = 1:params.exp.nblocks
    % Trials/block
    params.exp.block(b).ntrials = str2double(get(handles.NTrials_edit,'String'));

    % How terminate block
    contents = get(handles.BlockLengthType_popupmenu,'String');
    params.exp.block(b).length_type = contents{get(handles.BlockLengthType_popupmenu,'Value')};

    % Loop on trial(s)
    for t = 1:params.exp.block(b).ntrials
        
        % Fig/bg mode
        contents = get(handles.FigBgMode_popupmenu,'String');
        params.exp.block(b).trial(t).fig_bg_mode = contents{get(handles.FigBgMode_popupmenu,'Value')};
        
        % Duration seconds
        params.exp.block(b).trial(t).duration_secs = str2double(get(handles.DurationSecs_edit,'String'));
        
        % Fixation mode, size
        contents = get(handles.FixMode_popupmenu,'String');
        params.exp.block(b).trial(t).fix.mode = contents{get(handles.FixMode_popupmenu,'Value')};

        params.exp.block(b).trial(t).fix.deg = str2double(get(handles.FixDeg_edit,'String'));
        params.exp.block(b).trial(t).fix.pix = params.exp.block(b).trial(t).fix.deg *...
            handles.params.display.ppd;

        % Bounds (maximum dot positions given screen params *** FIX
        params.exp.block(b).trial(t).bounds = [0 0 0 0];
                
        % Compute these...
        this_trial = params.exp.block(b).trial(t);
        %----   ndotstim
        if strcmp( this_trial.fig_bg_mode, 'fig+bgnd' )
            params.exp.block(b).trial(t).ndotstim = 2;
        else
            params.exp.block(b).trial(t).ndotstim = 1;
        end

        %----   duration_fr
        params.exp.block(b).trial(t).duration_fr = round( params.exp.block(b).trial(t).duration_secs...
            * handles.params.display.fps );
        

        % Loop to fill dotstim
        for d = 1:params.exp.block(b).trial(t).ndotstim
        end % for d
        
    end % for t
end % for b
control.trial_number = 1;
control.block_number = 1;

handles.params.exp = params.exp;
handles.output = handles.params;


handles.control = control;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes rdkMenu wait for user response (see UIRESUME)
uiwait(handles.figure1);
return;
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = rdkMenu_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.params;
% quit
delete(handles.figure1);
return;
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% --- Executes on selection change in GenerateMode_popupmenu.
function GenerateMode_popupmenu_Callback(hObject, eventdata, handles)

contents = get(hObject,'String');
handles.params.exp.generate_mode = contents{get(hObject,'Value')};
guidata(hObject, handles);
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function GenerateMode_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GenerateMode_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% --- Executes on selection change in ExptType_popupmenu.
function ExptType_popupmenu_Callback(hObject, eventdata, handles)

contents = get(hObject,'String');
handles.params.exp.type = contents{get(hObject,'Value')};
guidata(hObject, handles);
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function ExptType_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ExptType_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
function Nblocks_edit_Callback(hObject, eventdata, handles)
handles.params.exp.nblocks = str2double(get(hObject,'String'));
guidata(hObject, handles);
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function Nblocks_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Nblocks_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% --- Executes on button press in Ok_pushbutton.
function Ok_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Ok_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.figure1);
return;
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
function NTrials_edit_Callback(hObject, eventdata, handles)
% hObject    handle to NTrials_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

value = str2double(get(hObject,'String'));

thisblock = handles.control.block_number;
handles.params.exp.block(thisblock).ntrials = value;
guidata(hObject, handles);
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function NTrials_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NTrials_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%--------------------------------------------------------------------------


% --- Executes on selection change in BlockLengthType_popupmenu.
function BlockLengthType_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to BlockLengthType_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contents = get(hObject,'String'); 
value = contents{get(hObject,'Value')};

thisblock = handles.control.block_number;
handles.params.exp.block(thisblock).length_type = value;
guidata(hObject, handles);
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function BlockLengthType_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BlockLengthType_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% --- Executes on selection change in BlockNumber_popupmenu.
function BlockNumber_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to BlockNumber_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

value = get(hObject,'Value');
handles.control.block_number = value;

% Add handler to change block number arrays, etc. *** FIX

guidata(hObject, handles);
%--------------------------------------------------------------------------




%--------------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function BlockNumber_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BlockNumber_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% --- Executes on selection change in FigBgMode_popupmenu.
function FigBgMode_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to FigBgMode_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

contents = get(hObject,'String');
value = contents{get(hObject,'Value')};

thisblock = handles.control.block_number;
thistrial = handles.control.trial_number;
handles.params.exp.block(thisblock).trial(thistrial).fig_bg_mode = value;

guidata(hObject, handles);
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function FigBgMode_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FigBgMode_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
function DurationSecs_edit_Callback(hObject, eventdata, handles)
% hObject    handle to DurationSecs_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

value = str2double(get(hObject,'String'));

thisblock = handles.control.block_number;
thistrial = handles.control.trial_number;
handles.params.exp.block(thisblock).trial(thistrial).duration_secs = value;

% Compute in frames, also
handles.params.exp.block(thisblock).trial(thistrial).duration_fr = value * ...
    handles.params.display.fps;

guidata(hObject, handles);
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function DurationSecs_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DurationSecs_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% --- Executes on selection change in FixMode_popupmenu.
function FixMode_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to FixMode_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

contents = get(hObject,'String');
value = contents{get(hObject,'Value')};

thisblock = handles.control.block_number;
thistrial = handles.control.trial_number;
handles.params.exp.block(thisblock).trial(thistrial).fix.mode = value;

guidata(hObject, handles);
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function FixMode_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FixMode_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
function FixDeg_edit_Callback(hObject, eventdata, handles)
% hObject    handle to FixDeg_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

value = str2double(get(hObject,'String'));

thisblock = handles.control.block_number;
thistrial = handles.control.trial_number;
handles.params.exp.block(thisblock).trial(thistrial).fix.deg = value;

% Compute pix value, too 
handles.params.exp.block(thisblock).trial(thistrial).fix.pix = value *...
    handles.params.display.ppd;

guidata(hObject, handles);
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function FixDeg_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FixDeg_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
function trial = ComputeTrialParams( trial, display )

%----   ndotstim
if strcmp( trial.fig_bg_mode, 'fig+bgnd' )
    trial.ndotstim = 2;
else
    trial.ndotstim = 1;
end

%----   duration_fr
trial.duration_fr = round( trial.duration_secs * display.fps );

return
%--------------------------------------------------------------------------

