package UserSettings;

use strict;
use warnings;

use JSON::PP;
use CGI qw(:standard);
use HTML::Entities;
use Config::Config;
use JRS::StrNumUtils;
use API::Db;
use API::Format;
use API::Utils;
use API::Error;

my $pt_db_source       = Config::get_value_for("database_host");
my $pt_db_catalog      = Config::get_value_for("database_name");
my $pt_db_user_id      = Config::get_value_for("database_username");
my $pt_db_password     = Config::get_value_for("database_password");

my $dbtable_users      = Config::get_value_for("dbtable_users");

sub update_profile {
    my $json_str = shift;
    my $username = shift;
    my $userid   = shift;

    my $err_msg;
    undef $err_msg;

    my $json_params  = decode_json $json_str;

    my $email               = $json_params->{"email"};
    my $descmarkup          = $json_params->{"desc_markup"};

    my $descformat = "";

    ########## E-MAIL
    if ( !defined($email) ) {
        $err_msg .= "Missing e-mail. ";
    } else {
        $email = StrNumUtils::trim_spaces($email);
        if ( length($email) < 1 ) {
            $err_msg .= "Missing e-mail. ";
        } elsif ( length($email) > 255 ) {
            $err_msg .= "E-mail must be less 256 characters long. ";
        } elsif ( !StrNumUtils::is_valid_email($email) ) {
            $err_msg .= "E-mail has incorrect syntax. ";
        }
    }

    ######## Description
    if ( defined($descmarkup) ) {
        $descformat = StrNumUtils::trim_spaces($descmarkup);
        $descformat = HTML::Entities::encode($descformat, '<>');
        $descformat = StrNumUtils::url_to_link($descformat);
        $descformat = StrNumUtils::newline_to_br($descformat);
    } else {
        $descformat = "";
    }

    my @rc;

    if ( defined($err_msg) ) {
        Error::report_error("400", "Invalid data.", $err_msg);
    } else {
        _update_user($userid, $username, $email, $descformat, $descmarkup);
    }

    my %hash;
    $hash{status}       = 200;
    my $json_return_str = encode_json \%hash;
    print header('application/json', '200 Accepted');
    print $json_return_str;
    exit;

}

sub _update_user {
    my $userid   = shift;
    my $username = shift;
    my $email    = shift;
    my $descformat = shift;
    my $descmarkup = shift;

    my @loop_data;

    my $db = Db->new($pt_db_catalog, $pt_db_user_id, $pt_db_password);
    Error::report_error("500", "Error connecting to database.", $db->errstr) if $db->err;

    $descmarkup = $db->quote($descmarkup);
    $descformat = $db->quote($descformat);
    $email      = $db->quote($email);

    my $SqlStr;
    $SqlStr    .= "update $dbtable_users set " .
                  "email=$email, " .
                  "desc_format=$descformat, " .
                  "desc_markup=$descmarkup " .
                  " where user_id=$userid";

    $db->execute($SqlStr);
    if ( $db->errstr =~ m|Duplicate entry '(.*?)'|i ) {
        Error::report_error("400", "Duplicate entry", "E-mail address $1 already exists.");
    } else {
        Error::report_error("500", "Error executing SQL", $db->errstr) if $db->err;
    }

    $db->disconnect;
    Error::report_error("500", "Error disconnecting from database.", $db->errstr) if $db->err;

    return @loop_data;
}

1;

