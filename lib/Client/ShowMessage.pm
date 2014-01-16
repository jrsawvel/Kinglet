package ShowMessage;

use strict;
use REST::Client;
use JSON::PP;

sub show_message {
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
        my $t = Page->new("messagepost");
        $t->set_template_variable("cgi_app",       "");
        $t->set_template_variable("message_id",     $json->{message_id});
        $t->set_template_variable("parent_id",      $json->{parent_id});
        $t->set_template_variable("message_text",   $json->{message_text});
        $t->set_template_variable("created_date",   $json->{created_date});
        $t->set_template_variable("author_name",    $json->{author_name});
        $t->set_template_variable("reply_count",    $json->{reply_count});
        $t->display_page("Message $json->{message_id} by $json->{author_name}"); 
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


# returned json :
# {
#    "status":202,
#    "authorname":"JB",
#    "authorid":1,
#    "createddate":"2013-11-21 00:33:56",
#    "markupcontent":"NIU plays at UT tonight. #sports #football #toledo",
#    "formattedcontent":"NIU plays at UT tonight. <a href=\"/tag/sports\">#sports</a> <a href=\"/tag/football\">#football</a> <a href=\"/tag/toledo\">#toledo</a>"
# }


# {
#    "status":400,
#    "description":"bad_request",
#    "user_message":"Error: You must enter text.",
#    "markupcontent":""
# }

1;
