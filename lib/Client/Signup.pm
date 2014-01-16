package Signup;

use strict;
use warnings;

use REST::Client;
use JSON::PP;

sub show_signup_form {
    Page->report_error("user", "New user sign-ups are not available at the moment.", "Sorry for the inconvenience.") if !Config::get_value_for("new_user_signups_allowed");
    my $t = Page->new("signupform");
    $t->display_page("New User Sign-up Form");
}

sub create_new_user {

    my $q = new CGI;

    my %hash;
    $hash{user_name}  = $q->param("username");
    $hash{email}      = $q->param("email");
    my $json = encode_json \%hash;

    my $headers = {
        'Content-type' => 'application/x-www-form-urlencoded'
    };

    my $api_url = Config::get_value_for("api_url");
    my $rest = REST::Client->new( {
        host => $api_url,
    } );

    my $pdata = {
        'json' => $json,
    };

    my $params = $rest->buildQuery( $pdata );

    $params =~ s/\?//;

    $rest->POST( "/users" , $params , $headers );

    my $rc = $rest->responseCode();
    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
        if ( Config::get_value_for("debug_mode") ) {
            Page->report_error("system", "debug pwd=$json->{password}" , "<a href=\"/activate/$json->{user_digest}\">activate</a>.");
        } else {
            # todo Mail::send_new_account_email($email, $username, $rc[1]{USERDIGEST});
            my $t = Page->new("newaccount");
            $t->set_template_variable("newusername", $json->{user_name});
            $t->display_page("New User Sign Up");
        }
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

sub activate_account {
    my $tmp_hash = shift; # ref to hash

    my $user_digest = $tmp_hash->{one};

    my $api_url     = Config::get_value_for("api_url");
    my $rest = REST::Client->new();
    $rest->GET($api_url . '/users/activate/' . $user_digest);
 
    my $rc = $rest->responseCode();
    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
        my $t = Page->new("activateaccount");
        $t->set_template_variable("msg1", "Your account has been activated. You can now login.");
        $t->display_page("Account Enabled");
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
