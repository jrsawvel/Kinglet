package Approval;

use strict;
use REST::Client;
use JSON::PP;

sub request_approval {
    my $q = new CGI;
    my $recipient_user_name = $q->param("recipient");

    my $user_name    = User::get_logged_in_username(); 
    my $user_id      = User::get_logged_in_userid(); 
    my $session_id   = User::get_logged_in_sessionid(); 
    my $query_string = "/?user_name=$user_name&user_id=$user_id&session_id=$session_id";

    my $api_url = Config::get_value_for("api_url") . "/lists/request/" . $recipient_user_name;

    my $rest = REST::Client->new();
    $api_url .= $query_string;
    $rest->GET($api_url);

    my $rc = $rest->responseCode();

    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
        my $t = Page->new("request");
        $t->set_template_variable("recipient_user_name", $recipient_user_name);
        $t->display_page("Request Approval");
    } elsif ( $rc >= 400 and $rc < 500 ) {
        if ( $rc == 401 ) {
            my $t = Page->new("notloggedin");
            $t->display_page("Login");
        } else {
            Page->report_error("user", "$json->{user_message}", $json->{system_message});
        }
    } else  {
        Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API.");
    }
}

sub show_requests_received {
    my $user_name    = User::get_logged_in_username(); 
    my $user_id      = User::get_logged_in_userid(); 
    my $session_id   = User::get_logged_in_sessionid(); 
    my $query_string = "/?user_name=$user_name&user_id=$user_id&session_id=$session_id";

    my $api_url = Config::get_value_for("api_url") . "/lists/requests";

    my $rest = REST::Client->new();
    $api_url .= $query_string;
    $rest->GET($api_url);

    my $rc = $rest->responseCode();

    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
        my $t = Page->new("showrequests");
        $t->set_template_loop_data("requests_loop", $json->{requests});
        $t->display_page("List of received approval requests");
    } elsif ( $rc >= 400 and $rc < 500 ) {
        if ( $rc == 401 ) {
            my $t = Page->new("notloggedin");
            $t->display_page("Login");
        } else {
            Page->report_error("user", "$json->{user_message}", $json->{system_message});
        }
    } else  {
        Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API.");
    }
}

sub approve_request {
    my $tmp_hash = shift;  
    _process_request("approve", $tmp_hash->{one}); 
}

sub reject_request {
    my $tmp_hash = shift;  
    _process_request("reject", $tmp_hash->{one}); 
}


sub _process_request {
    my $request_type         = shift;
    my $user_name_to_process = shift;
  
    my $q = new CGI;

    my $user_name    = User::get_logged_in_username(); 
    my $user_id      = User::get_logged_in_userid(); 
    my $session_id   = User::get_logged_in_sessionid(); 
    my $query_string = "/?user_name=$user_name&user_id=$user_id&session_id=$session_id";

    my $api_url = Config::get_value_for("api_url") . "/lists/" . $request_type . "/" . $user_name_to_process;

    my $rest = REST::Client->new();
    $api_url .= $query_string;
    $rest->GET($api_url);

    my $rc = $rest->responseCode();

    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
        my $url = Config::get_value_for("home_page") . "/requestsreceived";
        print $q->redirect( -url => $url);
        exit;
    } elsif ( $rc >= 400 and $rc < 500 ) {
        if ( $rc == 401 ) {
            my $t = Page->new("notloggedin");
            $t->display_page("Login");
        } else {
            Page->report_error("user", "$json->{user_message}", $json->{system_message});
        }
    } else  {
        Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API.");
    }
}

1;
