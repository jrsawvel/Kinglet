package Password;

use strict;
use warnings;

use JSON::PP;
use CGI qw(:standard);
use Config::Config;
use JRS::StrNumUtils;
use API::Db;
use API::DigestMD5;
use API::Error;
use API::Utils;
# use API::Mail;

my $pt_db_source       = Config::get_value_for("database_host");
my $pt_db_catalog      = Config::get_value_for("database_name");
my $pt_db_user_id      = Config::get_value_for("database_username");
my $pt_db_password     = Config::get_value_for("database_password");

my $dbtable_users      = Config::get_value_for("dbtable_users");
my $dbtable_sessionids = Config::get_value_for("dbtable_sessionids");

sub create_initial_password {
    my $tmp_username = shift;
    my $origemail    = shift;

    my $new_password = "";

   # create new password
    my $min_pwd_len = Config::get_value_for("min_pwd_len");
    srand;
    my @chars = ("A" .. "K", "a" .. "k", "M" .. "Z", "m" .. "z", 2 .. 9, qw(! @ $ % ^ & *) );
    $new_password = join("", @chars[ map {rand @chars} ( 1 .. $min_pwd_len ) ]);
    $new_password = lc($new_password);

    return $new_password;
}

sub create_new_password {
    my $json_str = shift;

    my $json_params  = decode_json $json_str;

    my $username          = $json_params->{"user_name"};
    my $email             = $json_params->{"email"};
    my $error_exists = 0;
    my $err_msg = "";

    ###### USERNAME
    if ( !defined($username) ) {
        $err_msg .= "Missing username. ";
    } else {
        if ( !Utils::valid_username($username) ) {
            $err_msg .= "Username must contain fewer than 31 characters, and only letters, numbers, and underscores are allowed. ";
        }
    }

    ###### EMAIL
    if ( !defined($email) ) {
        $err_msg .= "Missing e-mail. ";
    } else {
        $email = StrNumUtils::trim_spaces($email);
        if ( length($email) < 1 ) {
            $err_msg .= "Missing e-mail. ";
        } elsif ( length($email) > 255 ) {
            $err_msg .= "E-mail max length is 255 characters long. ";
        } elsif ( !StrNumUtils::is_valid_email($email) ) {
            $err_msg .= "E-mail has incorrect syntax. ";
        }
    }

    if ( $err_msg ) {
        Error::report_error("400", "Invalid data.", $err_msg);
    }

    $username = StrNumUtils::trim_spaces($username);
    $email    = StrNumUtils::trim_spaces($email);

    my @h = _create_new_password($username, $email);

    if ( !@h ) {
        Error::report_error("404", "Invalid input.",  "Username and/or e-mail does not exist.");
    }

    if ( exists($h[0]{CUSMSG}) ) {
        Error:report_error("500", $h[0]{CUSMSG},  $h[0]{SYSMSG});
    }

#todo    Mail::send_password($h[0]{EMAIL}, $h[0]{PWD});

    my %hash;
    $hash{status}       = 200;
    $hash{description}  = "OK";
    $hash{email}        = $h[0]{EMAIL};
    $hash{new_password} = $h[0]{PWD};
    my $json_return_str = encode_json \%hash;
    print header('application/json', '200 Accepted');
    print $json_return_str;
    exit;
}

