function params = rdkGetSetParams_beta( param_fn, control )
% rdkGetSetParams -- Get user params, set contingent ones
%
% params = rdkGetSetParams

%----   Feature adds/bugs
% 081214 Set display params via separate routine.
% 081214 Set control params via GUI menu.
% 081214 Mechanism for efficient condition setting like PowerDiva
% 081214 Get user specified params, separate routine to calculate
%        dependencies

%----   History
% 081214    rog wrote as hack to get data stucture oriented program up and
%           running. Added 'wedge' region.shape.
% 090112    rog modified to separate out user-defined from
%           computed/dependent parameters

params = [];

%----   Control
params.control = control;

%----   Experiment
if params.control.verbose
    fprintf('[%s]: Setting experiment params. \n', mfilename );
end

%exp.generate_mode = 'generate_online'; %{'generate_online', 'generate_frame_arrays'}
exp.dual = 1; % 0/1
% exp.type = 'demo'; %{'psychophysics', 'fmri', 'vep', 'demo'}
exp.nblocks = 1; % Not used

% Coherence presentation (quick-hack)
z = zeros([3 2 2]);
x = [.80 .72;.80 .64;.80 .48]; % 3 conditions
x2 = [.8 0;.8 0;.8 0]; 
z(:,1,:) = x;
z(:,2,:) = x2;
% y = [z(:,2,:) z(:,1,:)]; % Reversed eyes
% z = [z; y]; 
% % z = [z;z;z;z;z]; % Five replications
% order = Shuffle(1:length(z));
% pres = [z(Shuffle(1:length(z)),:,:);z(Shuffle(1:length(z)),:,:);z(Shuffle(1:length(z)),:,:);z(Shuffle(1:length(z)),:,:);z(Shuffle(1:length(z)),:,:)]; % Five replications, randomized within block and counterbalanced across blocks
%     z = zeros([3 2 2]);
%     x = [1 1; 1 1; 1 1];
%     z(:,1,:) = x;
%     z(:,2,:) = x;
%     pres = z;
exp.pres = z;
exp.ntrials = size(exp.pres,1);
params.exp = exp;

%----   Display
display = rdkGetDisplayParams( params );

%----   Block
block.ntrials = 1;
% block.length_type = 'fixed'; %{'fixed', 'user_resp', 'threshold'}

%----   Trial
% trial.fig_bg_mode = 'fig'; % {'fig', 'bgnd', 'fig+bgnd'}
trial.duration_secs = 20;
trial.duration_fr = round( trial.duration_secs * display.fps );
trial.ndotstim = 1;

% Parameter SpecificatSion
%----   Fixation
fix_param = ...
    {'off','off'; ... % Mode
    .15, .15; ... % Degree
    [0 0], [0 0]; ... % Center
    uint8(display.white), uint8(display.white)}; % Color

%----   Region
region_param = ...
    {'none','none'; ... %{'none', 'exp_ring', 'rot_wedge', 'trans'}
    .5, .5; ... % Compute size of region based on this -- FIX
    'circle', 'circle'; ... %{'annulus', 'wedge', 'circle', 'rect','none'}
    [ 0 10 ], [ 0 10 ]; ... % Annulus ring: [min max] of degrees
    [ 0 2*pi ], [ 0 2*pi ]; ... % Theta: [min max] of wedge size
    [ -10 10 ], [ -10 10 ]; ... % Height: [min max] in degrees
    [ -10 10 ], [ -10 10 ]}; % Width: [min max] in degrees

%----  Dots
dot_param = ...
    {.1,.1; ... % Density
    .01, .01; ... % Kill fraction
    0, 0; ... % Different colors (0/1)
    0, 0; ... % Different sizes (0/1)
    .1, .1; ... % Degree
    2, 2; ... % Dimensionality
    1, 1}; % Shape
    
%----  Motion
motion_param = ...
    {4 ,4; ... % Degree per second
    'uniform', 'uniform'; ... %{'opposing', 'uniform'}
    pi, pi; ... % Horizontal
    'uniform', 'uniform'; ... % Direction distribution
    {'linear_constant', 'random'}, {'linear_constant', 'random'}; ... %{'radial_constant', 'radial_accel', 'random', 'linear_constant', 'rotate_const_angle' , 'rotate_const_lin'}
    pi/360, pi/360; ... % Rotations (rad) per frame, for constant angular speed
    'uniform', 'uniform'; ... % Speed distribution
    [0 1], [0 1]; ... % Coherence for both-phases 
    '2-phase', '2-phase'; ... %{'none', '2-phase', '4-phase'}
    50, 50; ... % Frames per period
    0.5, 0.5; ... % Duty cycle
    1, 1}; % Starting motion index
    
