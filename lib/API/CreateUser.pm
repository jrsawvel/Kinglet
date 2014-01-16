use strict;
use warnings;
use NEXT;

{
    package CreateUser;

    use JRS::StrNumUtils;
    use API::DigestMD5;
    use API::Password;
    use API::Utils;
    # use Junco::Mail;

    my $MODULE_NAME = "CreateUser";

    sub new {
        my ($class, $username, $email) = @_;
        my $self = {
            username   => $username,
            email      => $email,
            password   => undef,
            userid     => 0,
            userdigest => undef,
            usererr    => 0,
            errstr     => undef,
            syserr     => 0,
            cusmsg     => undef,
            sysmsg     => undef
        };
        bless($self, $class);                 
        return $self;
    }

    sub check_username {
        my ($self) = @_;
        if ( !defined($self->{username}) or length($self->{username}) < 1 ) {
            $self->{usererr} = 1;
            $self->{errstr} .= "Missing username.<br />\n";
        } else {
            $self->{username} = StrNumUtils::trim_spaces($self->{username});
            if ( !Utils::valid_username($self->{username}) ) {
                $self->{usererr} = 1;
                $self->{errstr} .= "Username must contain fewer than 31 characters, and only letters, numbers, and underscores are allowed. <br />\n";
            }
        }
    }

    sub check_email {
        my ($self) = @_;
        if ( !defined($self->{email}) ) {
            $self->{usererr} = 1;
            $self->{errstr} .= "Missing e-mail.<br />\n";
        } else {
            $self->{email} = StrNumUtils::trim_spaces($self->{email});
            if ( length($self->{email}) < 1 ) {
                $self->{usererr} = 1;
                $self->{errstr} .= "Missing e-mail.<br />\n";
            } elsif ( length($self->{email}) > 255 ) {
                $self->{usererr} = 1;
                $self->{errstr} .= "E-mail must be shorter than 256 characters long.<br />\n";
            } elsif ( !StrNumUtils::is_valid_email($self->{email}) ) {
                $self->{usererr} = 1;
                $self->{errstr} .= "E-mail has incorrect syntax.<br />\n";
            } 
        }
    }

    sub is_user_error {
        my ($self) = @_;
        return $self->{usererr};
    }

    sub get_syntax_error_string {
        my ($self) = @_;
        return $self->{errstr};
    }

    sub is_system_error {
        my ($self) = @_;
        return $self->{syserr};
    }

    sub get_cusmsg {
        my ($self) = @_;
        return $self->{cusmsg};
    }

    sub get_sysmsg {
        my ($self) = @_;
        return $self->{sysmsg};
    }

    sub get_user_id {
        my ($self) = @_;
        return $self->{userid};
    }

    sub get_user_digest {
        my ($self) = @_;
        return $self->{userdigest};
    }

    sub get_password {
        my ($self) = @_;
        return $self->{password};
    }

    sub add_new_user {
        my ($self) = @_;

        $self->{password} = Password::create_initial_password($self->{username}, $self->{email});

        my $ipaddress = "";
        my $datetime = Utils::create_datetime_stamp();

        my $pt_db_source       = Config::get_value_for("database_host");
        my $pt_db_catalog      = Config::get_value_for("database_name");
        my $pt_db_user_id      = Config::get_value_for("database_username");
        my $pt_db_password     = Config::get_value_for("database_password");

        my $dbtable_users       = Config::get_value_for("dbtable_users");

        my $db = Db->new($pt_db_catalog, $pt_db_user_id, $pt_db_password);
        return __set_error($self, "system", "Error connecting to database.", $db->errstr) if $db->err;

        my $enc_pass = DigestMD5::create($self->{username}, $self->{email}, $self->{password}, $datetime);

        my $userdigest = DigestMD5::create($self->{username}, $self->{email}, $enc_pass, $datetime);
        $userdigest  =~ s|[^\w]+||g;

        $datetime      = $db->quote($datetime);
        my $username   = $db->quote($self->{username});
        $enc_pass      = $db->quote($enc_pass);
        my $email      = $db->quote($self->{email});
        $userdigest    = $db->quote($userdigest);
        $ipaddress     = $db->quote($ENV{REMOTE_ADDR});

        my $sql = "";
#        $sql    .= "insert into $dbtable_users(username,  password,  email,  digest,      createddate, ipaddress,  origemail)";
#        $sql    .= "                   values ($username, $enc_pass, $email, $userdigest, $datetime,   $ipaddress, $email)";
 
        $sql    .= "insert into $dbtable_users(user_name,  password,  email,  digest,      created_date,  orig_email)";
        $sql    .= "                   values ($username, $enc_pass, $email, $userdigest, $datetime,    $email)";

        my $userid = $db->execute($sql);
        if ( $db->err ) {
            if ( $db->errstr =~ m/Duplicate entry(.*?)for key/i ) {
                $db->disconnect;
                return __set_error($self, "user", "Error creating account.", "$1 already exists.");
            }
            return __set_error($self, "system", "Error connecting to database.", $db->errstr); 
        }

        $sql = "select user_id, digest from $dbtable_users where user_name = $username";
        $db->execute($sql);
        return __set_error($self, "system", "Error executing SQL.", $db->errstr) if $db->err;

        if ( $db->fetchrow ) {
            $self->{userid}     = $db->getcol("user_id");
            $self->{userdigest} = $db->getcol("digest");
        }
        return __set_error($self, "system", "Error retrieving data from database.", $db->errstr) if $db->err;

        $db->disconnect;
        return __set_error($self, "system", "Error disconnecting from database.", $db->errstr) if $db->err;
    }

    sub __set_error {
        my ($self, $type, $cusmsg, $sysmsg) = @_;
        $self->{usererr} = 1 if $type eq "user";
        $self->{syserr}  = 1 if $type eq "system";
        $self->{cusmsg} = $MODULE_NAME . " - " . $cusmsg;
        $self->{sysmsg} = $sysmsg;
    }
}

1;
