classdef DataFile < handle & hgsetget
    % Response recorder and data output manager.
    % This class will initiate response recording according to event
    % "record", calculate accuracy of response, and write data output to
    % .csv according to file identifier, "fid".  Upon notification from
    % DotDisp, KbCheck is initiated and listens to either the Lbit, Rbit,
    % or 'Escape' keys.  Hitting 'Escape' will successfully abort the
    % script, whereas Lbit and Rbit (from the SRbox) are recorded as left
    % or right responses, respectively.  Upon response, dobj.t timer object
    % is stopped, and accuracy is calculated.  This is initiated through
    % listener handle, "lh3".  This listener handle is turned off for
    % practice since accuracy calculations, and subsequent data output is
    % unnecessary. Additionally, listener handle, "lh" listens for accuracy
    % calculation, which then writes output.  If no response, then response
    % is logged as 'NA' and accuracy is logged as '99'.
    % 
    % Created by Ken Hwang, M.S.
    % Last modified 10/22/12
    % Requested by Cari Bogulski
    % PSU, SLEIC, Dept. of Psychology

    properties (SetObservable)
       fid % File identifier
       lh % Accuracy listener
       lh2 % Display object record event listener
       lh3 % Response entry listener
       resp % Response cell property
       acc % Accuracy value property
       zkey % Z-key
       slashkey % /-key
       Lbit = 1; % Left bit-value
       Rbit = 16; % Right bit-value
       esckey % ESC-key
       subj % Subj ID
       block % Block number
       coh % Coherence condition
    end
    
    methods
        function obj = DataFile(dobj,fid,subj)
            obj.subj = subj;
            KbName('UnifyKeyNames');
%             obj.zkey = KbName('z');
%             obj.slashkey = KbName('/?');
            obj.esckey = KbName('ESCAPE');
%             RestrictKeysForKbCheck([obj.zkey obj.slashkey obj.esckey]);
            RestrictKeysForKbCheck(obj.esckey);
            obj.fid = fid;
            obj.lh2 = addlistener(dobj,'record',@DataFile.record);
            obj.lh = addlistener(obj,'acc','PostSet',@(src,evt)writeFile(obj,src,evt));
            obj.lh3 = addlistener(obj,'resp','PostSet',@DataFile.accCheck);
        end
        function writeFile(obj,src,evt)
            switch obj.resp{4}
                case obj.Lbit
                    respstr = 'L';
                case obj.Rbit
                    respstr = 'R';
                case obj.esckey
                    respstr = 'ESC';
                otherwise
                    respstr = 'NA';
            end
            if obj.resp{3}
                dispstr = 'R';
            else
                dispstr = 'L';
            end
%             disp(obj.fid);
%             disp(obj.subj);
%             disp(obj.resp{1})
%             disp(obj.resp{2})
%             disp(dispstr);
%             disp(respstr);
%             disp(obj.resp{5})
%             disp(evt.AffectedObject.acc);
            fprintf(obj.fid,'%s,%d,%1.4f,%s,%s,%6.4f,%d\n',obj.subj{1},obj.resp{1},obj.resp{2},dispstr,respstr,obj.resp{5},evt.AffectedObject.acc);
        end    
    end
    
    methods (Static)
        function record(src,evt)
