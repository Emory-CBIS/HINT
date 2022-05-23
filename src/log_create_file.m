function log_create_file(logfile)
%log_create_file Creates the hcica log corresponding to the logfile
%entered. Future versions might change behavior depending on if the logfile
%already exists.

    outfile = fopen(logfile, 'wt' );
    
    fprintf(outfile, strcat('Log for hcica session on',...
        [' ', date()], ' started at: ',...
        [' ', datestr(now, 'HH_MM_SS')] ) );

end

