package Lists;

use strict;

use CGI qw(:standard);
use Config::Config;
use API::Auth;
use API::Error;
use API::ApprovedList;

sub lists {
    my $tmp_hash = shift;

    my $q = new CGI;

    my $request_method = $q->request_method();

    my $user_auth;
    $user_auth->{user_name}    = $q->param("user_name");
    $user_auth->{user_id}      = $q->param("user_id");
    $user_auth->{session_id}   = $q->param("session_id");

    my $hash = Auth::authenticate_user($user_auth);
    if ( $hash->{status} != 200 ) {
        Error::report_error($hash->{status}, $hash->{user_message}, $hash->{system_message});
    }

    if ( $request_method eq "GET" ) {
        if ( $tmp_hash->{one} eq "request" ) {
            ApprovedList::request_addition($user_auth, $tmp_hash->{two});
        } elsif ( $tmp_hash->{one} eq "requests" ) {
            ApprovedList::get_requests_received($user_auth);
        } elsif ( $tmp_hash->{one} eq "approve" ) {
            ApprovedList::process_request($user_auth, $tmp_hash->{two}, "a");
        } elsif ( $tmp_hash->{one} eq "reject" ) {
            ApprovedList::process_request($user_auth, $tmp_hash->{two}, "r");
        }
    }

    Error::report_error("400", "Not found", "Invalid request");  
}

1;

