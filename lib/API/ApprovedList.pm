package ApprovedList;

use strict;

use REST::Client;
use JSON::PP;
use CGI qw(:standard);
use JRS::StrNumUtils;
use API::Error;
use API::Db;
use API::Utils;
use API::GetUser;

my $pt_db_source       = Config::get_value_for("database_host");
my $pt_db_catalog      = Config::get_value_for("database_name");
my $pt_db_user_id      = Config::get_value_for("database_username");
my $pt_db_password     = Config::get_value_for("database_password");

my $dbtable_lists      = Config::get_value_for("dbtable_lists");
my $dbtable_users      = Config::get_value_for("dbtable_users");

sub is_user_approved {
    my $requester_user_id   = shift;
    my $recipient_user_name  = shift;

    my $recipient_user_id = _get_user_id_for($recipient_user_name);

    my $rc = _is_requester_approved($requester_user_id, $recipient_user_id);

    return $rc;

}

sub request_addition {
    my $user_auth           = shift;
    my $recipient_user_name = shift;

    if ( $user_auth->{user_name} eq $recipient_user_name ) {
        Error::report_error("400", "Invalid request.", "It's unnecessary to add your own name to your approved list.");
    } 

    my $recipient_user_id = _get_user_id_for($recipient_user_name);

    if ( !$user_auth->{user_id} ) {
        Error::report_error("401", "Invalid access.", "Missing user id.");
    } 
    
    if ( !$recipient_user_id or !StrNumUtils::is_numeric($recipient_user_id) ) {
        Error::report_error("400", "Invalid recipient username.", "Username was not found.");
    }

    my %hash = _make_request($user_auth->{user_id}, $recipient_user_id);

    my $json_str = encode_json \%hash;
    print header('application/json', "$hash{status} Accepted");
    print $json_str;
    exit;
}

sub process_request {
    my $user_auth           = shift;
    my $requester_user_name = shift;
    my $request_type        = shift;

    my $requester_user_id = _get_user_id_for($requester_user_name);

    if ( !$user_auth->{user_id} ) {
        Error::report_error("401", "Invalid access.", "Missing user id.");
    } 
    
    if ( !$requester_user_id or !StrNumUtils::is_numeric($requester_user_id) ) {
        Error::report_error("400", "Invalid requester username.", "Username was not found.");
    }

    my %hash = _update_request($user_auth, $requester_user_id, $requester_user_name, $request_type);

    my $json_str = encode_json \%hash;
    print header('application/json', "$hash{status} Accepted");
    print $json_str;
    exit;
}

sub get_requests_received {
    my $user_auth           = shift;

    if ( !$user_auth->{user_id} ) {
        Error::report_error("401", "Invalid access.", "Missing user id.");
    } 
    
    my @requests = _requests_received($user_auth->{user_id});
    @requests    = _format_requests_received(\@requests);

    my %hash;
    $hash{status}            =  200;
    $hash{description}       = "OK";
    $hash{requests}           =  \@requests;
    my $json_str = encode_json \%hash;
    print header('application/json', '200 Accepted');
    print $json_str;
    exit;
}

