function [ dxdy, drdt ] = rdkComputeGradient( fr, dots, motion )
% rdkComputeGradient -- computes new motion gradient for RDK
% [ dxdy, drdt ] = rdkComputeGradient( fr, dots, motion )

%----   Calls

%---    Called by
% rdkShowStimuli

%----   Feature adds/bugs
% 081214 Frame/time dependent motion gradients.
% 081214 3D gradients
% 081214 Allow user-defined expansion/acceleration factor for 'radial_accel'

%----   History
% 081213 rog modified from earlier version of non-structured code.
% 081214 rog tested motion modes.  All work as intended.
% 090129 rog modified to allow temporal modulation of motion modes.

%--------------------------------------------------------------------------

% motion = dotstim.motion;
% dots   = dotstim.dots;

if ~strcmp( motion.time_mod_mode, 'none' )
    switch motion.time_mod_mode
        case '2-phase'
             fr_in_cycle = mod( fr, motion.time_mod_period_fr ) + 1;
            
            % If current frame in cycle is greater than period times duty cycle,
            % change to phase 2
            if fr_in_cycle > floor( motion.time_mod_period_fr * motion.time_mod_duty_cycle )
                motion.time_mod_phase = 2;                               
            else
                motion.time_mod_phase = 1;
            end
        case '4-phase'
            fr_in_cycle = mod( fr, motion.time_mod_period_fr ) + 1;
%             fr_dur_phase = mod( fr, motion.time_mod_period_fr*2 ) + 1;
            
            if fr_in_cycle > floor( motion.time_mod_period_fr * motion.time_mod_duty_cycle )
                motion.time_mod_phase = 2;
            else
%                 % Add conditional test here to switch sign of motion.mdir
%                 % if forward motion cycle occurred last time
%                 if fr_dur_phase > floor( motion.time_mod_period_fr );
%                     motion.mdir = -1*motion.mdir;
%                 end
                motion.time_mod_phase = 1;
            end   
    end
end

% if motion.time_mod_phase == 1 % On-phase
%     motion_it = 2; % 1 iteration
%     
% elseif motion.time_mod_phase == 2 % Off-phase
%     
%     dot_index = rand(dots.ndots,1) < motion.coh;
%     coh(1).ind = find(dot_index); % Coherent dot indices
%     coh(2).ind = find(~dot_index); % Incoherent dot indices
%     
%     motion_it = 2; % 2 iterations
%     
% end

dot_index = rand(dots.ndots,1) < motion.coh(motion.time_mod_phase);
coh(1).ind = find(dot_index); % Coherent dot indices
coh(2).ind = find(~dot_index); % Incoherent dot indices    

% Initialize
dxdy = zeros( dots.ndots, dots.dimensionality);
drdt = zeros( dots.ndots, dots.dimensionality);

for motion_ind = 1:2

    switch motion.mode{ motion_ind }

        case 'linear_constant'
            v = [ cos( motion.direction_rads ) sin( motion.direction_rads ) ] * motion.pix_per_fr;
            dxdy(coh(motion_ind).ind, :) = repmat( v, [ length(coh(motion_ind).ind) 1 ] ) .* [ motion.mdir(coh(motion_ind).ind,1) motion.mdir(coh(motion_ind).ind,1) ];
            dt = atan2( dxdy(:,2), dxdy(:,1)+eps );

            new_xy = dots.xy(coh(motion_ind).ind,:) + dxdy(coh(motion_ind).ind,:);
            [new_r, new_t] = rect2polar( new_xy(:,1), new_xy(:,2) );
            drdt(coh(motion_ind).ind, :) = [ new_r new_t ] - dots.rt(coh(motion_ind).ind,:);
        case 'radial_constant'
            cs = [ cos( dots.rt((coh(motion_ind).ind),2)) sin(dots.rt((coh(motion_ind).ind),2) ) ];
            dr = motion.pix_per_fr * motion.mdir((coh(motion_ind).ind),1);            % change in radius per frame (pixels)
            dxdy(coh(motion_ind).ind, :) = cs .* [ dr dr ]; % change in x and y per frame (pixels)
            drdt(coh(motion_ind).ind, :) = [ dr zeros( size(dr) ) ];
        case 'radial_accel'
            try
                dots.expand_factor = dots.rt(coh(motion_ind).ind,1)/max(dots.rt(coh(motion_ind).ind,1));
                cs = [ cos( dots.rt((coh(motion_ind).ind),2) ) sin( dots.rt((coh(motion_ind).ind),2) ) ];

                dr = motion.pix_per_fr * motion.mdir((coh(motion_ind).ind),1).*dots.expand_factor;            % change in radius per frame (pixels)
                dxdy(coh(motion_ind).ind, :) = [dr dr] .* cs;       % change in x and y per frame (pixels)
                drdt(coh(motion_ind).ind, :) = [ dr zeros( size(dr) ) ];
            catch
