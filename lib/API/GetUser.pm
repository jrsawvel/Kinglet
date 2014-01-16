package GetUser;

use strict;

use JSON::PP;
use CGI qw(:standard);
use Config::Config;
use JRS::StrNumUtils;
use API::Error;
use API::Db;

my $pt_db_source       = Config::get_value_for("database_host");
my $pt_db_catalog      = Config::get_value_for("database_name");
my $pt_db_user_id      = Config::get_value_for("database_username");
my $pt_db_password     = Config::get_value_for("database_password");

my $dbtable_users      = Config::get_value_for("dbtable_users");

sub get_user {
    my $user_name = shift;
    my $logged_in_user_name = shift;
    my $logged_in_user_id   = shift;

    my $hash_ref  = _get_user($user_name, $logged_in_user_name, $logged_in_user_id);

    if ( !$hash_ref ) {
        Error::report_error("404", "Could not retrieve user information.", "$user_name not found.");
    } else {
        $hash_ref->{status}           = 200;
        my $json_str = encode_json $hash_ref;
        print header('application/json', '200 Accepted');
        print $json_str;
        exit;
    }
}

sub _get_user {
    my $user_name = shift;
    my $logged_in_user_name = shift;
    my $logged_in_user_id   = shift;


    my $hash_ref;

    my $db = Db->new($pt_db_catalog, $pt_db_user_id, $pt_db_password);
    Error::report_error("500", "Error connecting to database.", $db->errstr) if $db->err;

    my $quoted_user_name = $db->quote($user_name);
   
    my $sql;

    if ( $user_name eq $logged_in_user_name ) { 
        $sql = "select user_id, user_name, email, ";
        $sql .= " date_format(date_add(created_date, interval 0 hour), '%b %d, %Y') as created_date, ";
        $sql .= " user_status, desc_markup, desc_format, digest ";
        $sql .= " from $dbtable_users where user_name=$quoted_user_name and user_id=$logged_in_user_id ";
    } else {
        $sql = "select user_name, ";
        $sql .= " desc_format ";
        $sql .= " from $dbtable_users where user_name=$quoted_user_name ";
    }

    my @loop_data = $db->gethashes($sql);
    Error::report_error("500", "Error retrieving data from database.", $db->errstr) if $db->err;

    $db->disconnect();
    Error::report_error("500", "Error disconnecting from database.", $db->errstr) if $db->err;

    $hash_ref = $loop_data[0] if $loop_data[0]; # return a ref to a hash that contains the db data.

    return $hash_ref;
}

1;

