package Auth;

use strict;
use warnings;

use API::DigestMD5;
use API::Db;

my $pt_db_source       = Config::get_value_for("database_host");
my $pt_db_catalog      = Config::get_value_for("database_name");
my $pt_db_user_id      = Config::get_value_for("database_username");
my $pt_db_password     = Config::get_value_for("database_password");

my $dbtable_users      = Config::get_value_for("dbtable_users");
my $dbtable_sessionids = Config::get_value_for("dbtable_sessionids");

sub authenticate_user {
    my $user_auth = shift;  

    my $hash;

    if ( $user_auth->{user_id} < 1 ) {
        $hash->{status} = 401;
        $hash->{user_message}   = "Invalid access.";
        $hash->{system_message} = "User not logged in.";
        return $hash;
    } 
    if ( !valid_user($user_auth) ) {
        $hash->{status} = 403;
        $hash->{user_message}   = "Invalid access.";
        $hash->{system_message} = "User could not authenticate.";
        return $hash;
    } 
    $hash->{status} = 200;
    return $hash;
}

sub valid_user {
    my $h = shift;

    my $multiple_sessionids = Config::get_value_for("multiple_sessionids");

    my $db = Db->new($pt_db_catalog, $pt_db_user_id, $pt_db_password);
    return 0 if $db->err;

    my $sql = "select user_id, user_name, password, email, digest, session_id, created_date, orig_email from $dbtable_users where user_id=$h->{user_id} and user_status='o'";
    $db->execute($sql);
    return 0 if $db->err;

    my %hash;

    if ( $db->fetchrow ) {
        $hash{user_id}        = $db->getcol("user_id");
        $hash{user_name}      = $db->getcol("user_name");
        $hash{password}       = $db->getcol("password");
        $hash{email}          = $db->getcol("email");
        $hash{user_digest}    = $db->getcol("digest");
        $hash{session_id}     = $db->getcol("session_id");
        $hash{date}           = $db->getcol("created_date");
        $hash{orig_email}     = $db->getcol("orig_email");
    } else {
        $db->disconnect;
        return 0;
    }

    return 0 if $db->err;

    if ( $h->{user_id} != $hash{user_id} || lc($h->{user_name}) ne lc($hash{user_name}) ) {
        return 0;
    }

    if ( !$multiple_sessionids  and  $h->{session_id} ne $hash{session_id} ) {
            return 0;
    } elsif ( $multiple_sessionids ) {
        my $tmp_sessionid = $db->quote($h->{session_id});
        my $sql = "select user_id from $dbtable_sessionids where session_id=$tmp_sessionid and session_status='o' limit 1";
        $db->execute($sql);
        return 0 if $db->err;
        if ( $db->fetchrow ) {
            my $userid = $db->getcol("user_id");
            if ( $userid != $h->{user_id} ) {
                $db->disconnect;
                return 0;
            }
        } else {
            $db->disconnect;
            return 0;
        }
    }

    $db->disconnect;
    return 0 if $db->err;

    my $tmp_userdigest = DigestMD5::create($hash{user_name}, $hash{orig_email}, $hash{password}, $hash{date});
    $tmp_userdigest  =~ s|[^\w]+||g;

    if ( $tmp_userdigest eq $hash{user_digest} ) {
        return 1;
    }

    return 0;
}

1;

