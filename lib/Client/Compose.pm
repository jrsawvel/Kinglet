package Compose;

use strict;

use REST::Client;
use JSON::PP;
use JRS::StrNumUtils;

sub show_new_message_form {

    my $user_name    = User::get_logged_in_username(); 
    my $user_id      = User::get_logged_in_userid(); 
    my $session_id   = User::get_logged_in_sessionid(); 
    my $query_string = "/?user_name=$user_name&user_id=$user_id&session_id=$session_id";
    my $api_url      = Config::get_value_for("api_url") . '/users/' . $user_name;
    my $rest = REST::Client->new();
    $api_url .= $query_string;
    $rest->GET($api_url); 
    my $rc = $rest->responseCode();
    my $json = decode_json $rest->responseContent();
    if ( $rc >= 200 and $rc < 300 ) {
        my $t = Page->new("newmessageform");
        $t->set_template_variable("post_action", "addmessage");
        $t->display_page("Compose new message");
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

sub show_new_reply_form {
    my $tmp_hash = shift;

    my $user_name    = User::get_logged_in_username(); 
    my $user_id      = User::get_logged_in_userid(); 
    my $session_id   = User::get_logged_in_sessionid(); 
    my $query_string = "/?user_name=$user_name&user_id=$user_id&session_id=$session_id";

    my $message_id = $tmp_hash->{one}; 
    my $api_url = Config::get_value_for("api_url") . "/messages/" . $message_id;
    my $rest = REST::Client->new();
    $api_url .= $query_string;
    $rest->GET($api_url);
    my $rc = $rest->responseCode();
    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
        my $t = Page->new("newreplyform");
        $t->set_template_variable("post_action",              "addreply");
        $t->set_template_variable("reply_post",               1);
        $t->set_template_variable("reply_to_id",              $json->{message_id});
        $t->set_template_variable("reply_to_content_digest",  $json->{content_digest});
        $t->set_template_variable("reply_to_message",         _abreviate_message($json->{message_text}));
        $t->display_page("Compose reply message");
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

sub _abreviate_message {
    my $str = shift;
    $str = StrNumUtils::remove_html($str);
    if ( length($str) > 75 ) {
        $str = substr $str, 0, 75;
        $str .= " ...";
    }
    return $str;
}


1;
