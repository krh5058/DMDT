% DMDT
% Caller script for dot-motion discrimination task.
% Usage: dmdt
% Requirements: Serial Response Box (PST) with appropriate drivers (included),
% PsychToolbox (as of 3.10), and Matlab (as of 7.13.0.564 -- R2011b).
%
% Using the Serial Response Box: For the SRbox to work,
% PL2303_Prolific_DriverInstaller_v1.7.0 must be run.  First, make sure
% that SRbox and USB-serial converter (Plugable) is disconnected.  Then,
% run drivers.  Plug in the USB-serial converter to the serial connector on
% the PST SRbox and then into a USB port on the computer.  Open Device
% Manager and under "Ports & LDT" note the COM number.  The variable's
% value, 'com', must be changed to this number.
%
% Options: Prompts for subject ID, coherence values (7), and
% block/condition repetition parameters.  Condition repetition denotes how
% many times the 7 coherence values will be repeated within each block.  In
% order to keep equal counterbalancing of left and right motion conditions,
% this value must be even.  Default values for coherence values are:
% .008, .016, .032, .064, .128, .256, .512.  Default values for number of
% blocks and condition repetition are 5 and 20, respectively.
%
% Presentation is composed of a practice of each coherence value followed
% by the actual task.  Response recording is not monitored for practice
% conditions.  Output is filed under subject-specific directory within
% 'data' in a .csv format time-stamped for trial start time and date.
%
% Trial conditions are randomly assigned a coherence condition and a motion
% direction (either left or right).  Coherence is distributed amongst dots
% by random reassignment upon each frame of either linear motion or random
% motion.  Text displays occur prior to practice, after practice, between
% blocks, and at the end of the task.  Text can modified in variables:
% itxt, endptxt, break1txt, break2 txt,and endtxt.  Text formatting and
% wrapping on screen is automatic.
% 
% Created by Ken Hwang, M.S.
% Last modified 10/8/12
% Requested by Cari Bogulski
% PSU, SLEIC, Dept. of Psychology

PsychJavaTrouble;
rand('state',sum(clock*100));
randn('state',sum(clock*100));
warning('off','MATLAB:TIMER:RATEPRECISION');
com = '3'; % Default

% Directory of this script
file_str = mfilename('fullpath');
[file_dir,~,~] = fileparts(file_str);
% file_dir = fileparts(file_dir);

% Subj ID
subj_prompt={'Subject ID:'};
subj_name='Enter Subject ID';
subj_numlines=1;
subj_defaultanswer={'subj'};
subj_options.Resize='on';
s_name = inputdlg(subj_prompt,subj_name,subj_numlines,subj_defaultanswer,subj_options);
if isempty(s_name)
    clear all
    error('User Cancelled');
end
mkdir([file_dir filesep 'data' filesep s_name{1}]);

% Condition UI
cond_prompt={'1:','2:','3:','4:','5:','6:','7:'};
cond_name='Condition values (7)';
cond_numlines=1;
cond_defaultanswer={'.008','.016','.032','.064','.128','.256','.512'};
cond_options.Resize='on';
cond_options.WindowStyle='normal';
cond_options.Interpreter='tex';
coh=inputdlg(cond_prompt,cond_name,cond_numlines,cond_defaultanswer,cond_options);
if isempty(coh)
    clear all
    error('User Cancelled');
end
try
    condvals = cellfun(@(y)(str2num(y)),coh);
catch ME    
    disp('DMDT Error: Make sure that all condition values are numeric.');
    error(ME.message)
end

% Presentation format
pres_prompt={'Blocks:','Condition repetitions per block:'};
pres_name='Experimental design parameters';
pres_numlines=1;
pres_defaultanswer={'5','20'};
pres_options.Resize='on';
pres_options.WindowStyle='normal';
pres_options.Interpreter='tex';
pres_param=inputdlg(pres_prompt,pres_name,pres_numlines,pres_defaultanswer,pres_options);
if isempty(pres_param)
    clear all
    error('User Cancelled');
end
try
    pres_param = cellfun(@(y)(str2num(y)),pres_param);
    
    if mod(pres_param(2),2) > 0
        error('Repetition parameter must be even.')
    end
    
