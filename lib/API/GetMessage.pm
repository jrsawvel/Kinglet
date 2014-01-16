package GetMessage;

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

my $dbtable_messages   = Config::get_value_for("dbtable_messages");
my $dbtable_users      = Config::get_value_for("dbtable_users");
my $dbtable_recipients = Config::get_value_for("dbtable_recipients");

sub get_message {
    my $user_auth  = shift;
    my $message_id = shift;

    if ( !$user_auth->{user_id} ) {
        Error::report_error("401", "Invalid access.", "Missing user id.");
    } 
    
    if ( !StrNumUtils::is_numeric($message_id) ) {
        Error::report_error("400", "Invalid message ID.", "ID is not numeric.");
    }

    my %hash = _get_message($message_id, $user_auth->{user_id});

    if ( !%hash ) {
        Error::report_error("404", "Message unavailable.", "Message ID not found");
    } else {
        $hash{status}           = 200;
        $hash{description}      = "OK";
        my $json_str = encode_json \%hash;
        print header('application/json', '200 Accepted');
        print $json_str;
        exit;
    }
}

sub _get_message {
    my $message_id        = shift;
    my $logged_in_user_id = shift;

    my %hash;

    my $db = Db->new($pt_db_catalog, $pt_db_user_id, $pt_db_password);
    Error::report_error("500", "Error connecting to database.", $db->errstr) if $db->err;

#    my $sql = <<EOSQLX;
#        select message_id, parent_id, message_text, message_status, 
#        author_id, author_name, content_digest, 
#        recipient_names, reply_count, 
#        date_format(date_add(created_date, interval 0 hour), '%b %d, %Y at %r') as created_date
#        from $dbtable_messages where message_id=$message_id and message_status='o'
#EOSQLX

    my $sql = <<EOSQL;
        select m.message_id, m.parent_id, m.message_text, m.message_status, 
        m.author_id, m.author_name, m.content_digest, 
        m.recipient_names, m.reply_count, 
        date_format(date_add(m.created_date, interval 0 hour), '%b %d, %Y at %r') as created_date
        from $dbtable_messages m, $dbtable_recipients r 
        where m.message_id=$message_id and m.message_status='o' 
        and r.message_id=$message_id and r.user_id=$logged_in_user_id
EOSQL



    $db->execute($sql);
    Error::report_error("500", "Error executing SQL.", $db->errstr) if $db->err;

    while ( $db->fetchrow ) {
        $hash{message_id}      = $db->getcol("message_id");
        $hash{parent_id}       = $db->getcol("parent_id");
        $hash{message_text}    = $db->getcol("message_text");
        $hash{message_status}  = $db->getcol("message_status");
        $hash{author_id}       = $db->getcol("author_id");
        $hash{author_name}     = $db->getcol("author_name");
        $hash{created_date}    = $db->getcol("created_date");
        $hash{content_digest}  = $db->getcol("content_digest");
        $hash{recipient_names} = $db->getcol("recipient_names");
        $hash{reply_count}     = $db->getcol("reply_count");
    }
    Error::report_error("500", "Error retrieving data from database.", $db->errstr) if $db->err;

    $db->disconnect();
    Error::report_error("500", "Error disconnecting from database.", $db->errstr) if $db->err;

    return %hash;
}

1;

