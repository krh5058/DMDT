classdef DotDisp < handle & hgsetget
    % General screen presentation object This class is used for dot
    % presentation, text display, and response recording initiation.
    % DotDisp utilizes recursion to continue trial presentation until trial
    % length is reached, which it either end (if practice) or add a block
    % iteration and continue.  Dot presentation is executed with a timer
    % object, with a TimerFcn that executes according the frame rate
    % (default 60Hz).  However, due to the millisecond precision on timer
    % execution, this value is rounded up to the thousandth decimal.  The
    % timer StartFcn: dobj.t.UserData = dobj.t.UserData + 1;', tallies
    % presentation iteration within the timer object's "UserData".  The
    % StopFcn, 'dobj.loadQueue', executes DotDisp's loadQueue function
    % which moves all queue values into the "pres" and empties "queue".
    % This occurs after each trial presentation, so that "queue" is ready
    % to receive new property values from DotGen upon the next trial start.
    % Values labeled "pres" are the current dot display properties, which
    % is one iteration behind the "queue", and two iterations behind
    % "coh_count".
    %
    % The timer object calls dobj.drawDots, which is an easy-to-use
    % function used to display the dots according to the position vector at
    % framerate "fr".  dobj.dispTxt is also a simple function call that is
    % used to display text and wait a specified amount of time, and has
    % been modified to take SRbox or keyboard presses into account.
    % dobj.dmdtrun is the recursive call, which is the umbrella function
    % for the entire script.  This function will continue until the number
    % of trials in pres_coh is reached, and whether the practice length or
    % task length is reached, it will handle following executions
    % appropriately according to a set of 'if' statements.  Due to its
    % recursive nature, property "kickout" is implemented, such that when
    % recursive ends all function calls are appropriately "return"-ed.
    % Lastly, startRecord is used to notify DataFile of response recording
    % initiation, which also flushes all events in the SRbox queue prior to
    % the trial.
    %
    % Created by Ken Hwang, M.S.
    % Last modified 11/5/12
    % Requested by Cari Bogulski
    % PSU, SLEIC, Dept. of Psychology
    
    properties (SetObservable)
        vbl = 0 % VBL timestamp
        pres % Presentation dot array
        LR_pres % LR of presentation array
        coh_pres % Coherenece of presentation array
        block_pres % Block count of presentation array
        queue % Dot array queue
        LR_queue % LR of queue array
        coh_queue % Coherence of queue array
        block_queue % Block for queue array
        pixsize % Dot pixel size
        w % Window handle
        fix_coord % Fixation coordinates
        t % Timer object
        fr = 0; % Current frame
        genobj % Generator object name
        dispobj % Display object name
        dataobj % Data object name
        startTime; % Trial start time
        prac % Practice flag
        pst_h % PST box handle
        Lbit = 1; % Left bit-value
        Rbit = 16; % Right bit-value
        rkey
        zkey
        slashkey
        esckey
        kickout = 0; % Recursive kickout flag
    end
    events
        record
    end
    methods
        % Initialize
        function obj = DotDisp(gobj,genobj,dispobj,dataobj,prac,pst_h)
            KbName('UnifyKeyNames');
            %             obj.zkey = KbName('z');
            %             obj.slashkey = KbName('/?');
            obj.pst_h = pst_h;
            obj.esckey = KbName('ESCAPE');
            obj.rkey = KbName('r');
            obj.prac = prac;
            obj.genobj = genobj;
            obj.dispobj = dispobj;
            obj.dataobj = dataobj;
            obj.w = Screen('OpenWindow',gobj.display.screenNumber,gobj.display.black);
            obj.pixsize = gobj.dot.pixsize;
            obj.fix_coord = gobj.display.fix_coord;
            %             obj.lh = addlistener(gobj,'pres','PostSet',@DotDisp.loadDot);
            obj.t = timer('TimerFcn',@(x,y)evalin('base',[dispobj '.drawDots;']), ...
                'StartFcn',@(x,y)evalin('base',[dispobj '.t.UserData = ' dispobj '.t.UserData + 1;']), ...
                'StopFcn',@(x,y)evalin('base',[dispobj '.loadQueue;']), ...
                'Period',gobj.display.ifi, ...
                'TasksToExecute',gobj.display.fr, ...
                'ExecutionMode','fixedRate', ...
                'UserData',0);
        end
        function startRecord(obj)
            SRflush = CMUBox('GetEvent',obj.pst_h); 
            while ~isempty(SRflush) % Continue call until event queue is empty
                SRflush = CMUBox('GetEvent',obj.pst_h);
            end
            RestrictKeysForKbCheck(obj.esckey);
            obj.startTime = GetSecs;
            notify(obj,'record'); % Broadcast
        end
        % Load queue info, delete queue
        function loadQueue(obj)
            if ~isempty(obj.queue) % Load if not empty
                obj.pres = obj.queue;
                obj.LR_pres = obj.LR_queue;
                obj.coh_pres = obj.coh_queue;
                obj.block_pres = obj.block_queue;
            end
            obj.queue = [];
            obj.LR_queue = [];
            obj.coh_queue = [];
            obj.block_queue = [];
            
            obj.fr = 0;
        end
        % Draw dots function
        function drawDots(obj)
            obj.fr = obj.fr + 1;
            Screen('DrawDots',obj.w,obj.pres(:,:,obj.fr)',obj.pixsize);
            obj.vbl = Screen('Flip',obj.w);
        end
        % Draw text function
        function dispTxt(obj,txt,waitS,box)
            DrawFormattedText(obj.w,txt,'center','center',255,[],[],[],3);
            Screen('Flip',obj.w);
%             RestrictKeysForKbCheck([obj.esckey obj.slashkey obj.zkey]);
%             [~,keyCode,~] = KbStrokeWait;
            if box
                % Flush queue
                SRflush = CMUBox('GetEvent',obj.pst_h);
                while ~isempty(SRflush) % Continue call until event queue is empty
                    SRflush = CMUBox('GetEvent',obj.pst_h);
                end
                CMUBox('GetEvent',obj.pst_h,1); % wait for button press
            else
                RestrictKeysForKbCheck([obj.esckey obj.rkey]);
                [~,keyCode,~] = KbStrokeWait;
                if find(keyCode)==obj.esckey
                    evalin('base','abort==1')
                    obj.kickout = 1;
                    return;
                end
            end
            Screen('Flip',obj.w);
            WaitSecs(waitS);
        end
        % Recursive call
        function dmdtrun(obj)
            while evalin('base','dobj.t.UserData < gobj.trial_n')
                evalin('base','start(dobj.t);');
                evalin('base','dobj.startRecord;');
                if evalin('base','abort;')
                    return;
                else % If no abort
                    Screen('FillOval', obj.w, 255, obj.fix_coord );
                    Screen('Flip',obj.w);
                    evalin('base','gobj.init = [];');
                    WaitSecs(.5); % 500ms wait between
                    dmdtrun(obj); % Recursive call
                    if obj.kickout
                        return;
                    end
                end
            end
            % End of run
            if evalin('base','dobj.prac;'); % If Practice
                evalin('base','dobj.dispTxt(endptxt,1,1);'); % End practice text, pause 1 second
                obj.kickout = 1; % Kick out of recursion
                return;
            else
                % If block count is not reached
                if evalin('base','gobj.block_count < pres_param(1)')
                    evalin('base','dobj.dispTxt(break1txt,0,0);'); % Display break1 text (keyboard press)
                    evalin('base','gobj.coh_count = 1;'); % Reset coh_count
                    evalin('base','gobj.lh.Enabled = true;'); % Re-enable listening
                    evalin('base','gobj.block_count = gobj.block_count + 1;'); % Add to block count
                    evalin('base','dobj.dispTxt(break2txt,0,1);'); % Display break2 text
                    evalin('base','gobj.init = [];');
                    evalin('base','dobj.loadQueue;');
                    obj.t.UserData = 0; % Reset
                    dmdtrun(obj); % Recursive call
                    if obj.kickout
                        return;
                    end
                else
                    evalin('base','dobj.dispTxt(endtxt,0,1);'); % Display end text
                    obj.kickout = 1; % Kick out of recursion
                end
            end
        end
    end
end