sub _make_request {
    my $author_id         = shift; # user making the request
    my $recipient_user_id = shift; # user receiving the request

    my %hash;
    $hash{status}       = 204;
    $hash{description}  = "No Content";
    $hash{made_request} = "true";

    my $date_time = Utils::create_datetime_stamp();

    my $db = Db->new($pt_db_catalog, $pt_db_user_id, $pt_db_password);
    Error::report_error("500", "Error connecting to database.", $db->errstr) if $db->err;

    my $sql = "select status, created_date from $dbtable_lists where requester_user_id = $author_id and recipient_user_id = $recipient_user_id";

    $db->execute($sql);
    Error::report_error("500", "Error executing SQL.", $db->errstr) if $db->err;

    if ( $db->fetchrow ) {
        my $status = $db->getcol("status");
        if ( $status eq 'a' ) {
           $hash{status}         = 400;
           $hash{request_status} = "approved";
           $hash{description}    = "Bad Request";
           $hash{user_message}   = "Request made earlier.";
           $hash{system_message} = "Recipient has already approved the requester.";
        } elsif ( $status eq 'r' ) {
           $hash{status}         = 400;
           $hash{request_status} = "rejected";
           $hash{description}    = "Bad Request";
           $hash{user_message}   = "Request made earlier.";
           $hash{system_message} = "Recipient has already rejected the requester.";
        } elsif ( $status eq 'p' ) {
           $hash{status}         = 400;
           $hash{request_status} = "pending";
           $hash{description}    = "Bad Request";
           $hash{user_message}   = "Request made earlier.";
           $hash{system_message} = "Request is pending approval by the recipient.";
        }
    } 
    Error::report_error("500", "Error retrieving data from database.", $db->errstr) if $db->err;

    if ( $hash{status} == 204 ) {
        $sql  = "insert into $dbtable_lists (requester_user_id, recipient_user_id, status, created_date, modified_date) ";
        $sql .= " values ($author_id, $recipient_user_id, 'p', '$date_time', '$date_time') ";
        $db->execute($sql);
        Error::report_error("500", "Error executing SQL.", $db->errstr) if $db->err;

        # for the person making the request, automatically add and approve the recipient to the requester's approved list.
        $sql  = "insert into $dbtable_lists (requester_user_id, recipient_user_id, status, created_date, modified_date) ";
        $sql .= " values ($recipient_user_id, $author_id, 'a', '$date_time', '$date_time') ";
        $db->execute($sql);
        Error::report_error("500", "Error executing SQL.", $db->errstr) if $db->err;
    }

    $db->disconnect();
    Error::report_error("500", "Error disconnecting from database.", $db->errstr) if $db->err;

    return %hash;
}

sub _get_user_id_for {
    my $user_name = shift;

    my $user_id = 0;

    my $db = Db->new($pt_db_catalog, $pt_db_user_id, $pt_db_password);
    Error::report_error("500", "Error connecting to database.", $db->errstr) if $db->err;

    my $quoted_user_name = $db->quote($user_name);

    my $sql;
    $sql = "select user_id from $dbtable_users where user_name=$quoted_user_name ";
    $db->execute($sql);
    Error::report_error("500", "Error executing SQL.", $db->errstr) if $db->err;
    if ( $db->fetchrow ) {
        $user_id = $db->getcol("user_id");
    }
    Error::report_error("500", "Error retrieving data from database.", $db->errstr) if $db->err;
    
    $db->disconnect();
    Error::report_error("500", "Error disconnecting from database.", $db->errstr) if $db->err;

    return $user_id;
}

sub _requests_received {
    my $logged_in_user_id = shift;

    my $sql = <<EOSQL;
    select u.user_name, l.status, 
    date_format(date_add(l.created_date, interval 0 hour), '%b %d, %Y') as created_date
    from $dbtable_lists l, $dbtable_users u where l.recipient_user_id = $logged_in_user_id and l.requester_user_id = u.user_id
EOSQL

    my $db = Db->new($pt_db_catalog, $pt_db_user_id, $pt_db_password);
    Error::report_error("500", "Error connecting to database.", $db->errstr) if $db->err;

    my @loop_data = $db->gethashes($sql);
    Error::report_error("500", "Error executing SQL.", $db->errstr) if $db->err;

    $db->disconnect;
    Error::report_error("500", "Error disconnecting from database.", $db->errstr) if $db->err;

    return @loop_data;

}

sub _format_requests_received {
    my $loop_data = shift; #array ref

    my @requests = ();

    foreach my $hash_ref ( @$loop_data ) {
        if ( $hash_ref->{status} eq 'p' ) {
            $hash_ref->{status} = 'pending';
        } elsif ( $hash_ref->{status} eq 'a' ) {
            $hash_ref->{status} = 'approved';
        } elsif ( $hash_ref->{status} eq 'r' ) {
            $hash_ref->{status} = 'rejected';
        }

        push(@requests, $hash_ref);
    }

    return @requests;
}
    