catch ME    
    error(ME.message)
end

% Text
itxt = WrapString('In this task, you will see arrays of dots on the screen. In each array, some proportion of the dots will be moving in the same direction, either LEFT or RIGHT. Your task is to decide as QUICKLY and ACCURATELY as possible whether the coherent direction of motion is LEFT or RIGHT, using the LEFT key as your LEFT response, and the RIGHT key as your RIGHT response. When you are ready to begin some practice trials, please place your index fingers on the LEFT and RIGHT keys, and hit either key to begin.');
endptxt = WrapString('This completes the practice trials. The task is divided into 5 blocks, with a break in between each block for you to rest your eyes before continuing. If you have any questions, feel free to ask the experimenter now. When you are ready to begin the task, please place your index fingers on the LEFT and RIGHT keys, and hit either key to get started.');
break1txt = WrapString('Please take this opportunity to rest your eyes and take a short break. When you feel ready to continue, please hit the ''r'' key for ''ready''.');
break2txt = WrapString('When you are ready to begin the next block of trials, please place your fingers on the LEFT and RIGHT keys on the button box, and hit either key to begin');
endtxt = WrapString('Congratulations! You have completed this portion of the experiment! Please notify the experimenter.');

% Experimental design
trial_n = pres_param(2)*length(condvals);
set(0,'RecursionLimit',trial_n + 100) % Set Recursion limit based on trial_n with 100 buffer
pres_coh = repmat(condvals,[pres_param(2) pres_param(1)]);
pres_coh = Shuffle(pres_coh);
prac_coh = Shuffle(condvals);
LR_mat = Shuffle([ones([size(pres_coh,1)/2 size(pres_coh,2)]); zeros([size(pres_coh,1)/2 size(pres_coh,2)])]);
prac_LR = randi(0:1,[length(condvals) 1]);

% Output Set-up
fid = fopen([file_dir filesep 'data' filesep s_name{1} filesep s_name{1} '_' datestr(now,30) '.csv'],'a');
headers = {'Subject','Block','Condition','LR_Presentation','LR_Response','RT','Acc'};
fprintf(fid,'%s,%s,%s,%s,%s,%s,%s\n',headers{:}); % Print headers

close(gcf);
obj_h = {'gobj','dobj','dataobj'}; % Handle names

pst_h = CMUBox('Open', 'pst',['COM' com],'norelease'); % Set-up SRbox
abort = 0;

ShowHideWinTaskbarMex(0);
ListenChar(2);
HideCursor;

    % Practice:
% Object definitions
gobj = DotGen(prac_coh,prac_LR,obj_h{1},obj_h{2},obj_h{3});
dobj = DotDisp(gobj,obj_h{1},obj_h{2},obj_h{3},1,pst_h); % Practice
dataobj = DataFile(dobj,fid,s_name);
dataobj.lh3.Enabled = false; % Turn off listening for practice
% Set-up
gobj.init = [];
dobj.loadQueue;

try
    dobj.dispTxt(itxt,1,1); % Instructions text, Pause 1 second
    dobj.dmdtrun; % Run practice

    eval(['clear ' obj_h{1} ' ' obj_h{2} ' ' obj_h{3} ' ']); % Clear handle names
    
    if abort
    else
        % Task:
        % Object definitions
        gobj = DotGen(pres_coh,LR_mat,obj_h{1},obj_h{2},obj_h{3});
        dobj = DotDisp(gobj,obj_h{1},obj_h{2},obj_h{3},0,pst_h); % Task
        dataobj = DataFile(dobj,fid,s_name);
        % Set-up
        gobj.init = [];
        dobj.loadQueue;
        
        dobj.dmdtrun; % Run task
    end
    
catch ME
    disp(ME.message);
    fclose('all');
    Screen('CloseAll');
    ShowHideWinTaskbarMex(1);
    ListenChar(0);
    ShowCursor;
end

fclose('all');
Screen('CloseAll');
ShowHideWinTaskbarMex(1);
CMUBox('Close',pst_h)
ListenChar(0);
ShowCursor;
clear all
close all