sub _create_new_password {
    my $tmp_username = shift;
    my $tmp_email    = shift;

    my $new_password = "";
    my $datetime = "";
    my $username_in_database = "";
    my $origemail = "";

    my @loop_data;

    my $db = Db->new($pt_db_catalog, $pt_db_user_id, $pt_db_password);
    Error::report_error("500", "Error connecting to database.", $db->errstr) if $db->err;

    my $username = $db->quote($tmp_username);
    my $email    = $db->quote($tmp_email);

    my $sql = "select user_name, created_date, orig_email from $dbtable_users where user_name=$username and email=$email and user_status in ('o','p')";

    $db->execute($sql);
    Error::report_error("500", "Error executing SQL", $db->errstr) if $db->err;

    if ( $db->fetchrow ) {
        $datetime             = $db->getcol("created_date");
        $username_in_database = $db->getcol("user_name");
        $origemail            = $db->getcol("orig_email");
    } else {
        $db->disconnect;
        return @loop_data;
    }
    Error::report_error("500", "Error retrieving data from database.", $db->errstr) if $db->err;

   # create new password
    my $min_pwd_len = Config::get_value_for("min_pwd_len");
    srand;
    my @chars = ("A" .. "K", "a" .. "k", "M" .. "Z", "m" .. "z", 2 .. 9, qw(! @ $ % ^ & *) );
    $new_password = join("", @chars[ map {rand @chars} ( 1 .. $min_pwd_len ) ]);
    $new_password = lc($new_password);

    my $pwddigest = DigestMD5::create($tmp_username, $origemail, $new_password, $datetime);

    my $new_userdigest = DigestMD5::create($username_in_database, $origemail, $pwddigest, $datetime);
    $new_userdigest  =~ s|[^\w]+||g;

    $pwddigest      = $db->quote($pwddigest);
    $new_userdigest = $db->quote($new_userdigest);

    $sql = "update $dbtable_users set password=$pwddigest, digest=$new_userdigest  where user_name=$username and email=$email and user_status='o'";
    $db->execute($sql);
    Error::report_error("500", "Error executing SQL", $db->errstr) if $db->err;

    $db->disconnect;
    Error::report_error("500", "Error disconnecting from database.", $db->errstr) if $db->err;

    return $loop_data[0] = {EMAIL=> $tmp_email, PWD => $new_password};
}

sub update_password {
    my $json_str = shift;

    my $json_params  = decode_json $json_str;

    my $err_msg;
    undef $err_msg;

    my $oldpassword          = $json_params->{"old_password"};
    my $newpassword          = $json_params->{"new_password"};
    my $verifypassword       = $json_params->{"verify_password"};
    my $userid               = $json_params->{"user_id"};
    my $username             = $json_params->{"user_name"};

    if ( !defined($userid) || !StrNumUtils::is_numeric($userid) ) {
        $err_msg .= "Missing or invalid user ID submitted. ";
    }

    if ( !defined($username) || !Utils::valid_username($username) ) {
        $err_msg .= "Missing or invalid username submitted. ";
    }

    ######## PASSWORD
    if ( !defined($oldpassword) || !defined($newpassword) || !defined($verifypassword) ) {
        $err_msg .= "Missing old, new, or verify password. ";
    } else {
        $oldpassword       = StrNumUtils::trim_spaces($oldpassword);
        $newpassword       = StrNumUtils::trim_spaces($newpassword);
        $verifypassword    = StrNumUtils::trim_spaces($verifypassword);

        if ( !Utils::valid_password($newpassword) || !Utils::valid_password($verifypassword) ) {
            $err_msg .= "Password shorter than eight characters or longer than 30 characters or contains invalid characters. ";
        } elsif ( $newpassword ne $verifypassword ) {
            $err_msg .= "New password and verify password do not match. ";
        } elsif ( !Utils::is_strong_password($newpassword) ) {
            $err_msg .= "Password is too weak. ";
        }
    }

    my @rc;

    if ( defined($err_msg) ) {
        Error::report_error("400", "Invalid data.", $err_msg);
    } else {
        @rc = _modify_password($userid, $username, $oldpassword, $newpassword);
    }

    my %hash;
    $hash{status}       = 200;
    $hash{session_id}   = $rc[0]{SESSIONID};
    $hash{user_id}      = $userid;
    $hash{user_name}    = $username;
    my $json_return_str = encode_json \%hash;
    print header('application/json', '200 Accepted');
    print $json_return_str;
    exit;
}


