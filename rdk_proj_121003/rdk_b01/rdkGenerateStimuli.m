function exp = rdkGenerateStimuli( params )
% rdkGenerateStimuli -- generate dots, motion patterns for RDK expt
%
% exp = rdkGenerateStimuli( params )

%----   Calls
%   rdkGenerateDots
%   rdkComputeGradient

%----   Called by
%   rdk

%----   Feature adds/bugs
%   081214  Block breaks, instruction sets, randomization of trials

%----   History
%   081213  rog adapted from earlier code.
%   081214  rog updated documention.

%-------------------------------------------------------------------------

exp = params.exp;
fr  = 0;

for b = 1:exp.nblocks
    for t = 1:exp.block(b).ntrials
        for s = 1:exp.block(b).trial(t).ndotstim
            for d = 1:exp.dual+1
                % Dot positions
                if params.control.verbose
                    fprintf('%[s]: Making set %d of stimulus %d for trial %d in block %d.', mfilename, d, s, t, b );
                end
            
                region = exp.block(b).trial(t).dotstim(s).region(d);
                dots = exp.block(b).trial(t).dotstim(s).dots(d);
                dots = rdkGenerateDots( dots, region );
                exp.block(b).trial(t).dotstim(s).dots(d) = dots;
                
                % Motion gradient
                motion = exp.block(b).trial(t).dotstim(s).motion(d);
                [ dxdy, drdt ] = rdkComputeGradient( fr, dots, motion );
                exp.block(b).trial(t).dotstim(s).motion(d).dxdy = dxdy;
                exp.block(b).trial(t).dotstim(s).motion(d).drdt = drdt;
            end % dual loop
        end % stim loop
    end % trial loop
end % block loop

return;