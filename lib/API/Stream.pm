package Stream;

use strict;

use JSON::PP;
use CGI qw(:standard);
use Config::Config;
use API::Utils;
use API::Error;
use API::Db;
use JRS::DateTimeFormatter;
use JRS::StrNumUtils;

my $pt_db_source       = Config::get_value_for("database_host");
my $pt_db_catalog      = Config::get_value_for("database_name");
my $pt_db_user_id      = Config::get_value_for("database_username");
my $pt_db_password     = Config::get_value_for("database_password");

my $dbtable_messages   = Config::get_value_for("dbtable_messages");
my $dbtable_recipients = Config::get_value_for("dbtable_recipients");

sub get_message_stream {
    my $user_auth  = shift;
    my $tmp_hash = shift;  

    my $page_num        = 1;
    my $message_id      = 0;
    my $is_reply_stream = 0;
    my $is_since_stream = 0;

    if ( exists($tmp_hash->{two}) and $tmp_hash->{two} eq "replies" ) {
        $is_reply_stream = 1;
        $message_id = $tmp_hash->{one};
    } elsif ( exists($tmp_hash->{two}) ) {
        $page_num = $tmp_hash->{two};
    }

    if ( !StrNumUtils::is_numeric($page_num) ) {
        Error::report_error("401", "Invalid access.", "Page number is not numeric.");
    }

    if ( !$user_auth->{user_id} ) {
        Error::report_error("401", "Invalid access.", "Missing user id.");
    } 

    my $sql      = _create_stream_sql($page_num, $is_reply_stream, $message_id, $user_auth->{user_id});
    my @messages = _get_stream($sql);
    @messages    = _format_message_stream(\@messages, $user_auth->{user_id}); 
    my $json_str = _format_json_messages(\@messages, $is_reply_stream);
    print header('application/json', '200 Accepted');
    print $json_str;
    exit;
}

sub get_received_messages_since {
    my $user_auth  = shift;
    my $tmp_hash = shift;  

    if ( !$user_auth->{user_id} ) {
        Error::report_error("401", "Invalid access.", "Missing user id.");
    } 

    if ( $tmp_hash->{one} ne "since" ) {
        Error::report_error("401", "Invalid access.", "Unrecognized action.");
    }

    if ( !StrNumUtils::is_numeric($tmp_hash->{two}) ) {
        Error::report_error("401", "Invalid access.", "Missing epoch date. [$tmp_hash->{two}]");
    }
    
    my $epoch = $tmp_hash->{two};
 
    my $sql      = _create_since_sql($user_auth->{user_id}, $epoch);
    my @messages = _get_stream($sql);

    my $array_len = @messages;

    my %hash;
    $hash{status}            =  200;
    $hash{description}       = "OK";
    $hash{new_message_count} = $array_len;
    my $json_str = encode_json \%hash;
    print header('application/json', '200 Accepted');
    print $json_str;
    exit;
}

sub get_threads {
    my $user_auth  = shift;
    my $tmp_hash = shift;  

    my $page_num        = 1;
    if ( exists($tmp_hash->{two}) ) {
        $page_num = $tmp_hash->{two};
    }
    if ( !StrNumUtils::is_numeric($page_num) ) {
        Error::report_error("401", "Invalid access.", "Page number is not numeric.");
    }

    if ( !$user_auth->{user_id} ) {
        Error::report_error("401", "Invalid access.", "Missing user id.");
    } 

    if ( $tmp_hash->{one} ne "threads" ) {
        Error::report_error("401", "Invalid access.", "Unrecognized action.");
    }

    my $sql     = _create_threads_sql($page_num, $user_auth->{user_id});
    my @threads = _get_stream($sql);
    @threads    = _format_threads(\@threads, $user_auth->{user_id});

    my %hash;
    $hash{status}            =  200;
    $hash{description}       = "OK";
    $hash{threads}           =  \@threads;
    my $json_str = encode_json \%hash;
    print header('application/json', '200 Accepted');
    print $json_str;
    exit;
}

