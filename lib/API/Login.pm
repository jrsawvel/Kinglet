package Login;

use strict;
use warnings;

use JSON::PP;
use CGI qw(:standard);
use JRS::DateTimeFormatter;
use JRS::StrNumUtils;
use Config::Config;
use API::DigestMD5;
use API::Db;
use API::Utils;
use API::Error;

my $pt_db_source       = Config::get_value_for("database_host");
my $pt_db_catalog      = Config::get_value_for("database_name");
my $pt_db_user_id      = Config::get_value_for("database_username");
my $pt_db_password     = Config::get_value_for("database_password");

my $dbtable_users      = Config::get_value_for("dbtable_users");
my $dbtable_sessionids = Config::get_value_for("dbtable_sessionids");

sub login {
    my $json_str = shift;

    my $json_params  = decode_json $json_str;

    my $error_exists = 0;
    my $email             = $json_params->{email};
    my $password          = $json_params->{password};
    my $savepassword      = $json_params->{savepassword};
    if ( !defined($savepassword) ) {
        $savepassword = "no";
    } 

#  Error::report_error("400", "email=$email", "password=$password");

    if ( !StrNumUtils::is_valid_email($email) ) {
        $error_exists = 1;
    }

    if ( !Utils::valid_password($password) ) {
        $error_exists = 1;
    }

    my %hash;

    if ( $error_exists ) {
        Error::report_error("404", "Invalid login.", "Username or password was not found in database.");
    }
    else {
        %hash = _verify_login($email, $password);
    }

    if ( !%hash ) {
        Error::report_error("404", "Invalid login.", "Username or password was not found in database.");
    }

    $hash{status}           = 200;
    $hash{description}      = "OK";
    my $json_return_str = encode_json \%hash;
    print header('application/json', '200 Accepted');
    print $json_return_str;
    exit;
}

sub _verify_login {
    my $tmp_email    = shift;
    my $tmp_password = shift;

    my $sessionid = "";
    my $sql = "";
    my %hash;

    my $current_datetime = Utils::create_datetime_stamp();

    $tmp_email    = StrNumUtils::trim_spaces($tmp_email);
    $tmp_password = StrNumUtils::trim_spaces($tmp_password);

    my $multiple_sessionids = Config::get_value_for("multiple_sessionids");

    my $db = Db->new($pt_db_catalog, $pt_db_user_id, $pt_db_password);
    Error::report_error("500", "Error connecting to database.", $db->errstr) if $db->err;
   
    my $email = $db->quote($tmp_email); 
    $sql = "select user_id, user_name, password, created_date, orig_email from $dbtable_users where email=$email and user_status='o'";

    $db->execute($sql);
    Error::report_error("500", "Error executing SQL", $db->errstr) if $db->err;

    my $datetime     = "";
    my $md5_password = "";
    my $orig_email   = "";

    if ( $db->fetchrow ) {
        $hash{user_id}     = $db->getcol("user_id");
        $hash{user_name}   = $db->getcol("user_name");
        $md5_password      = $db->getcol("password");
        $datetime          = $db->getcol("created_date");
        $orig_email        = $db->getcol("orig_email");

        my $tmp_dt = DateTimeFormatter::create_date_time_stamp_utc("(yearfull)-(0monthnum)-(0daynum) (24hr):(0min):(0sec)"); # db date format in gmt:  2013-07-17 21:15:34
        $hash{session_id} = DigestMD5::create($hash{user_name}, $orig_email, $md5_password, $datetime, $tmp_dt);
        $hash{session_id} =~ s|[^\w]+||g;
    }
    Error::report_error("500", "Error retrieving data from database.", $db->errstr) if $db->err;

    my $pwddigest = DigestMD5::create($hash{user_name}, $orig_email, $tmp_password, $datetime);

    if ( $md5_password ne $pwddigest ) {
        %hash = ();
    } else {
        my $sessionid = $db->quote($hash{session_id});
        if ( $multiple_sessionids ) {
            $sql = "insert into $dbtable_sessionids (user_id, session_id, created_date, session_status)";
            $sql .= " values ($hash{user_id}, $sessionid, '$current_datetime', 'o')";
        } else {
            $sql = "update $dbtable_users set session_id=$sessionid where user_id=$hash{user_id}";
        }
        $db->execute($sql);
        Error::report_error("500", "Error executing SQL", $db->errstr) if $db->err;
    }

    $db->disconnect;
    Error::report_error("500", "Error disconnecting from database.", $db->errstr) if $db->err;

    return %hash;
}

1;

