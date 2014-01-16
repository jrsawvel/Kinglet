package Db;

use strict;
use DBI;

sub new
{
    my ($pkg, $sid, $user, $pwd) = @_;

    my $self = {
        DBH    => undef,
        STH    => undef,
        ROW    => undef,
        ERR    => 0,
        ERRSTR => undef
    };

    $self->{DBH} = DBI->connect("dbi:mysql:$sid", $user, $pwd, {
#    $self->{DBH} = DBI->connect("dbi:mysql:database=$sid;host=parula", $user, $pwd, {
        PrintError => 0,
        RaiseError => 0
    } ) ;
    
    if ( $DBI::err ) {
        $self->{ERR} = 1;
        $self->{ERRSTR} = $DBI::errstr;
    }

    $self->{DBH}->{LongReadLen} = 512 * 1024;

    bless($self, $pkg);

    return $self;
}

sub err
{
    my $self= shift;
    return $self->{ERR};
}

sub quote
{
    my $self= shift;
    my $str = shift;
    return $self->{DBH}->quote($str);

}

sub errstr
{
    my $self= shift;
    return $self->{ERRSTR};
}

sub execute
{
    my $self = shift;
    my $sql = shift;

    $self->{ERR} = 0;
    $self->{STH} = $self->{DBH}->prepare($sql);
    if ( $DBI::err ) {
        $self->{ERR} = 1;
        $self->{ERRSTR} = $DBI::errstr;
        return;
    }

    $self->{STH}->execute(); 
    if ( $DBI::err ) {
        $self->{ERR} = 1;
        $self->{ERRSTR} = $DBI::errstr;
        return;
    }

    # be careful of mysql versions. old was {insertid}
    return $self->{STH}->{mysql_insertid};
}

sub insertid
{
    my $self = shift;
    return $self->{STH}->{insertid};
}

sub disconnect
{
    my $self = shift;

    $self->{ERR} = 0;
    $self->{STH}->finish; 

    $self->{DBH}->disconnect();
    if ( $DBI::err ) {
        $self->{ERR} = 1;
        $self->{ERRSTR} = $DBI::errstr;
    }
}

sub fetchrow
{

    my $self = shift;
    $self->{ERR} = 0;
    $self->{ROW} = $self->{STH}->fetchrow_hashref;

    if ( $DBI::err ) {
        $self->{ERR} = 1;
        $self->{ERRSTR} = $DBI::errstr;
        return 0;
    }

    return $self->{ROW} ? 1 : 0 ;

}

sub gethashes
{
    my $self      = shift;
    my $sql       = shift;

    $self->{ERR} = 0;
    $self->execute($sql);
    if ( $DBI::err ) {
        return undef;
    }

    my @records;

    while (my $ref = $self->{STH}->fetchrow_hashref)
    {
        if ( $DBI::err ) {
            $self->{ERR} = 1;
            $self->{ERRSTR} = $DBI::errstr;
            return undef;
        }

        push @records, $ref;
    }
    return @records;
}

sub getcol
{
    my $self = shift;
    my $col = shift;

    return $self->{ROW}->{$col};
}

sub DESTROY
{
    my $self = shift;

    $self->{DBH} = undef;
    $self->{STH} = undef;
}

1;