sub _create_since_sql {
    my $logged_in_user_id = shift;
    my $epoch             = shift;

    my $dt = DateTimeFormatter::create_date_time_stamp_utc($epoch, "(yearfull)-(0monthnum)-(0daynum) (24hr):(0min):(0sec)"); 

    my $sql = <<EOSQL;
        select m.message_id, m.parent_id, m.message_text, 
        m.message_status, m.author_id, m.author_name, m.reply_count, m.recipient_names, 
        date_format(date_add(m.created_date, interval 0 hour), '%b %d, %Y') as created_date, 
        unix_timestamp(m.created_date) as date_epoch_seconds 
        from $dbtable_messages m, $dbtable_recipients r 
        where m.created_date > '$dt' and r.user_id=$logged_in_user_id 
        and m.author_id != $logged_in_user_id 
        and r.message_id = m.message_id and m.message_status='o' 
        order by m.message_id desc
EOSQL

    return $sql;
}

sub _create_stream_sql {
    my $page_num          = shift;
    my $is_reply_stream   = shift;
    my $message_id        = shift;
    my $logged_in_user_id = shift;

    my $max_entries = Config::get_value_for("max_entries_on_page");
    my $page_offset = $max_entries * ($page_num - 1);
    my $max_entries_plus_one = $max_entries + 1;

#    my $offset = Utils::get_time_offset();

    my $order_direction = " desc ";
    $order_direction = " asc " if $is_reply_stream;

    my $limit_str = " limit $max_entries_plus_one offset $page_offset ";
    $limit_str = "" if $is_reply_stream;

    my $reply_sql = "";
    $reply_sql = " and m.parent_id = $message_id " if $is_reply_stream;

    my $sql = <<EOSQL;
        select m.message_id, m.parent_id, m.message_text, 
        m.message_status, m.author_id, m.author_name, m.reply_count, m.recipient_names, 
        date_format(date_add(m.created_date, interval 0 hour), '%b %d, %Y') as created_date, 
        unix_timestamp(m.created_date) as date_epoch_seconds 
        from $dbtable_messages m, $dbtable_recipients r 
        where r.user_id=$logged_in_user_id and r.message_id = m.message_id and m.message_status='o' 
        $reply_sql
        order by m.message_id $order_direction
        $limit_str
EOSQL

    return $sql;
}


sub _get_stream {
    my $sql = shift;

    my $db = Db->new($pt_db_catalog, $pt_db_user_id, $pt_db_password);
    Error::report_error("500", "Error connecting to database.", $db->errstr) if $db->err;

    my @loop_data = $db->gethashes($sql);
    Error::report_error("500", "Error executing SQL.", $db->errstr) if $db->err;

    $db->disconnect;
    Error::report_error("500", "Error disconnecting from database.", $db->errstr) if $db->err;

    return @loop_data;
}

sub _format_message_stream {
    my $loop_data         = shift;
    my $logged_in_user_id = shift;
    my @messages = ();
    foreach my $hash_ref ( @$loop_data ) {
        $hash_ref->{created_date}   = Utils::format_creation_date($hash_ref->{created_date}, $hash_ref->{date_epoch_seconds});
        $hash_ref->{logged_in_user} = $logged_in_user_id; # true value so a positive number
        delete($hash_ref->{date_epoch_seconds});

        $hash_ref->{author_type} = "others";
        if ( $hash_ref->{author_id} == $logged_in_user_id ) {
            $hash_ref->{author_type} = "you";
        }
        delete($hash_ref->{author_id});

        $hash_ref->{recipient_names} =~ s/\|/ /g;
        
        push(@messages, $hash_ref);
    }
    return @messages;
}

