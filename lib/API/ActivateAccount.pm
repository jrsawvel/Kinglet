use strict;
use warnings;
use NEXT;

{
    package ActivateAccount;

    my $MODULE_NAME = "ActivateAccount";

    sub new {
        my ($class, $digest) = @_;
        my $self = {
            usererr    => 0,
            syserr     => 0,
            cusmsg     => undef,
            sysmsg     => undef
        };
        bless($self, $class);                 
        __activate_account($self, $digest);
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

    sub __activate_account {
        my ($self, $digest) = @_;

        my $pt_db_source       = Config::get_value_for("database_host");
        my $pt_db_catalog      = Config::get_value_for("database_name");
        my $pt_db_user_id      = Config::get_value_for("database_username");
        my $pt_db_password     = Config::get_value_for("database_password");

        my $dbtable_users       = Config::get_value_for("dbtable_users");

        my $db = Db->new($pt_db_catalog, $pt_db_user_id, $pt_db_password);
        return __set_error($self, "system", "Error connecting to database.", $db->errstr) if $db->err;

        $digest = $db->quote($digest);

        my $sql;

        $sql = "select user_id from $dbtable_users where digest = $digest";
        $db->execute($sql);
        return __set_error($self, "system", "Error executing SQL.", $db->errstr) if $db->err;

        if ( !$db->fetchrow ) {
            return __set_error($self, "system", "Error activating account", "Invalid data given or account does not exist.");
        }
        return __set_error($self, "system", "Error retrieving data from database.", $db->errstr) if $db->err;

        $sql = "update $dbtable_users set user_status = 'o' where digest = $digest and user_status = 'p'";
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

