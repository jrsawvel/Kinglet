package NewMessage;

use strict;

use JSON::PP;
use HTML::Entities;
use Encode qw(decode encode);
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use Config::Config;
use JRS::StrNumUtils;
use API::Utils;
use API::Format;
use API::Error;
use API::DigestMD5;
use API::Db;
use API::GetMessage;

my $pt_db_source       = Config::get_value_for("database_host");
my $pt_db_catalog      = Config::get_value_for("database_name");
my $pt_db_user_id      = Config::get_value_for("database_username");
my $pt_db_password     = Config::get_value_for("database_password");

my $dbtable_messages   = Config::get_value_for("dbtable_messages");
my $dbtable_recipients = Config::get_value_for("dbtable_recipients");
my $dbtable_users      = Config::get_value_for("dbtable_users");
my $dbtable_lists      = Config::get_value_for("dbtable_lists");

sub add_message {
    my $tmp_hash = shift;
    my $logged_in_user_name = shift;
    my $logged_in_user_id =  shift;

    my %reply;
    $reply{is_reply} = 0;
    if ( exists($tmp_hash->{two}) and $tmp_hash->{two} eq "replies" ) {
        # if posting a reply, uri is:  /messages/<msgid>/replies
        %reply = _get_reply_info($tmp_hash->{one}, $logged_in_user_id);
    }
 
    my $err_msg;
    undef $err_msg;

    my $q = new CGI;

    my $json_params  = decode_json $q->param("json");

    my $user_submitted_message_text = $json_params->{message_text};

    my $message_text    = StrNumUtils::trim_spaces($user_submitted_message_text);
    $message_text = Encode::decode_utf8($message_text);

    if ( !defined($message_text) || length($message_text) < 1 )  { 
       $err_msg .= "You must enter text.";
    } 

    if ( length($message_text) > 300 ) {
        my $len = length($message_text);
        $err_msg .= "$len chars entered. Max is 300.";
    }

    if ( $reply{error_exists} ) {
        $err_msg .= $reply{err_msg} . " ";
    }

    my %approved_list_info;
    my %recipient_user_id_info;
    my $recipient_names;

    if ( $reply{is_reply} ) {
        my $tmp_user_name           = "|" . lc($logged_in_user_name) . "|";
        $recipient_names            = $reply{recipient_names};
        my $reply_to_id             = $json_params->{reply_to_id};
        my $reply_to_content_digest = $json_params->{reply_to_content_digest};
        if ( !StrNumUtils::is_numeric($reply_to_id) ) {
            $err_msg .= "The message id being replied to is missing or not numeric. ";
        } elsif ( length($reply_to_content_digest) < 1 ) {
            $err_msg .= "Missing content digest. ";
        } elsif ( $reply{message_id} != $reply_to_id ) {
            $err_msg .= "Invalid reply to id given. $reply{message_id} $reply_to_id ";
        } elsif ( $reply{content_digest} ne $reply_to_content_digest ) {
            $err_msg .= "Invalid reply to content digest given. ";
        } elsif ( index(lc($recipient_names), lc($tmp_user_name)) < 0 ) {
            $err_msg .= "You were not included in the original message, so you cannot reply to it. ";
        }
    } else {
        $recipient_names = Format::create_recipient_list_str($message_text); 
    }

    # @j in message gets converted to |j|
    if ( length($recipient_names) < 3 and !$reply{is_reply} ) {
        $err_msg .= "You have to include at least one recipient name in your new message. $recipient_names";
    } else {
        # if the author of the new message did not include himself, then add the author's name to recipient list
        my $tmp_name = lc($logged_in_user_name);
        if ( lc($recipient_names) !~ m|$tmp_name| ) {
            $recipient_names .= "$logged_in_user_name|";
        }

        %recipient_user_id_info = _get_recipient_user_ids($recipient_names);
        if ( $recipient_user_id_info{error_exists} ) {
            $err_msg .= $recipient_user_id_info{error_message};
        } else {
            %approved_list_info = _is_author_on_recipients_approved_lists($logged_in_user_id, \%recipient_user_id_info);
            if ( $approved_list_info{error_exists} ) {
                $err_msg .= $approved_list_info{error_message};
            }
        }
    }
  
    if ( defined($err_msg) ) {
        my %hash;
        $hash{status}         = 400;
        $hash{description}    = "Bad Request";
        $hash{user_message}   = $err_msg;
        $hash{system_message} = $err_msg;
        $hash{message_text}  = $user_submitted_message_text;
        my $json_str = encode_json \%hash;
        print header('application/json', '400 Accepted');
        print $json_str;
        exit;
    } 

    my $markup_content    = $message_text;
    $markup_content       = HTML::Entities::encode($markup_content,'^\n^\r\x20-\x25\x27-\x7e');
    my $formatted_content = HTML::Entities::encode($markup_content, '<>');
#    $formatted_content    = StrNumUtils::url_to_link($formatted_content);
    $formatted_content    = Format::format_urls($formatted_content);
    $formatted_content    = Format::at_name_to_link($formatted_content);
# maybe later   $formatted_content    = Format::hashtag_to_link($formatted_content);
# maybe later   $formatted_content    = Format::post_id_to_link($formatted_content);
    $formatted_content    = Format::check_for_external_links($formatted_content);

    my $message_id = _add_message($logged_in_user_id, $logged_in_user_name, $formatted_content, $recipient_names, \%reply);

   _add_recipients($message_id, $recipient_user_id_info{user_ids}, $logged_in_user_id);

    my %hash;
    $hash{status}           = 201;
    $hash{description}      = "Created";
    $hash{message_id}       = $message_id;
    my $json_str = encode_json \%hash;
    print header('application/json', '201 Accepted');
    print $json_str;

    exit;
}

