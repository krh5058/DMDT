function dots = rdkGenerateDots( dots, bounds )
% rdkGenerateDots -- generates dot pattern for rdk experiment
%
% dots = rdkGenerateDots( dotstim )

%----   Calls
% randrange

%----   Called by
% rdkGenerateStimuli
% rdkShowStimuli

%----   Feature adds/bugs

%----   History
%   081213 rog adapted from old code.

%--------------------------------------------------------------------------

% dots = dotstim.dots;
% bounds = dotstim.region;

switch dots.distrib
    case 'polar'
        r = dots.rt(:, 1);
        t = dots.rt(:, 2);       
        r( dots.out_index ) = randrange( bounds.rminmax_pix(1), bounds.rminmax_pix(2), [ dots.nout 1] );      
        t( dots.out_index ) = randrange( bounds.tminmax(1), bounds.tminmax(2), [ dots.nout 1]);
        
        [ x, y ] = polar2rect( r(dots.out_index), t(dots.out_index) );
                    
        dots.xy( dots.out_index, : ) = [ x y ];

        dots.rt = [ r t ];
        
        dots.nout = 0;
        dots.out_index = 0;
    case 'rect'
        x = randrange( bounds.hminmax_pix(1), bounds.hminmax_pix(2), [ dots.nout 1] );
        y = randrange( bounds.vminmax_pix(1), bounds.vminmax_pix(2), [ dots.nout 1] );
        
        dots.xy(dots.out_index, :) = [ x y ];
        [ r, t ] = rect2polar( dots.xy(:,1), dots.xy(:,2) );
        dots.rt = [ r t ];
        
        dots.nout = 0;
        dots.out_index = 0;
    otherwise
        error('dots distrib mode misspecified.\n');
end % switch
return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
