package LogoutUser;

use strict;
use warnings;

use REST::Client;
use JSON::PP;

sub logout {

    my $user_name    = User::get_logged_in_username(); 
    my $user_id      = User::get_logged_in_userid(); 
    my $session_id   = User::get_logged_in_sessionid(); 
    my $query_string = "/?user_name=$user_name&user_id=$user_id&session_id=$session_id";

    my $api_url = Config::get_value_for("api_url") . "/users/" . $user_name . "/logout";
    my $rest = REST::Client->new();
    $api_url .= $query_string;
    $rest->GET($api_url);

    my $rc = $rest->responseCode();

    my $json = decode_json $rest->responseContent();

    if ( $rc >= 400 and $rc < 500 ) {
        Page->report_error("user", "$json->{user_message}", $json->{system_message});
    } elsif ( $rc >= 200 and $rc < 300 ) {
        my $q = new CGI;

        my $cookie_prefix = Config::get_value_for("cookie_prefix");
        my $cookie_domain = Config::get_value_for("email_host");

        my $c1 = $q->cookie( -name => $cookie_prefix . "userid",                -value => "0", -path => "/", -expires => "-10y", -domain => ".$cookie_domain");
        my $c2 = $q->cookie( -name => $cookie_prefix . "username",              -value => "0", -path => "/", -expires => "-10y", -domain => ".$cookie_domain");
        my $c3 = $q->cookie( -name => $cookie_prefix . "sessionid",             -value => "0", -path => "/", -expires => "-10y", -domain => ".$cookie_domain");
        my $c4 = $q->cookie( -name => $cookie_prefix . "current",               -value => "0", -path => "/", -expires => "-10y", -domain => ".$cookie_domain");

        my $url = Config::get_value_for("home_page"); 
        print $q->redirect( -url => $url, -cookie => [$c1,$c2,$c3,$c4] );
    } else  {
        Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API.");
    }
}

1; 
