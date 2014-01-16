package AddMessage;

use strict;
use REST::Client;
use JSON::PP;

sub add_message {
    my $q = new CGI;
    my $message_text = $q->param("message_text");

    my $user_name    = User::get_logged_in_username(); 
    my $user_id      = User::get_logged_in_userid(); 
    my $session_id   = User::get_logged_in_sessionid(); 

    my $headers = {
        'Content-type' => 'application/x-www-form-urlencoded'
    };

    # set up a REST session
    my $rest = REST::Client->new( {
           host => Config::get_value_for("api_url"),
    } );

    my %hash;
    $hash{message_text} = $message_text;
    my $json_str = encode_json \%hash;

    # then we have to url encode the params that we want in the body
    my $pdata = {
        'json'       => $json_str,
        'user_name'  => $user_name,
        'user_id'    => $user_id,
        'session_id' => $session_id,
    };
    my $params = $rest->buildQuery( $pdata );

    # but buildQuery() prepends a '?' so we strip that out
    $params =~ s/\?//;

    # then sent the request:
    # POST requests have 3 args: URL, BODY, HEADERS
    $rest->POST( "/messages" , $params , $headers );

    my $rc = $rest->responseCode();

    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
        my $url = Config::get_value_for("home_page");
        print $q->redirect( -url => $url);
        exit;
    } elsif ( $rc >= 400 and $rc < 500 ) {
        my $t = Page->new("errorpage");
        $t->set_template_variable("post_action", "addmessage");
        $t->set_template_variable("errmsg", "Error: $json->{description} - $json->{user_message}");
        $t->set_template_variable("message_text",    $json->{message_text});
        $t->display_page("Message error"); 
    } else  {
        Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API.");
    }
}

sub add_reply {
    my $q = new CGI;
    my $message_text = $q->param("message_text");
    my $reply_to_id  = $q->param("reply_to_id");
    my $reply_to_content_digest = $q->param("reply_to_content_digest");

    my $user_name    = User::get_logged_in_username(); 
    my $user_id      = User::get_logged_in_userid(); 
    my $session_id   = User::get_logged_in_sessionid(); 

    my $headers = {
        'Content-type' => 'application/x-www-form-urlencoded'
    };

    # set up a REST session
    my $rest = REST::Client->new( {
           host => Config::get_value_for("api_url"),
    } );

    my %hash;
    $hash{message_text}             = $message_text;
    $hash{reply_to_id}              = $reply_to_id;
    $hash{reply_to_content_digest} = $reply_to_content_digest;
    my $json_str = encode_json \%hash;

    # then we have to url encode the params that we want in the body
    my $pdata = {
        'json' => $json_str,
        'user_name'  => $user_name,
        'user_id'    => $user_id,
        'session_id' => $session_id,
    };
    my $params = $rest->buildQuery( $pdata );

    # but buildQuery() prepends a '?' so we strip that out
    $params =~ s/\?//;

    # then sent the request:
    # POST requests have 3 args: URL, BODY, HEADERS
    $rest->POST( "/messages/" . $reply_to_id . "/replies" , $params , $headers );

    my $rc = $rest->responseCode();

    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
#        my $url = Config::get_value_for("home_page") . "/replies/" . $reply_to_id;
        my $url = Config::get_value_for("home_page");
        print $q->redirect( -url => $url); 
        exit;
    } elsif ( $rc >= 400 and $rc < 500 ) {
        my $t = Page->new("errorpage");
        $t->set_template_variable("post_action", "addreply");
        $t->set_template_variable("reply_post", 1);
        $t->set_template_variable("reply_to_id",  $reply_to_id);
        $t->set_template_variable("reply_to_content_digest",  $reply_to_content_digest);
        $t->set_template_variable("errmsg", "Error: $json->{description} - $json->{user_message}");
        $t->set_template_variable("message_text",    $json->{message_text});
        $t->display_page("Message error"); 
    } else  {
        Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API. $json->{user_message} - $json->{system_message} ");
    }
}

1;

