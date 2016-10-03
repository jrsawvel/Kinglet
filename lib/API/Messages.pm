package Messages;

use strict;

use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use API::GetMessage;
use API::Stream;
use API::NewMessage;
use API::Auth;
use API::Error;

sub messages {
    my $tmp_hash = shift;

    my $q = new CGI;

    my $request_method = $q->request_method();

    my $user_auth;
    $user_auth->{user_name}    = $q->param("user_name");
    $user_auth->{user_id}      = $q->param("user_id");
    $user_auth->{session_id}   = $q->param("session_id");

    my $hash = Auth::authenticate_user($user_auth);
    if ( $hash->{status} != 200 ) {
        Error::report_error($hash->{status}, $hash->{user_message}, $hash->{system_message});
    }

    if ( $request_method eq "GET" ) {

        if ( $tmp_hash->{one} eq "page" or $tmp_hash->{two} eq "replies" ) {
            Stream::get_message_stream($user_auth, $tmp_hash);
        } elsif ( $tmp_hash->{one} eq "since" ) {
            Stream::get_received_messages_since($user_auth, $tmp_hash);
        } elsif ( $tmp_hash->{one} eq "threads" ) {
            Stream::get_threads($user_auth, $tmp_hash);
        } elsif ( $tmp_hash->{one} ) {
            GetMessage::get_message($user_auth, $tmp_hash->{one});
        } else {
            Stream::get_message_stream($user_auth);
        }

    } elsif ( $request_method eq "POST" ) {
        NewMessage::add_message($tmp_hash, $user_auth->{user_name}, $user_auth->{user_id});
    }

}

1;