%                motion.coh
%                motion.time_mod_phase
%                motion_ind
%                coh
%                length(coh(motion_ind).ind)
            end
        case 'rotate_const_angle'
            %----   Compute rotational factor per frame
            dt = motion.rot_rads_per_fr;

            %----   Rotate coord by dt
            if motion.mdir(1) > 0
                xy_new = dots.xy(coh(motion_ind).ind,:)*[ cos( dt ) -sin( dt ); sin( dt ) cos( dt ) ];
                %.*[ motion.mdir((coh(motion_ind).ind),1) motion.mdir((coh(motion_ind).ind),1) ];
            else
                xy_new = dots.xy(coh(motion_ind).ind,:)*[ cos( dt ) -sin( dt ); sin( dt ) cos( dt ) ]'; % Transposed
            end
            %----   Calculate delta x, y
            dxdy(coh(motion_ind).ind, :) = xy_new - dots.xy(coh(motion_ind).ind,:);

            [ dr, dt ] = rect2polar( dxdy((coh(motion_ind).ind),1), dxdy((coh(motion_ind).ind),2) );
            drdt(coh(motion_ind).ind, :) = [ dr dt ];
        case 'rotate_const_lin'
            %----   Compute rotational factor per frame
            [~,t] = rect2polar(dots.xy(coh(motion_ind).ind,1),dots.xy(coh(motion_ind).ind,2)); % Theta values
            x_orig = dot(dots.xy(coh(motion_ind).ind,:),[ cos( t ) sin( t )],2); % Rotate x-coord back to origin by theta
            if ~isempty(x_orig)
                dt = repmat(motion.pix_per_fr,[length(x_orig) 1]);
                %----   Rotate coord by dt
                if motion.mdir(1) > 0 % Counter-clockwise
                    xy_orig = [x_orig dt]; % Add linear displacement
                    %.*[ motion.mdir((coh(motion_ind).ind),1) motion.mdir((coh(motion_ind).ind),1) ];
                else % Clockwise
                    xy_orig = [x_orig -1*dt]; % Subtract linear displacement
                end          
                xy_new = [dot(xy_orig,[cos(t) -sin(t)],2), dot(xy_orig,[sin( t ) cos( t ) ],2)]; % Rotate back (with displacement) by theta (one set of coordinates at a time by dot product, then cat)
                %----   Calculate delta x, y
                dxdy(coh(motion_ind).ind, :) = xy_new - dots.xy(coh(motion_ind).ind,:);
            end
            [ dr, dt ] = rect2polar( dxdy((coh(motion_ind).ind),1), dxdy((coh(motion_ind).ind),2) );
            drdt(coh(motion_ind).ind, :) = [ dr dt ];
        case 'random'
            dt = rand( length(coh(motion_ind).ind), 1 )*2*pi;
            cs = [ cos(dt) sin(dt) ];
            rr = motion.pix_per_fr * ones( length(coh(motion_ind).ind) , 2);
            dxdy(coh(motion_ind).ind, :) = rr.*cs; 

            new_xy = dots.xy(coh(motion_ind).ind,:) + dxdy(coh(motion_ind).ind,:);
            [new_r, new_t] = rect2polar( new_xy(:,1), new_xy(:,2) );
            drdt(coh(motion_ind).ind, :) = [ new_r new_t ] - dots.rt(coh(motion_ind).ind,:);
        otherwise
            error('motion_mode not specified properly.');
    end

end

return