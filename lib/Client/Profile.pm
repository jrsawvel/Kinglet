package Profile;

use strict;
use REST::Client;
use JSON::PP;

sub show_user {
    my $tmp_hash = shift;

    my $user_name    = User::get_logged_in_username(); 
    my $user_id      = User::get_logged_in_userid(); 
    my $session_id   = User::get_logged_in_sessionid(); 
    my $query_string = "/?user_name=$user_name&user_id=$user_id&session_id=$session_id";

    my $username_for_profile = $tmp_hash->{one};

    my $api_url = Config::get_value_for("api_url") . '/users/' . $username_for_profile;
    my $rest = REST::Client->new();
    $api_url .= $query_string;
    $rest->GET($api_url); 
    my $rc = $rest->responseCode();
    my $json = decode_json $rest->responseContent();
    if ( $rc >= 200 and $rc < 300 ) {
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

    my $deleted_user = 0;
    if ( $json->{user_status} eq "d" ) {
        $deleted_user = 1;
    }

    my $t = Page->new("showuser");
    $t->set_template_variable("cgi_app",       "");

    my $logged_in_username = User::get_logged_in_username();

    my $logged_in_user_viewing_own_profile = 0; 
    if ( $logged_in_username and ( lc($logged_in_username) eq lc($username_for_profile) )  ) {
        $t->set_template_variable("ownerloggedin", "1"); 
        $logged_in_user_viewing_own_profile = 1; 
    }

    $t->set_template_variable("profileusername"     , $json->{user_name});
#    $t->set_template_variable("creationdate"        , $json->{created_date});
    $t->set_template_variable("deleteduser"        , $deleted_user);
    $t->set_template_variable("descformat"         , $json->{desc_format});
    $t->display_page("Show User $json->{user_name}");
}

sub show_user_settings_form {
    my $user_name    = User::get_logged_in_username(); 
    my $user_id      = User::get_logged_in_userid(); 
    my $session_id   = User::get_logged_in_sessionid(); 
    my $query_string = "/?user_name=$user_name&user_id=$user_id&session_id=$session_id";

    my $api_url = Config::get_value_for("api_url") . '/users/' . $user_name;
    my $rest = REST::Client->new();
    $api_url .= $query_string;
    $rest->GET($api_url); 
    my $rc = $rest->responseCode();
    my $json = decode_json $rest->responseContent();
    if ( ($rc >= 200 and $rc < 300) and $json->{user_id} ) {
        my $t = Page->new("settings");
        $t->set_template_variable("user_name",   $json->{user_name});
        $t->set_template_variable("user_id",     $json->{user_id});
        $t->set_template_variable("email",       $json->{email});
        $t->set_template_variable("desc_markup", $json->{desc_markup});
        $t->display_page("Customize User Settings");
    } elsif ( ($rc >= 200 and $rc < 300) ) {
        Page->report_error("user", "Invalid request.", "Unable to complete action.");
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

sub customize_user {
    my $user_name    = User::get_logged_in_username(); 
    my $user_id      = User::get_logged_in_userid(); 
    my $session_id   = User::get_logged_in_sessionid(); 
    my $query_string = "/?user_name=$user_name&user_id=$user_id&session_id=$session_id";

    my $q = new CGI;
    my $email        = $q->param("email");
    my $desc_markup  = $q->param("desc_markup");

    my %hash;
    $hash{email}       = $email;
    $hash{desc_markup} = $desc_markup;
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
        'user_name' => $user_name,
        'user_id' => $user_id,
        'session_id' => $session_id,
    };
    my $params = $rest->buildQuery( $pdata );

    $params =~ s/\?//;

    $rest->PUT( "/users" , $params , $headers );

    my $rc = $rest->responseCode();
    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
        my $url = Config::get_value_for("cgi_app") . "/user/$user_name";
        print $q->redirect( -url => $url);
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

sub change_password {
    my $user_name    = User::get_logged_in_username(); 
    my $user_id      = User::get_logged_in_userid(); 
    my $session_id   = User::get_logged_in_sessionid(); 
    my $query_string = "/?user_name=$user_name&user_id=$user_id&session_id=$session_id";

    my $q = new CGI;

    my %hash;
    $hash{old_password}     = $q->param("old_password");
    $hash{new_password}     = $q->param("new_password");
    $hash{verify_password}  = $q->param("verify_password");
    $hash{user_name}        = $user_name;
    $hash{user_id}          = $user_id;
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
        'user_name' => $user_name,
        'user_id' => $user_id,
        'session_id' => $session_id,
    };
    my $params = $rest->buildQuery( $pdata );

    $params =~ s/\?//;

    $rest->PUT( "/users/password" , $params , $headers );

    my $rc = $rest->responseCode();
    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
        my $cookie_prefix = Config::get_value_for("cookie_prefix");
        my $cookie_domain = Config::get_value_for("email_host");
        my $c1 = $q->cookie( -name => $cookie_prefix . "userid",                -value => "$user_id", -path => "/", -domain => ".$cookie_domain");
        my $c2 = $q->cookie( -name => $cookie_prefix . "username",              -value => "$user_name", -path => "/",  -domain => ".$cookie_domain");
        my $c3 = $q->cookie( -name => $cookie_prefix . "sessionid",     -value => "$json->{session_id}", -path => "/",  -domain => ".$cookie_domain");
        my $url = Config::get_value_for("home_page");
        print $q->redirect( -url => $url, -cookie => [$c1,$c2,$c3] );
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

sub create_new_password {

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

    $rest->POST( "/users/password" , $params , $headers );

    my $rc = $rest->responseCode();
    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
        my $t = Page->new("lostpassword");
        if ( Config::get_value_for("debug_mode") ) {
            Page->report_error("user", "debug", "email=$json->{email} new-pwd=$json->{new_password}"); 
        }
        # Mail::send_password($h[0]{EMAIL}, $h[0]{PWD});
        $t->display_page("Creating New Password");
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