dotstim = [];

% For stereo or non-stereo mode
for d = 1:(exp.dual)+1
    
    if params.control.verbose
        fprintf('[%s]: Setting fixation params.', mfilename );
    end
    
    %----   Fixation
    fix(d).mode    = fix_param{1,d};
    fix(d).deg     = fix_param{2,d};
    fix(d).center  = fix_param{3,d};
    fix(d).color   = fix_param{4,d};
    fix(d).pix     = fix(d).deg * display.ppd; % Conversion
    fix(d).coord   = [ display.center - fix(d).pix  display.center + fix(d).pix ];
    
    %----   Region params, specifying time and space components of each region
    if params.control.verbose
        fprintf('[%s]: Setting region params.', mfilename );
    end
    
    region(d).space_mod_mode   = region_param{1,d}; 
    region(d).space_duty_cycle = region_param{2,d};  
    region(d).shape            = region_param{3,d};
    region(d).rminmax_deg      = region_param{4,d}; 
    region(d).tminmax          = region_param{5,d};
    region(d).hminmax_deg      = region_param{6,d};
    region(d).vminmax_deg      = region_param{7,d};
    
    % %----   2nd region if fig+bdnd
    % region2.space_mod_mode  = 'none'; %{'none', 'exp_ring', 'rot_wedge', 'trans'}
    % region2.space_duty_cycle = .5;  % Compute size of region based on this -- FIX
    % region2.shape           = 'annulus'; %{'annulus', 'wedge', 'circle', 'rect','none'}
    % region2.rminmax_deg     = [ 5 7.5 ]; % Outer circle
    % region2.tminmax         = [ 0 2*pi ];
    % region2.hminmax_deg   = [ -10 10 ];
    % region2.vminmax_deg   = [ -10 10 ];
    
    if params.control.verbose
        fprintf('[%s]: Setting dot params.', mfilename );
    end    
 
    %--------   Dots
    dots(d).density            = dot_param{1,d};
    dots(d).f_kill             = dot_param{2,d};
    dots(d).differentcolors    = dot_param{3,d};
    dots(d).differentsizes     = dot_param{4,d};
    dots(d).deg                = dot_param{5,d};
    dots(d).dimensionality     = dot_param{6,d};
    dots(d).shape              = dot_param{7,d};
    
    if any(strcmp({'annulus','circle','wedge'},region(d).shape))
        dots(d).distrib            = 'polar';
    elseif any(strcmp({'rect','rect_annulus'},region(d).shape))
        dots(d).distrib            = 'rect';
    end
    
    % dots2.density           = .1;
    % dots2.distrib           = 'polar'; %{'polar', 'rect'}
    % dots2.f_kill            = 0.01;
    % dots2.differentcolors   = 0;
    % dots2.differentsizes    = 0;
    % dots2.deg               = 0.1;
    % dots2.dimensionality    = 2;
    % dots2.shape             = 1;  %{ 0, 1, 2 }
    
    %--------   Motion
    motion(d).deg_per_sec          = motion_param{1,d};
    motion(d).direction_mode       = motion_param{2,d};
    motion(d).direction_rads       = motion_param{3,d};
    motion(d).direction_distrib    = motion_param{4,d};
    motion(d).mode                 = motion_param{5,d};
    motion(d).rot_rads_per_fr      = motion_param{6,d}; %  For Constant angular speed
    motion(d).speed_distrib        = motion_param{7,d};
    motion(d).coh                  = motion_param{8,d};
    motion(d).time_mod_mode         = motion_param{9,d};
    motion(d).time_mod_period_fr    = motion_param{10,d};
    motion(d).time_mod_duty_cycle   = motion_param{11,d};
    motion(d).time_mod_phase        = motion_param{12,d};
    
    % motion2.deg_per_sec          = 1;
    % motion2.direction_mode       = 'uniform'; %{'opposing', 'uniform'}
    % motion2.direction_rads       = 0;  % horizontal
    % motion2.direction_distrib    = 'uniform';
    % motion2.mode                 = {'linear_constant','random'}; %{'radial_constant', 'radial_accel', 'random', 'linear_constant', 'rotate_const_angle', 'none' }
    % motion2.rot_rads_per_fr      = pi/360;
    % motion2.speed_distrib        = 'uniform'; %{'constant', 'random_uniform'};
    % motion2.coh                  = 1;
    % motion2.time_mod_mode        = '4-phase'; %{'none', '2-phase', '4-phase'}
    % motion2.time_mod_period_fr   = 60;
    % motion2.time_mod_duty_cycle  = 0.5;
    % motion2.time_mod_phase       = 1;