sub _add_message {
    my $author_id          = shift;
    my $author_name        = shift; 
    my $message_text       = shift;
    my $recipient_names    = shift;
    my $reply_hash         = shift;

    my $message_status = "o";

    my $parent_id = 0;
    if ( $reply_hash->{is_reply} ) {
        $parent_id = $reply_hash->{parent_id};
    }

    my $date_time = Utils::create_datetime_stamp();

    my $db = Db->new($pt_db_catalog, $pt_db_user_id, $pt_db_password);
    Error::report_error("500", "Error connecting to database.", $db->errstr) if $db->err;

    $author_name     = $db->quote($author_name);
    $message_text    = $db->quote($message_text);
    $recipient_names = $db->quote($recipient_names);

    # create message digest
    my $md5 = Digest::MD5->new;
    $md5->add(Utils::otp_encrypt_decrypt($message_text, $date_time, "enc"), $author_id, $date_time);
    my $content_digest = $md5->b64digest;
    $content_digest =~ s|[^\w]+||g;

    my $sql;
    $sql .= "insert into $dbtable_messages (parent_id, message_text, message_status, author_id, author_name, created_date, content_digest, recipient_names, last_message_date, last_message_author_name)";
    $sql .= " values ($parent_id, $message_text, '$message_status', $author_id, $author_name, '$date_time', '$content_digest', $recipient_names, '$date_time', $author_name)";
    my $message_id = $db->execute($sql);
    Error::report_error("500", "Error executing SQL.", $db->errstr) if $db->err;

    if ( $reply_hash->{is_reply} ) {
        $sql = "update $dbtable_messages set reply_count=reply_count+1, last_message_date='$date_time', last_message_author_name=$author_name, last_message_id=$message_id where message_id=$parent_id";
        $db->execute($sql);
        Error::report_error("500", "Error executing SQL.", $db->errstr) if $db->err;
    }

    $db->disconnect;
    Error::report_error("500", "Error disconnecting from database.", $db->errstr) if $db->err;

    return $message_id;
}

