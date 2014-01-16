package Homepage;

use strict;
use REST::Client;
use JSON::PP;
use JRS::StrNumUtils;

sub show_homepage {
    my $tmp_hash = shift;

    my $user_name    = User::get_logged_in_username(); 
    my $user_id      = User::get_logged_in_userid(); 
    my $session_id   = User::get_logged_in_sessionid(); 
    my $query_string = "/?user_name=$user_name&user_id=$user_id&session_id=$session_id";

    my $messages_api_url = Config::get_value_for("api_url") . "/messages";

    my $page_num = 1;
    if ( StrNumUtils::is_numeric($tmp_hash->{one}) ) {
        $page_num = $tmp_hash->{one};
        if ( $page_num > 1 ) {
            $messages_api_url .= "/page/$page_num";
        }
    }

    my $rest = REST::Client->new();
    $messages_api_url .= $query_string;
    $rest->GET($messages_api_url);

    my $rc = $rest->responseCode();
    my $json = decode_json $rest->responseContent();

    if ( $rc >= 400 and $rc < 500 ) {
        if ( $rc == 401 or $rc == 403 ) {
            my $t = Page->new("notloggedin");
            $t->display_page("Login");
        } else {
            Page->report_error("user", "$json->{user_message}", $json->{system_message});
        }
    } elsif ( $rc >= 200 and $rc < 300 ) {
        _display_homepage_stream($json->{messages}, $page_num, $json->{next_link_bool});
    } else  {
        Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API.");
    }
}

sub _display_homepage_stream {
    my $messages = shift;
    my $page_num = shift;
    my $next_link_bool = shift;

    my $t = Page->new("homepage");
    $t->set_template_loop_data("stream_loop", $messages);

    my $max_items_on_main_page = Config::get_value_for("max_entries_on_page");

    my $len = @$messages;
 
    if ( $page_num == 1 ) {
        $t->set_template_variable("not_page_one", 0);
    } else {
        $t->set_template_variable("not_page_one", 1);
    }

    if ( $len >= $max_items_on_main_page && $next_link_bool ) {
        $t->set_template_variable("not_last_page", 1);
    } else {
        $t->set_template_variable("not_last_page", 0);
    }

    my $previous_page_num = $page_num - 1;
    my $next_page_num     = $page_num + 1;

    my $next_page_url     = "/stream/$next_page_num";
    my $previous_page_url = "/stream/$previous_page_num";

    $t->set_template_variable("next_page_url", $next_page_url);
    $t->set_template_variable("previous_page_url", $previous_page_url);

    $t->display_page("Home page");
}

1;
