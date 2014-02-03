function out_params = setParamDefaults( params )

if nargin < 1
    disp( sprintf('[%s]: No param struct specified.', mfilename ) );
end

out_params = params;

disp(sprintf('[%s]: Setting default parameters.', mfilename ) );

%---    Display
out_params.display.screens = Screen('Screens');
out_params.display.screenNumber = max( out_params.display.screens );

[width_pix, height_pix]=Screen('WindowSize', out_params.display.screenNumber);
out_params.display.rect = [0  0 width_pix height_pix];

out_params.display.black = 1;
out_params.display.white = 256;
out_params.display.width_cm = 39;
[out_params.display.center(1), out_params.display.center(2)] = RectCenter( out_params.display.rect );

out_params.display.view_dist_cm = 60;
out_params.display.fps = 60;
out_params.display.ifi = 1/out_params.display.fps;

out_params.display.update_hz    = 60; % Redundant
out_params.display.waitframes   = 1;
out_params.display.ppd = pi * (width_pix) / atan(out_params.display.width_cm/out_params.display.view_dist_cm/2) / 360;

%---    Time parameters
time.trial_secs = 10;
time.nframes = round( time.trial_secs * out_params.display.update_hz/out_params.display.waitframes );

out_params.time = time;

%---    Motion
out_params.motion.deg_per_sec = 5;
out_params.motion.direction_mode  = 'uniform'; %{'opposing', 'uniform'}
out_params.motion.mode = 'linear_constant'; %{'radial_constant', 'radial_accel', 'random', 'linear_constant' }
out_params.motion.frame_dependent = 0;
out_params.motion.rot_rads_per_fr = pi/120;
out_params.motion.trans_dir_rads = pi/8;  % horizontal
out_params.motion.fig_bg_mode = 'bgnd'; % {'figure', 'bgnd', 'fig+bgnd'}

%---    Dots

out_params.dots.density    = .01; % not valid, just a placeholder
out_params.dots.distrib    = 'polar'; %{'polar', 'rect'}
out_params.dots.f_kill     = 0.01;
out_params.dots.differentcolors = 0;
out_params.dots.differentsizes  = 0;
out_params.dots.deg             = 0.1;
out_params.dots.dimensionality  = 2;
out_params.dots.shape           = 1;  %{ 0, 1, 2 }

out_params.dots.pix             = round( out_params.dots.deg * out_params.display.ppd );
out_params.dots.ndots           = round( out_params.dots.density * width_pix * height_pix/(out_params.dots.pix^2) );

%----   dotpatch params
out_params.dotpatch.mode      = 'fixed';  % {'fixed', 'sine_radius', 'radar_theta'}
out_params.dotpatch.shape     = 'rectangular' %{'rectangular', 'circular', 'annular'}
out_params.dotpatch.n_dotpatches = 1;
out_params.dotpatch.rminmax_deg   = [ 5 10 ];
out_params.dotpatch.tminmax       = [ 0 2*pi ];
out_params.dotpatch.hminmax_deg   = [ -10 10 ];
out_params.dotpatch.vminmax_deg   = [ -10 10 ];
out_params.dotpatch.fr_per_cyc    = 180;
out_params.dotpatch.wedge_rads    = pi/4;

%----   Bounds params
out_params.bounds.mode     = 'polar';  %{'polar', 'rectangular'}
out_params.bounds.rminmax_deg  = [ 5 10 ];
out_params.bounds.tminmax  = [ 0 2*pi ];
out_params.bounds.hminmax_deg  = [ -10 10 ];
out_params.bounds.vminmax_deg  = [ -10 10 ];

% switch out_params.bounds.mode
%     case 'polar'
%         out_params.bounds.rminmax_pix = out_params.bounds.rminmax_deg * out_params.display.ppd;
% 
%         tmin        = 0;
%         tmax        = 2*pi;
%         out_params.bounds.tminmax = [ 0 2*pi ];
% 
%         out_params.bounds.hminmax_pix = out_params.bounds.hminmax_deg * out_params.display.ppd;
%         out_params.bounds.vminmax_pix = out_params.bounds.vminmax_deg * out_params.display.ppd;
% 
%         hmin = 0;
%         hmax = 0;
%         vmin = 0;
%         vmax = 0;
%     case 'rectangular'
%         out_params.bounds.rminmax_pix = [ 0 0 ];
%         bounds.tminmax = [ 0 0 ];
%         bounds.hminmax_pix = bounds.hminmax_deg * out_params.display.ppd;
%         bounds.vminmax_pix = bounds.vminmax_deg * out_params.display.ppd;
% 
%         hmin = -display.ppd*.10;
%         hmax = abs( hmin );
%         vmin = -max_d/2 * display.ppd;
%         vmax = abs( vmin );
%     otherwise
%         error('bounds_mode misspecified.');
% end

%----   Fixation params
out_params.fix.mode    = 'on';
out_params.fix.deg     = .15;
out_params.fix.center  = [ 0 0 ];
out_params.fix.pix     = out_params.fix.deg * out_params.display.ppd;
out_params.fix.coord   = [ out_params.display.center - out_params.fix.pix  out_params.display.center + out_params.fix.pix ];
out_params.fix.color   = uint8( out_params.display.white );

return;
