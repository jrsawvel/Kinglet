package Users;

use strict;

use CGI qw(:standard);
use JSON::PP;
use API::Error;
use API::GetUser;
use API::Login;
use API::CreateUser;
use API::ActivateAccount;
use API::Logout;
use API::Password;
use API::UserSettings;
use API::Auth;

sub users {
    my $tmp_hash = shift;

    my $q = new CGI;

    my $request_method = $q->request_method();

    my $user_auth;
    $user_auth->{user_name}    = $q->param("user_name");
    $user_auth->{user_id}      = $q->param("user_id");
    $user_auth->{session_id}   = $q->param("session_id");
    my $is_auth = Auth::authenticate_user($user_auth);

    if ( $request_method eq "POST" ) {

        if ( exists($tmp_hash->{one}) and $tmp_hash->{one} eq "login" ) {
            Login::login($q->param("json"));
        } elsif ( exists($tmp_hash->{one}) and $tmp_hash->{one} eq "password" ) {
            Password::create_new_password($q->param("json"));
        } elsif ( !exists($tmp_hash->{one}) ) {
            _add_user($q->param("json"));   
        } else {
            Error::report_error($is_auth->{status}, $is_auth->{user_message}, $is_auth->{system_message});
        }

    } elsif ( $request_method eq "PUT" and $is_auth->{status} == 200 ) {

        if ( exists($tmp_hash->{one}) and $tmp_hash->{one} eq "password" ) {
            Password::update_password($q->param("json"));
        } elsif ( !exists($tmp_hash->{one}) ) {
            UserSettings::update_profile($q->param("json"), $user_auth->{user_name}, $user_auth->{user_id});        
        } else {
            Error::report_error($is_auth->{status}, $is_auth->{user_message}, $is_auth->{system_message});
        }

    } elsif ( $request_method eq "GET" ) {

        if ( $tmp_hash->{one} eq "activate" ) {
            _activate_account($tmp_hash->{two});
        } elsif ( $tmp_hash->{two} eq "logout" and $is_auth->{status} == 200 ) {
            _logout_user($tmp_hash->{one}, $user_auth);
        } elsif ( exists($tmp_hash->{one}) and !exists($tmp_hash->{two}) and $is_auth->{status} == 200 ) {
            GetUser::get_user($tmp_hash->{one}, $user_auth->{user_name}, $user_auth->{user_id}); 
        } else {
            Error::report_error($is_auth->{status}, $is_auth->{user_message}, $is_auth->{system_message});
        }
    } 
    Error::report_error("400", "Not found", "Invalid request");  
}

sub _add_user {
    my $json_str = shift;

    my $json_params  = decode_json $json_str;

    my $email     = $json_params->{email};
    my $user_name = $json_params->{user_name};

    my $u = CreateUser->new($user_name, $email);
    $u->check_username();    
    $u->check_email();    
    
    Error::report_error("400", "Invalid Input",  $u->get_syntax_error_string()) if $u->is_user_error(); 

    $u->add_new_user();

    Error::report_error("400",   $u->get_cusmsg(),  $u->get_sysmsg()) if $u->is_user_error(); 
    Error::report_error("400",   $u->get_cusmsg(),  $u->get_sysmsg()) if $u->is_system_error(); 

    my %hash;
    $hash{status}       = 201;
    $hash{description}  = "Created";
    $hash{user_id}      = $u->get_user_id();
    $hash{user_name}    = $user_name;
    $hash{email}        = $email;
    $hash{password}     = $u->get_password();
    $hash{user_digest}  = $u->get_user_digest();
    my $json_return_str = encode_json \%hash;
    print header('application/json', '201 Accepted');
    print $json_return_str;

    exit;
}

sub _activate_account {
    my $user_digest = shift; 

    if ( !defined($user_digest) || length($user_digest) < 1 ) {
        Error::report_error("400", "Missing data.", "No digest given.");
    }

    my $u = ActivateAccount->new($user_digest);

    Error::report_error("400",   $u->get_cusmsg(),  $u->get_sysmsg()) if $u->is_user_error(); 
    Error::report_error("400",   $u->get_cusmsg(),  $u->get_sysmsg()) if $u->is_system_error(); 

    my %hash;
    $hash{status}            = 204;
    $hash{description}       = "No Content";
    $hash{activate_account}  = "true";
    my $json_return_str = encode_json \%hash;
    print header('application/json', '204 Accepted');
    print $json_return_str;

    exit;
}

sub _logout_user {
    my $user_name      = shift;
    my $logged_in_user_hash = shift;

    my $session_id = $logged_in_user_hash->{session_id};

    if ( !defined($session_id) || length($session_id) < 1 ) {
        Error::report_error("400", "Missing data.", "No session ID given.");
    }

    my $u = Logout->new($user_name, $session_id);

    Error::report_error("400",   $u->get_cusmsg(),  $u->get_sysmsg()) if $u->is_user_error(); 
    Error::report_error("400",   $u->get_cusmsg(),  $u->get_sysmsg()) if $u->is_system_error(); 

    my %hash;
    $hash{status}       = 204;
    $hash{description}  = "No Content";
    $hash{logged_out}   = "true";
    my $json_return_str = encode_json \%hash;
    print header('application/json', '204 Accepted');
    print $json_return_str;

    exit;
}

1;