sub _update_request {
    my $user_auth           = shift; # ref to hash of logged-in user info
    my $requester_user_id   = shift; # user requesting addtion to author's approved list
    my $requester_user_name = shift; 
    my $request_type        = shift;

    my $author_id = $user_auth->{user_id}; # user making the request

    my %hash;
    $hash{status} = 200;
    $hash{description} = "OK";

    my $date_time = Utils::create_datetime_stamp();

    my $db = Db->new($pt_db_catalog, $pt_db_user_id, $pt_db_password);
    Error::report_error("500", "Error connecting to database.", $db->errstr) if $db->err;

    my $sql = "select id, created_date, modified_date from $dbtable_lists where recipient_user_id = $author_id and requester_user_id = $requester_user_id";

    $db->execute($sql);
    Error::report_error("500", "Error executing SQL.", $db->errstr) if $db->err;

    my $quoted_request_type = $db->quote($request_type);
    if ( $db->fetchrow ) {
        my $id = $db->getcol("id");
        my $created_date  = $db->getcol("created_date");
        my $modified_date = $db->getcol("modified_date");
        $sql  = "update $dbtable_lists set status=$quoted_request_type, modified_date='$date_time' where id=$id";
        $db->execute($sql);
        Error::report_error("500", "Error executing SQL.", $db->errstr) if $db->err;

        if ( $created_date eq $modified_date ) {
            _send_request_action_message($user_auth, $request_type, $requester_user_name); 
        }
    } else {
        $hash{status}         = 400;
        $hash{description}    = "Bad Request";
        $hash{user_message}   = "No request.";
        $hash{system_message} = "No request was  made by the user.";
    }
    Error::report_error("500", "Error retrieving data from database.", $db->errstr) if $db->err;

    $db->disconnect();
    Error::report_error("500", "Error disconnecting from database.", $db->errstr) if $db->err;

    return %hash;
}

# API code makes a Client request to itself
sub _send_request_action_message {
    my $user_auth           = shift;
    my $request_type        = shift;
    my $requester_user_name = shift;
   
    my $q = new CGI;

    my $user_name    = $user_auth->{user_name};
    my $user_id      = $user_auth->{user_id};
    my $session_id   = $user_auth->{session_id};

    my $request_type_word = "crap";
    if ( $request_type eq "a" ) {
        $request_type_word = "approved";
    } elsif ( $request_type eq "r" ) {
        $request_type_word = "rejected";
    } else {
        Error::report_error("400", "Unable to complete request.", "Invalid request type action submitted $request_type.");
    }

    my $message_text = "\@$requester_user_name System Message: Your request to be added to $user_name\'s approved list has been $request_type_word.";

    my $headers = {
        'Content-type' => 'application/x-www-form-urlencoded'
    };

    # set up a REST session
    my $rest = REST::Client->new( {
           host => Config::get_value_for("api_url"),
    } );

    my %hash;
    $hash{message_text} = $message_text;
    my $json_str = encode_json \%hash;

    # then we have to url encode the params that we want in the body
    my $pdata = {
        'json'       => $json_str,
        'user_name'  => $user_name,
        'user_id'    => $user_id,
        'session_id' => $session_id,
    };
    my $params = $rest->buildQuery( $pdata );

    # but buildQuery() prepends a '?' so we strip that out
    $params =~ s/\?//;

    # then sent the request:
    # POST requests have 3 args: URL, BODY, HEADERS
    $rest->POST( "/messages" , $params , $headers );

    my $rc = $rest->responseCode();

    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
    } elsif ( $rc >= 400 and $rc < 500 ) {
        Error::report_error("400", "Action $request_type completed.", "But automated message could not be sent to $requester_user_name. $json->{user_message} - $json->{system_message} - $json->{description}"); 
        
    } else  {
        Error::report_error("400", "Unable to complete request.", "Problem processing automated message response.");
    }
}

sub _is_requester_approved {
    my $requester_user_id = shift;
    my $recipient_user_id = shift;

    my $rc = 0;

    my $db = Db->new($pt_db_catalog, $pt_db_user_id, $pt_db_password);
    Error::report_error("500", "Error connecting to database.", $db->errstr) if $db->err;

    my $sql = "select id from $dbtable_lists where requester_user_id = $requester_user_id and recipient_user_id = $recipient_user_id and status='a'";

    $db->execute($sql);
    Error::report_error("500", "Error executing SQL.", $db->errstr) if $db->err;

    if ( $db->fetchrow ) {
        $rc = $db->getcol("id");
    } 
    Error::report_error("500", "Error retrieving data from database.", $db->errstr) if $db->err;

    $db->disconnect();
    Error::report_error("500", "Error disconnecting from database.", $db->errstr) if $db->err;

    return $rc;
}


1;
