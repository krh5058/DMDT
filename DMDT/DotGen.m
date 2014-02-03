classdef DotGen < handle & hgsetget
    % Parameter definition and dot array generator
    % This class definition creates an object instance used for active dot
    % array generation.  DotGen is called prior to each block start and
    % upon each trial.  Currently dot generation is run serially before
    % each display, so large dot-arrays will delay presentation.  Thus,
    % take care when setting fine dot sizes or long trial durations.  These
    % settings will require DotGen to construct very large dot arrays
    % because each following trial's dot array is generated upon the trial
    % presentation.  The current set-up will allow for parallel generation
    % of dot-arrays, but has not been implemented yet.
    %
    % Dot generation is contingent on display parameters, as well, which is
    % calculated upon instance definition.  Currently, visual parameters
    % have been set according to the requested experimental conditions
    % (view distance, monitor width, and refresh rate).
    %
    % DotGen is initiated upon change of the observable property "init".
    % This property is being listened to by handle "lh", which is turned
    % on or off on block start/end.  Dot arrays are held in property
    % "queue" which is transferred over to DotDisp property queue.
    % Property "coh_count" is added after each dot generation.  Due to
    % the dot generation prior to its display, the dot array held in
    % "queue" is always one iteration ahead of the actual display on
    % screen.  Additionally, "coh_count" is tallied after each dot
    % generation, so "coh_count" is actually two iterations of ahead of the
    % coherence being displayed on screen.  The forethought in these
    % iterations are taken into account when output is concerned.  Thus,
    % the reason for block_queue, coh_queue, and LR_queue properties in
    % DotDisp, which are recorded on each queue generation.
    %
    % Currently, each dot array is first constructed in a square with area
    % d^2, d being the diameter of the circle mask used.  When dots move
    % out of this field, they are automatically relocated on the opposing
    % side of the square such that no dots are ever killed or regenerated
    % within a trial.  Afterwards, the entire display is masked by a circle
    % of defined radius, circle_deg.  These dots are created for each
    % frame, which is z-dimension long in "queue", the length of which is
    % determined by frames per period and duration length (in seconds).  
    %
    % Created by Ken Hwang, M.S.
    % Last modified 10/22/12
    % Requested by Cari Bogulski
    % PSU, SLEIC, Dept. of Psychology

    properties (SetObservable)
        dur = 2; % Duration in seconds
        circle_deg = 10; % Circle radius in degrees
        dot_dens = .1; % Dot Density
%         dot_kill_per = .01;
        dot_deg = .05; % Dot degree
        fix_deg = .15; % Fixation degree
        mot_v = 2; % Deg/sec motion
%         mot_dir = pi;
        dot % Dot structure
        display % Display structure
        motion % Motion structure
        pres_coh % Coherence values
        trial_n % Length of trials
        coh_count = 1; % Coherence/trial counter
        block_count = 1; % Block counter
        LR_mat % LR Matrix (0 = left, 1 = right)
        init % Initialize gen callback
        queue % Dot array queue
        lh % Listener handle
        genobj % Generator object name
        dispobj % Display object name
        dataobj % Data object name
    end
    
    methods
        function obj = DotGen(pres_coh,LR_mat,genobj,dispobj,dataobj)
            
            % Display parameters
            obj.genobj = genobj;
            obj.dispobj = dispobj;
            obj.dataobj = dataobj;
            obj.pres_coh = pres_coh;
            obj.trial_n = length(pres_coh);
            obj.LR_mat = LR_mat;
            obj.display.screens = Screen('Screens');
            obj.display.screenNumber = max( obj.display.screens );
            obj.display.doublebuffer = 1;
            
            [width_pix, height_pix]=Screen('WindowSize', obj.display.screenNumber);
            
            obj.display.height_pix = height_pix;
            obj.display.width_pix = width_pix;
            
            obj.display.rect = [0  0 width_pix height_pix];
            
            obj.display.black = 1;
            obj.display.white = 255;
            obj.display.width_cm = 40.8; % Width in cm
            [obj.display.center(1), obj.display.center(2)] = RectCenter( obj.display.rect );
            
            obj.display.view_dist_cm = 65;
            obj.display.fps = 60;
            obj.display.ifi = 1/obj.display.fps;
            obj.display.fr = obj.dur * obj.display.fps;
            
            obj.display.waitframes   = 1;
            obj.display.update_hz    = obj.display.fps/obj.display.waitframes;
            obj.display.update_ifi   = 1/obj.display.update_hz;
            obj.display.ppd = pi * (width_pix) / atan(obj.display.width_cm/obj.display.view_dist_cm/2) / 360;
            fixpix = obj.display.ppd * obj.fix_deg;
            obj.display.fix_coord = [ obj.display.center - fixpix  obj.display.center + fixpix ];
            
            % Motion
            obj.motion.mot_v = obj.mot_v;
%             obj.motion.mot_dir = obj.mot_dir;
            obj.motion.pfs = obj.mot_v * obj.display.ppd / obj.display.fps;            
            
            % Dot field calculations
            obj.dot.r_pix = obj.circle_deg * obj.display.ppd;
            obj.dot.dotField = [obj.display.center(1)-obj.dot.r_pix obj.display.center(2)-obj.dot.r_pix obj.display.center(1)+obj.dot.r_pix obj.display.center(2)+obj.dot.r_pix];

            % Region and dot parameters
            obj.dot.area = pi*obj.dot.r_pix^2;
            obj.dot.pixsize = round( obj.dot_deg * obj.display.ppd);
            obj.dot.ndots = round(obj.dot_dens/(obj.dot.pixsize^2) * obj.dot.area);
            
            obj.lh = addlistener(obj,'init','PostSet',@DotGen.gen);
            