sub _modify_password {
    my $userid      = shift;
    my $username    = shift;
    my $oldpassword = shift;
    my $newpassword = shift;

    my $sqlstr;

    my @loop_data;

    my $db = Db->new($pt_db_catalog, $pt_db_user_id, $pt_db_password);
    Error::report_error("500", "Error connecting to database.", $db->errstr) if $db->err;

    my $tmp_username = $db->quote($username);

    $sqlstr = "select user_id, password, created_date, email, digest, orig_email from $dbtable_users where user_id=$userid and user_name=$tmp_username";
    $db->execute($sqlstr);
    Error::report_error("500", "Error executing SQL", $db->errstr) if $db->err;

    my $uid;

    my $password = "";
    my $datetime = "";
    my $digest   = "";
    my $origemail    = "";

    my $multiple_sessionids = Config::get_value_for("multiple_sessionids");
    my $current_datetime = Utils::create_datetime_stamp();

    if ( $db->fetchrow ) {
        $uid = $db->getcol("user_id");
        if ( $uid != $userid ) {
            Error::report_error("400", "Old password is invalid", "Try again");
        }
        $password   = $db->getcol("password");
        $datetime   = $db->getcol("created_date");
        $origemail  = $db->getcol("orig_email");
        $digest     = $db->getcol("digest");
    } else {
        Error::report_error("400", "Old password is incorrect.", "Try again.");
    }
    Error::report_error("500", "Error retrieving data from database.", $db->errstr) if $db->err;

    my $old_enc_pass = DigestMD5::create($username, $origemail, $oldpassword, $datetime);

    my $old_userdigest = DigestMD5::create($username, $origemail, $old_enc_pass, $datetime);
    $old_userdigest  =~ s|[^\w]+||g;

    if ( $old_enc_pass ne $password or $old_userdigest ne $digest ) {
        Error::report_error("400", "Old password is incorrect.", "Try again. oldpwd=$old_enc_pass - pwd=$password - olddig=$old_userdigest - digest=$digest");
    }

    # if got to here, old password matches. update db with new info.

    my $new_enc_pass = DigestMD5::create($username, $origemail, $newpassword, $datetime);

    my $new_userdigest = DigestMD5::create($username, $origemail,  $new_enc_pass, $datetime);
    $new_userdigest  =~ s|[^\w]+||g;

    my $new_sessionid = DigestMD5::create($username, $origemail, $new_enc_pass, $datetime, Utils::create_datetime_stamp());
    $new_sessionid =~ s|[^\w]+||g;

    $new_enc_pass   = $db->quote($new_enc_pass);
    $new_userdigest = $db->quote($new_userdigest);
    my $tmp_new_sessionid  = $db->quote($new_sessionid);
    $username       = $db->quote($username);
    $old_enc_pass   = $db->quote($old_enc_pass);
    $old_userdigest = $db->quote($old_userdigest);

    $sqlstr = "update $dbtable_users set password=$new_enc_pass, digest=$new_userdigest, session_id=$tmp_new_sessionid where user_id=$userid and user_name=$username and password=$old_enc_pass and digest=$old_userdigest";
    $db->execute($sqlstr);
    Error::report_error("500", "Error executing SQL", $db->errstr) if $db->err;

    if ( $multiple_sessionids ) {
        $sqlstr = "insert into $dbtable_sessionids (user_id, session_id, created_date, session_status)";
        $sqlstr .= " values ($userid, $tmp_new_sessionid, '$current_datetime', 'o')";
        $db->execute($sqlstr);
        Error::report_error("500", "Error executing SQL", $db->errstr) if $db->err;
    } 

    $db->disconnect;
    Error::report_error("500", "Error disconnecting from database.", $db->errstr) if $db->err;

#    $loop_data[0] = {USERDIGEST => $new_userdigest};
    $loop_data[0] = {SESSIONID => $new_sessionid};
    return @loop_data;
}

1;