%-------------------------------------------------------------------------
%   Dependent and computed values
%-------------------------------------------------------------------------

%----   Trial



% switch trial.fig_bg_mode
%     case {'fig', 'bgnd'}
%         trial.ndotstim = 1;
%     case 'fig+bgnd'
%         trial.ndotstim = 2;
%     otherwise
%         trial.ndotstim = 1;
% end % switch trial.fig_bg_mode
% 

%----    Region

    if ~strcmp( region(d).space_mod_mode, 'none' )
        region(d).space_mod_period_s = trial.duration_secs*region(d).space_duty_cycle;% DEFAULT
        region(d).space_mod_period_fr = round( region(d).space_mod_period_s * display.update_hz );
        region(d).space_mod_rad_per_fr = 2*pi/(region(d).space_mod_period_s * display.update_hz );
    else
        region(d).space_mod_period_s = trial.duration_secs;% DEFAULT
        region(d).space_mod_period_fr = round( region(d).space_mod_period_s * display.update_hz ); % Total frames
        region(d).space_mod_rad_per_fr = 2*pi/(region(d).space_mod_period_s * display.update_hz ); % *** Why needs this calculation?
    end

    %---    Convert to pix
    region(d).rminmax_pix = floor( region(d).rminmax_deg * display.ppd );
    region(d).rminmax_static_pix = region(d).rminmax_pix;
    region(d).hminmax_pix = floor( region(d).hminmax_deg * display.ppd );
    region(d).vminmax_pix = floor( region(d).vminmax_deg * display.ppd );

    %---    ring width useful in expanding/contracting paradigms
    region(d).ring_width_pix = region(d).rminmax_pix(2)-region(d).rminmax_pix(1);


    %----   Assign default region to dotstim struct
%     dotstim.region(d) = region(d);

    % if trial.ndotstim == 2
    %     dotstim(2).region = region2;
    %     dotstim(2).region.rminmax_pix = floor( dotstim(2).region.rminmax_deg * display.ppd );
    %     dotstim(2).region.rminmax_static_pix = dotstim(2).region.rminmax_pix;
    %     dotstim(2).region.ring_width_pix = dotstim(2).region.rminmax_pix(2)-dotstim(2).region.rminmax_pix(1);
    %     dotstim(2).region.hminmax_pix = floor( dotstim(2).region.hminmax_deg * display.ppd );
    %     dotstim(2).region.vminmax_pix = floor( dotstim(2).region.vminmax_deg * display.ppd );
    % else
    %     dotstim(1).region.name = trial.fig_bg_mode;
    % end % if

    %----   Compute outer bounds for stimuli based on patches
%     max_r = zeros( trial.ndotstim, 1);
%     max_v = zeros( trial.ndotstim, 1);
%     max_h = zeros( trial.ndotstim, 1);
%     min_v = zeros( trial.ndotstim, 1);
%     min_h = zeros( trial.ndotstim, 1);

%     for s = 1:trial.ndotstim
        max_r = max( region(d).rminmax_pix );
        max_v = max( region(d).vminmax_pix );
        max_h = max( region(d).hminmax_pix );

        min_v = min( region(d).vminmax_pix );
        min_h = min( region(d).hminmax_pix );