sub _is_author_on_recipients_approved_lists {
    my $author_id      = shift;
    my $recipient_info = shift; # ref to hash that contains refs to arrays

    my $recipient_ids   = $recipient_info->{user_ids};
    my $recipient_names = $recipient_info->{user_names};

    my $sql;

    my $db = Db->new($pt_db_catalog, $pt_db_user_id, $pt_db_password);
    Error::report_error("500", "Error connecting to database.", $db->errstr) if $db->err;

    my $len = @$recipient_ids;

    my %hash;
    $hash{error_exists} = 0;

    for (my $i=0; $i<$len; $i++) {
        my $user_id   = $recipient_ids->[$i];
        my $user_name = $recipient_names->[$i];
        if ( $user_id && $user_id != $author_id ) {
            $sql = "select status from $dbtable_lists where requester_user_id = $author_id and recipient_user_id = $user_id  ";
            $db->execute($sql);
            Error::report_error("500", "Error executing SQL.", $db->errstr) if $db->err;
            if ( $db->fetchrow ) {
                my $status = $db->getcol("status");
                if ( $status eq 'p' ) {
                    $hash{error_message} .= "You cannot message '$user_name' because your request to be added to the user's approved list is still pending a decision by the user. ";
                    $hash{error_exists}   = 1;
                } elsif ( $status eq 'r' ) {
                    $hash{error_message} .= "You cannot message '$user_name' because your request to be added to the user's approved list was rejected. ";
                    $hash{error_exists}   = 1;
                }
            } else {
                $hash{error_message} .= "You cannot message '$user_name' because you have not requested to be added to the user's approved list. ";
                $hash{error_exists}   = 1;
            }
            Error::report_error("500", "Error retrieving data from database.", $db->errstr) if $db->err;
        }
    }

#    $db->disconnect; why is this causing an error - 11Feb2014
#    Error::report_error("500", "Error disconnecting from database.", $db->errstr) if $db->err;

    return %hash;
}

sub _add_recipients {
    my $message_id  = shift;
    my $recipients  = shift; # ref to array

    my $sql;

    my $db = Db->new($pt_db_catalog, $pt_db_user_id, $pt_db_password);
    Error::report_error("500", "Error connecting to database.", $db->errstr) if $db->err;

    foreach (@$recipients) {
        my $user_id = $_;
        if ( $user_id ) {
            $sql = "insert into $dbtable_recipients (message_id, user_id) ";
            $sql .= " values ($message_id, $user_id)";
            $db->execute($sql);
            Error::report_error("500", "Error executing SQL.", $db->errstr) if $db->err;
        }
    }

    $db->disconnect;
    Error::report_error("500", "Error disconnecting from database.", $db->errstr) if $db->err;
}

sub _get_recipient_user_ids {
    my $recipient_list_str = shift;

    my $sql;

    $recipient_list_str =~ s/^\|//;
    $recipient_list_str =~ s/\|$//;
    my @recipients = split(/\|/, $recipient_list_str);

    my $db = Db->new($pt_db_catalog, $pt_db_user_id, $pt_db_password);
    Error::report_error("500", "Error connecting to database.", $db->errstr) if $db->err;

    my %hash;
    my @ids;
    my $i=0;
    foreach (@recipients) {
        my $recipient = $_;
        $recipient = $db->quote($recipient);
        if ( $recipient ) {
            $sql = "select user_id from $dbtable_users where user_name = $recipient and user_status='o'";
            $db->execute($sql);
            Error::report_error("500", "Error executing SQL.", $db->errstr) if $db->err;
         
            if ( $db->fetchrow ) {
                $ids[$i] = $db->getcol("user_id");
                $i++;
            } else {
                $hash{error_message} .= "User $recipient does not exist. ";
                $hash{error_exists}   = 1;
            }

            Error::report_error("500", "Error retrieving data from database.", $db->errstr) if $db->err;
        }
    }

    $db->disconnect;
    Error::report_error("500", "Error disconnecting from database.", $db->errstr) if $db->err;

    $hash{user_ids}   = \@ids;
    $hash{user_names} = \@recipients;

    return %hash;
}

sub _get_reply_info {
    my $reply_to_id       = shift;
    my $logged_in_user_id = shift;

    my %return_hash;

    $return_hash{is_reply} = 1;

    if ( !StrNumUtils::is_numeric($reply_to_id) ) {
        $return_hash{error_exists} = 1;
        $return_hash{err_msg} = "Invalid message ID. ID is not numeric.";
        return %return_hash;
    }

    my %reply_to_msg = GetMessage::_get_message($reply_to_id, $logged_in_user_id);

    $return_hash{recipient_names} = $reply_to_msg{recipient_names};
    $return_hash{message_id}      = $reply_to_msg{message_id};
    $return_hash{content_digest}  = $reply_to_msg{content_digest};
    $return_hash{parent_id}       = $reply_to_id;

    return %return_hash;
}

1;

