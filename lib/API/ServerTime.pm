package ServerTime;

use strict;

use Time::Local;
use CGI qw(:standard);
use JSON::PP;

sub get_server_time {
    my %hash;
    $hash{server_epoch_seconds} = time();
    $hash{status}           = 200;
    $hash{description}      = "OK";
    my $json_str = encode_json \%hash;
    print header('application/json', '200 Accepted');
    print $json_str;
    exit;
}

1;