%     end

    trial.bounds(d).rminmax_pix = max( max_r );
    trial.bounds(d).hminmax_pix = [ min( min_h ) max( max_h ) ];
    trial.bounds(d).vminmax_pix = [ min( min_v ) max( max_v ) ];

    %----   To compute region areas, it's a bit tricky
    %for s = 1:trial.ndotstim
        switch region(d).shape
            case 'circle'
                region(d).area_pix2 = pi*region(d).rminmax_pix(2)^2;
            case 'annulus'
                outerA = pi*region(d).rminmax_pix(2)^2;
                innerA = pi*region(d).rminmax_pix(1)^2;
                region(d).area_pix2 = outerA - innerA;
            case 'wedge'
                outerA = pi*region(d).rminmax_pix(2)^2;
                innerA = pi*region(d).rminmax_pix(1)^2;
                annulusArea = outerA - innerA;
                % Calculate area of annulus first, then scale by fraction of
                % theta range
                thetaFraction = (region(d).tminmax(2)-region(d).tminmax(1))/(2*pi);
                region(d).area_pix2 = annulusArea * thetaFraction;
            case 'rect'
                hside = region(d).hminmax_pix(2) - region(d).hminmax_pix(1);
                vside = region(d).vminmax_pix(2) - region(d).vminmax_pix(1);
                region(d).area_pix2 = hside * vside;
            case 'rect_annulus' %* FIX
                hsideOut = region(d).hminmax_pix(2) - region(d).hminmax_pix(1);
                vsideOut = region(d).vminmax_pix(2) - region(d).minmax_pix(1);
                region(d).area_pix2 = hsideOut * vsideOut;
            otherwise
                region(d).area_pix2 = 0;
        end
    %end

    %----   Dot stim
    if params.control.verbose
        fprintf('[%s]: Computing dependent dot params.', mfilename );
    end

    %----   Both dotstim have identical dot distributions in default mode
%     dotstim(1).dots(d) = dots(d);
    % if trial.ndotstim == 2
    %     dotstim(2).dots = dots2;
    % end

    %----   Compute ndots
%     for s = 1:trial.ndotstim
%         dots = dotstim(s).dots(d);

        dots(d).pix  = round( dots(d).deg * display.ppd );
        dots(d).ndots = round( dots(d).density/(dots(d).pix^2) * region(d).area_pix2 );

        if dots(d).differentsizes > 0
            dots(d).pix   = (1+rand(1, dots(d).ndots)*(dots(d).differentsizes-1))*dots(d).pix;
        end

        dots(d).xy              = zeros( dots(d).ndots, dots(d).dimensionality );
        dots(d).rt              = zeros( dots(d).ndots, dots(d).dimensionality );
        dots(d).nout            = dots(d).ndots;
        dots(d).out_index       = (1:dots(d).ndots)';

        if dots(d).differentcolors == 1
            dots(d).colors = uint8( round( rand( 3, dots(d).ndots )*display.white ) );
        else
            dots(d).colors = display.white;
        end
%         dotstim.dots(d) = dots(d);
%     end

    %--------   Motion
    if params.control.verbose
        fprintf('[%s]: Setting motion params.', mfilename );
    end

    %----   Computed/dependent motion params

    motion(d).pix_per_fr  = motion(d).deg_per_sec * display.ppd / display.fps;  % compute pfs

    %---    Assign defaults to dotstim
%     dotstim(1).motion = motion;

    % if trial.ndotstim == 2
    %     dotstim(2).motion = motion2;
    %     dotstim(2).motion.pix_per_fr  = dotstim(2).motion.deg_per_sec * display.ppd / display.fps;  % compute pfs
    % end

    %---    Assign motion direction vectors to each dotstim & initialize dxdy's
%     for s = 1:trial.ndotstim
        %---   Motion direction vector
        switch motion(d).direction_mode
            case 'opposing'
                motion(d).mdir = 2 * floor(rand(dots(d).ndots,1)+0.5) - 1;    % motion direction (in or out) for each dot
            case 'uniform'
                motion(d).mdir = ones( dots(d).ndots, 1);
            otherwise
                error('direction_mode specified improperly.');
        end
        motion(d).drdt   = zeros( dots(d).ndots, dots(d).dimensionality); % initialize to 0
        motion(d).dxdy   = zeros( dots(d).ndots, dots(d).dimensionality);
%     end

end
%----   Assemble data structure
dotstim.dots = dots;
dotstim.region = region;
dotstim.motion = motion;
trial.dotstim = dotstim;
trial.fix = fix;
block.trial = trial;
exp.block = block;
params.exp = exp;

params.display = display;
params.control = control;


%----   Code to plot shape of region
%rdkPlotTrialRegion( trial );

return;

