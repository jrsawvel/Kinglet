package Function;

use strict;
use warnings;

sub do_invalid_function {
    my ($tmp_hash) = @_;
    my $function = $tmp_hash->{function};
    Page->report_error("user", "Client Invalid function: $function", "It's not supported.");
    exit;
}

sub get_cgi_params_from_path_info {
    my @param_names = @_;
    my %params;
    my $path_info = $ENV{REQUEST_URI}; # with nginx confi, using this instead of PATH_INFO

    my @values = ();
    # remove dummy .html extension if exists
    if ( $path_info ) {
        $path_info =~ s/\.html//g; 
        $path_info =~ s/\/api\/v1//g;
        # if url = /cgi-bin/comments.pl/30/123/0/1, path_info will equal /30/123/0/1
        # this substitution removes leading forward slash before the 30.
        $path_info =~ s/\/// if ( $path_info );
        @values = split(/\//, $path_info);
    }
    my $len = @values;
    for (my $i=0; $i<$len; $i++) {
        $params{$param_names[$i]} = $values[$i];
    }
    return %params;
}

1;

