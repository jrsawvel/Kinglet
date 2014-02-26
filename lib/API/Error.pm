package Error;

use strict;

use JSON::PP;
use CGI qw(:standard);

sub error {
    my ($tmp_hash) = @_;
    my %hash;
    $hash{status}         = 404;
    $hash{description}    = "Not Found";
    $hash{user_message}   = "Invalid function: $tmp_hash->{function}.";
    $hash{system_message} = "It's not supported.";
    my $json_str = encode_json \%hash;
    print header('application/json', '404 Accepted');
#    print "Status: 404 Accepted\n";
#    print "Content-Type: application/json; charset=ISO-8859-1\n\n";
    print $json_str;
    exit;
}

sub report_error {
    my $status         = shift;
    my $user_message   = shift;
    my $system_message = shift;

    my %http_status_codes;
    $http_status_codes{200} = "OK";
    $http_status_codes{201} = "Created";
    $http_status_codes{204} = "No Content";
    $http_status_codes{400} = "Bad Request";
    $http_status_codes{401} = "Not Authorized";
    $http_status_codes{403} = "Forbidden";
    $http_status_codes{404} = "Not Found";
    $http_status_codes{500} = "Internal Server Error";

    my %hash;
    $hash{status}         = $status;
    $hash{description}    = $http_status_codes{$status};
    $hash{user_message}   = $user_message;
    $hash{system_message} = $system_message;

    my $json_str = encode_json \%hash;
    print header('application/json', "$status Accepted");
    print $json_str;
    exit;
}

1;

