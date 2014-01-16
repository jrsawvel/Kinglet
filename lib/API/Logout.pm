use strict;
use warnings;
use NEXT;

{
    package Logout;

    my $MODULE_NAME = "Logout";

    sub new {
        my ($class, $user_name, $session_id) = @_;
        my $self = {
            usererr    => 0,
            syserr     => 0,
            cusmsg     => undef,
            sysmsg     => undef
        };
        bless($self, $class);                 
        __logout($self, $user_name, $session_id);
        return $self;
    }

    sub is_user_error {
        my ($self) = @_;
        return $self->{usererr};
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

    sub __logout {
        my ($self, $user_name, $session_id) = @_;

        my $pt_db_source       = Config::get_value_for("database_host");
        my $pt_db_catalog      = Config::get_value_for("database_name");
        my $pt_db_user_id      = Config::get_value_for("database_username");
        my $pt_db_password     = Config::get_value_for("database_password");

        my $dbtable_users       = Config::get_value_for("dbtable_users");
        my $dbtable_sessionids  = Config::get_value_for("dbtable_sessionids");

        my $db = Db->new($pt_db_catalog, $pt_db_user_id, $pt_db_password);
        return __set_error($self, "system", "Error connecting to database.", $db->errstr) if $db->err;

        $session_id = $db->quote($session_id);
        $user_name  = $db->quote($user_name);

        my $user_id = 0;

        my $sql;

        $sql = "select user_id from $dbtable_users where user_name = $user_name";
        $db->execute($sql);
        return __set_error($self, "system", "Error executing SQL.", $db->errstr) if $db->err;
        if ( $db->fetchrow ) {
            $user_id = $db->getcol("user_id");
        } else {
            return __set_error($self, "system", "Error (1) logging out account", "Invalid data given or account does not exist.");
        }
        return __set_error($self, "system", "Error retrieving data from database.", $db->errstr) if $db->err;

        my $tmp_user_id = 0;
        $sql = "select user_id from $dbtable_sessionids where session_id = $session_id";
        $db->execute($sql);
        return __set_error($self, "system", "Error executing SQL.", $db->errstr) if $db->err;
        if ( $db->fetchrow ) {
            $tmp_user_id = $db->getcol("user_id");
        } else {
            return __set_error($self, "system", "Error (2) logging out account", "Invalid data given or account does not exist. $sql");
        }
        return __set_error($self, "system", "Error retrieving data from database.", $db->errstr) if $db->err;
        if ( $user_id != $tmp_user_id ) {
            return __set_error($self, "system", "Error (3) logging out account", "Invalid data given or account does not exist.");
        }

        $sql = "update $dbtable_sessionids set session_status = 'd' where session_id = $session_id and user_id = $user_id and session_status='o'";
        $db->execute($sql);
        return __set_error($self, "system", "Error executing SQL.", $db->errstr) if $db->err;

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

