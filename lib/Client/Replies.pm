package Replies;

use strict;

use REST::Client;
use JSON::PP;

sub show_replies {
    my $tmp_hash = shift;

    my $user_name    = User::get_logged_in_username(); 
    my $user_id      = User::get_logged_in_userid(); 
    my $session_id   = User::get_logged_in_sessionid(); 
    my $query_string = "/?user_name=$user_name&user_id=$user_id&session_id=$session_id";

    # get the original message that started the discussion thread
    my $message_id = $tmp_hash->{one}; 
    my $api_url = Config::get_value_for("api_url") . "/messages/" . $message_id;
    my $rest = REST::Client->new();
    $api_url .= $query_string;
    $rest->GET($api_url);
    my $rc = $rest->responseCode();
    my $json = decode_json $rest->responseContent();

    if ( $rc >= 400 and $rc < 500 ) {
        if ( $rc == 401 ) {
            my $t = Page->new("notloggedin");
            $t->display_page("Login");
        } else {
            Page->report_error("user", "$json->{user_message}", $json->{system_message});
        }
    } 

    # get reply messages
    if ( $rc >= 200 and $rc < 300 ) {
        my $tmp_hash = shift;

        my $messages_api_url = Config::get_value_for("api_url") . "/messages/" . $message_id . "/replies";

        my $rest = REST::Client->new();
        $messages_api_url .= $query_string;
        $rest->GET($messages_api_url);

        $rc = $rest->responseCode();
        my $json_replies = decode_json $rest->responseContent();

        if ( $rc >= 400 and $rc < 500 ) {
            Page->report_error("user", "$json_replies->{user_message}", $json_replies->{system_message});
        } elsif ( $rc >= 200 and $rc < 300 ) {
            # display original message and its replies
            my $t = Page->new("replies");
            $t->set_template_variable("cgi_app",       "");
            $t->set_template_variable("message_id",     $json->{message_id});
            $t->set_template_variable("parent_id",      $json->{parent_id});
            $t->set_template_variable("message_text",   $json->{message_text});
            $t->set_template_variable("created_date",   $json->{created_date});
            $t->set_template_variable("author_name",    $json->{author_name});
            $t->set_template_variable("reply_count_header",    $json->{reply_count});
            $t->set_template_loop_data("stream_loop", $json_replies->{messages});
            $t->display_page("Replies for $json->{message_id}"); 
        } else  {
            Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API.");
        }
    }else  {
        Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API.");
    }
}

1;