%             keyIsDown = 0;
%             while strcmp(get(src.t,'Running'),'on')
%                 [keyIsDown,secs,keyCode] = KbCheck;
%                 if keyIsDown
%                     if find(keyCode)==evalin('base','dataobj.esckey')
%                         stop(src.t);
%                         evalin('base','Screen(''CloseAll'')');
%                         evalin('base','abort = 1;');
%                         src.kickout = 1; % Kick out of recursion
%                         return;
%                     end
% %                     disp(find(keyCode)); % Temp
%                     RT = secs - src.startTime;
% %                     disp({src.block_pres,src.coh_pres,src.LR_pres,find(keyCode),RT}); % Temp
%                     % Resp cols: 1) Block #, 2) Coherence value, 3) LR of
%                     % presentation, 4) Z or / Response, 5) RT
%                     evalin('base',[src.dataobj '.resp = {' int2str(src.block_pres) ',' num2str(src.coh_pres) ',' int2str(src.LR_pres) ',' int2str(find(keyCode)) ',' num2str(RT) '};']);
%                     evalin('base','stop(timerfind);');
%                 end
%             end
%             % No response
%             if ~keyIsDown
%                 evalin('base',[src.dataobj '.resp = {' int2str(src.block_pres) ',' num2str(src.coh_pres) ',' int2str(src.LR_pres) ',0,0};']);
%             end
            keyIsDown = 0;
            while strcmp(get(src.t,'Running'),'on')
                [keyIsDown,~,keyCode] = KbCheck;
                SRevt = CMUBox('GetEvent', src.pst_h);
                if keyIsDown 
                    if find(keyCode)==evalin('base','dataobj.esckey')
                        stop(src.t);
                        evalin('base','Screen(''CloseAll'')');
                        evalin('base','abort = 1;');
                        src.kickout = 1; % Kick out of recursion
                        return;
                    end
                end
                if ~isempty(SRevt)
                    if SRevt.state ~= src.Lbit && SRevt.state ~= src.Rbit % If not left or right press
                        SRflush = CMUBox('GetEvent',src.pst_h);
                        while ~isempty(SRflush) % Continue call until event queue is empty
                            SRflush = CMUBox('GetEvent',src.pst_h);
                        end
                    else
                        RT = SRevt.time - src.startTime;
                        % Resp cols: 1) Block #, 2) Coherence value, 3) LR of
                        % presentation, 4) Z or / Response, 5) RT
                        evalin('base',[src.dataobj '.resp = {' int2str(src.block_pres) ',' num2str(src.coh_pres) ',' int2str(src.LR_pres) ',' int2str(SRevt.state) ',' num2str(RT) '};']);
                        evalin('base','stop(timerfind);'); % Kick while
                    end
                end
            end
            % No response
            if isempty(SRevt)
                evalin('base',[src.dataobj '.resp = {' int2str(src.block_pres) ',' num2str(src.coh_pres) ',' int2str(src.LR_pres) ',0,0};']);
            end
        end
        function accCheck(src,evt)
%             if evt.AffectedObject.resp{3} % If Right
%                 if evt.AffectedObject.resp{4}==evt.AffectedObject.slashkey % If slashkey is pressed
%                     evt.AffectedObject.acc = 1;
%                 elseif evt.AffectedObject.resp{4}==0 % If no response
%                     evt.AffectedObject.acc = 99;
%                 else
%                     evt.AffectedObject.acc = 0;
%                 end
%             else % If Left
%                 if evt.AffectedObject.resp{4}==evt.AffectedObject.zkey % If zkey is pressed
%                     evt.AffectedObject.acc = 1;
%                 elseif evt.AffectedObject.resp{4}==0 % If no response
%                     evt.AffectedObject.acc = 99;
%                 else
%                     evt.AffectedObject.acc = 0;
%                 end
%             end
            if evt.AffectedObject.resp{3} % If Right
                if evt.AffectedObject.resp{4}==evt.AffectedObject.Rbit % If Rbit is pressed
                    evt.AffectedObject.acc = 1;
                elseif evt.AffectedObject.resp{4}==0 % If no response
                    evt.AffectedObject.acc = 99;
                else
                    evt.AffectedObject.acc = 0;
                end
            else % If Left
                if evt.AffectedObject.resp{4}==evt.AffectedObject.Lbit % If Lbit is pressed
                    evt.AffectedObject.acc = 1;
                elseif evt.AffectedObject.resp{4}==0 % If no response
                    evt.AffectedObject.acc = 99;
                else
                    evt.AffectedObject.acc = 0;
                end
            end
        end
    end
    
end