%             % Dot set
%             x = randrange(obj.dot.dotField(1), obj.dot.dotField(3),[obj.dot.ndots 1]);
%             y = randrange(obj.dot.dotField(2), obj.dot.dotField(4),[obj.dot.ndots 1]);
%             obj.pres = [x y];
            
        end
    end
    
    methods (Static)
        function gen(src,evt)
            % Dot set
            x = randrange(evt.AffectedObject.dot.dotField(1), evt.AffectedObject.dot.dotField(3),[evt.AffectedObject.dot.ndots 1]);
            y = randrange(evt.AffectedObject.dot.dotField(2), evt.AffectedObject.dot.dotField(4),[evt.AffectedObject.dot.ndots 1]);
            xymat = [x y];
            
            % Condition report
            evalin('base',[evt.AffectedObject.dispobj '.block_queue = ' int2str(evt.AffectedObject.block_count) ';']);
            evalin('base',[evt.AffectedObject.dispobj '.coh_queue = ' num2str(evt.AffectedObject.pres_coh(evt.AffectedObject.coh_count,evt.AffectedObject.block_count)) ';']);
            evalin('base',[evt.AffectedObject.dispobj '.LR_queue = ' int2str(evt.AffectedObject.LR_mat(evt.AffectedObject.coh_count,evt.AffectedObject.block_count)) ';']);
            
            % Linear motion
            if evt.AffectedObject.LR_mat(evt.AffectedObject.coh_count,evt.AffectedObject.block_count)
                lin_mot = evt.AffectedObject.motion.pfs; % Right
            else
                lin_mot = -1*evt.AffectedObject.motion.pfs; % Left
            end
            
            % Initialize
            queue = zeros([size(xymat,1) size(xymat,2) evt.AffectedObject.display.fr]);
            
            % Dots-per-frame routine
            for i = 1:evt.AffectedObject.display.fr
                % Coherence parse
                lin_index = rand(evt.AffectedObject.dot.ndots,1) < evt.AffectedObject.pres_coh(evt.AffectedObject.coh_count,evt.AffectedObject.block_count);
                % Random motion
                dt = rand(length(find(~lin_index)),1)*2*pi;
                rand_mot = repmat(evt.AffectedObject.motion.pfs, [size(dt,1) 2]).*[cos(dt) sin(dt)];
                % Redefine dot array
                xymat = [[(xymat(lin_index,1) + lin_mot) xymat(lin_index,2)];[(xymat(~lin_index,1) + rand_mot(:,1)) (xymat(~lin_index,2) + rand_mot(:,2))]];
                % Bounds check
                oob_x1 = xymat(:,1) < evt.AffectedObject.dot.dotField(1); 
                oob_x2 = xymat(:,1) > evt.AffectedObject.dot.dotField(3);
                oob_y1 = xymat(:,2) < evt.AffectedObject.dot.dotField(2);
                oob_y2 = xymat(:,2) > evt.AffectedObject.dot.dotField(4);
                % Redefine out-of-bounds
                if any(oob_x1)
                    xymat(oob_x1,1) = evt.AffectedObject.dot.dotField(3) - (evt.AffectedObject.dot.dotField(1) - xymat(oob_x1,1)); % Subtract left oob distance from right side of dotField
                end
                if any(oob_x2)
                    xymat(oob_x2,1) = xymat(oob_x2,1) - evt.AffectedObject.dot.dotField(3) + evt.AffectedObject.dot.dotField(1); % Add right oob distance to left side of dotField
                end
                if any(oob_y1)
                    xymat(oob_y1,2) = evt.AffectedObject.dot.dotField(4) - (evt.AffectedObject.dot.dotField(2) - xymat(oob_y1,2)); % Subtract bottom oob distance from top of dotField
                end
                if any(oob_y2)
                    xymat(oob_y2,2) = xymat(oob_y2,2) - evt.AffectedObject.dot.dotField(4) + evt.AffectedObject.dot.dotField(2); % Add top oob distance to bottom of dotField
                end
                % Mask with circle
                xyconv = [(xymat(:,1) - evt.AffectedObject.display.center(1)) (xymat(:,2) - evt.AffectedObject.display.center(2))]; % Move origin
                r = sqrt( xyconv(:,1).^2 + xyconv(:,2).^2 );
                circ_ind = r < evt.AffectedObject.dot.r_pix;
                % Final dot array
                queue(circ_ind,:,i) = xymat(circ_ind,:);
                queue(~circ_ind,:,i) = NaN;
            end
            
            % Update objects
            evt.AffectedObject.queue = queue;
            evalin('base',[evt.AffectedObject.dispobj '.queue = ' evt.AffectedObject.genobj '.queue;']);
            if evt.AffectedObject.coh_count == evt.AffectedObject.trial_n
                evt.AffectedObject.lh.Enabled = false; % Turn listening off once trial_n is reached
            else
                evt.AffectedObject.coh_count = evt.AffectedObject.coh_count + 1; % Stops at trial_n
            end
            
        end
    end
    
end