sub _format_threads {
    my $loop_data         = shift;
    my $logged_in_user_id = shift;
    my @messages = ();
    foreach my $hash_ref ( @$loop_data ) {
        $hash_ref->{created_date}        = Utils::format_creation_date($hash_ref->{created_date},      $hash_ref->{date_epoch_seconds});
        $hash_ref->{last_message_date}   = Utils::format_creation_date($hash_ref->{last_message_date}, $hash_ref->{last_message_date_epoch_seconds});
        $hash_ref->{logged_in_user} = $logged_in_user_id; # true value so a positive number
        delete($hash_ref->{date_epoch_seconds});
        delete($hash_ref->{last_message_date_epoch_seconds});

        $hash_ref->{recipient_names} =~ s/\|/ /g;
       
        my $str = $hash_ref->{message_text}; 
        $str    = StrNumUtils::remove_html($str);
        $str    = _remove_at_names($str);
        if ( length($str) > 75 ) {
            $str = substr $str, 0, 75;
            $str .= " ...";
        }
        $hash_ref->{message_text} = $str;
        
        push(@messages, $hash_ref);
    }
    return @messages;
}

sub _format_json_messages {
    my $messages        = shift;
    my $is_reply_stream = shift;
    my $max_entries = Config::get_value_for("max_entries_on_page");
    my $len = @$messages;
    my %hash;
    $hash{next_link_bool} = 0;
    if ( !$is_reply_stream and ($len > $max_entries) ) {
        $hash{next_link_bool} = 1;
        pop @$messages;
    }
    $hash{status}      =  200;
    $hash{description} = "OK";
    $hash{messages}    =  $messages;
    my $json_str = encode_json \%hash;
    return $json_str;
}

sub _remove_at_names {
    my $str = shift;

    $str = " " . $str . " "; # hack to make regex work
    my @recipients = ();

    if ( (@recipients = $str =~ m|\s@(\w+)|gsi) ) {
            foreach (@recipients) {
               my $tmp_recipient = $_;
               $str =~ s|\@$tmp_recipient||gsi;
           }
    }
    return $str;
}

sub _create_threads_sql {
    my $page_num          = shift;
    my $logged_in_user_id = shift;

    my $max_entries = Config::get_value_for("max_entries_on_page");
    my $page_offset = $max_entries * ($page_num - 1);
    my $max_entries_plus_one = $max_entries + 1;

    my $limit_str = " limit $max_entries_plus_one offset $page_offset ";

    my $sql = <<EOSQL;
        select m.message_id,  m.message_text, 
        m.author_name, m.reply_count, m.recipient_names, 
        date_format(date_add(m.created_date, interval 0 hour), '%b %d, %Y') as created_date, 
        unix_timestamp(m.created_date) as date_epoch_seconds,
        date_format(date_add(m.last_message_date, interval 0 hour), '%b %d, %Y') as last_message_date, 
        unix_timestamp(m.last_message_date) as last_message_date_epoch_seconds,
        m.last_message_author_name,
        m.last_message_id
        from $dbtable_messages m, $dbtable_recipients r 
        where r.user_id=$logged_in_user_id and r.message_id = m.message_id and m.message_status='o' and m.parent_id=0 
        order by m.last_message_date desc
        $limit_str
EOSQL
    
#    my $sql = <<EOSQL;
#        select m.message_id, m.parent_id, m.message_text, 
#        m.message_status, m.author_id, m.author_name, m.reply_count, m.recipient_names, 
#        date_format(date_add(m.created_date, interval 0 hour), '%b %d, %Y') as created_date, 
#        unix_timestamp(m.created_date) as date_epoch_seconds 
#        from $dbtable_messages m, $dbtable_recipients r 
#        where r.user_id=$logged_in_user_id and r.message_id = m.message_id and m.message_status='o' and m.parent_id=0 
#        order by m.message_id desc
#        $limit_str
# EOSQL
    
    return $sql;
}


# possible date format alternatives:
#        date_format(date_add(created_date, interval $offset hour), '%b %d, %Y') as date, 
#        date_format(date_add(created_date, interval $offset hour), '%r') as time, 
#        date_format(date_add(created_date, interval $offset hour), '%d%b%Y') as urldate, 


1;

