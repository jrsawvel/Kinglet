#!/usr/bin/perl -wT

# d_update-password-put.t
# change password

use strict;

use lib 'lib';

# use Test::More qw(no_plan);
use Test::More tests => 10;

BEGIN {
    use_ok('REST::Client');
    use_ok('JSON::PP');
    use_ok('Config::Config');
}

my $api_url = Config::get_value_for("api_url");
ok(defined($api_url), 'read api url from config file.');

my $json_input;

open(my $fh, "<", "t/new-user-info.json") or die "cannot open < new-user-info.json for read: $!";
while ( <$fh> ) {
    chomp;
    $json_input = $_; 
}
close($fh) or warn "close failed: $!";

ok(defined($json_input), 'new user info read from file.');

my $json_params  = decode_json $json_input;
my $user_id      = $json_params->{user_id};
my $user_name    = $json_params->{user_name};
my $password     = $json_params->{password};

ok(defined($user_id),   'user id parsed from jsonn input.');
ok(defined($user_name), 'user name parsed from jsonn input.');
ok(defined($password),  'password parsed from jsonn input.');


open($fh, "<", "t/logged-in-info.json") or die "cannot open < logged-in-info.json for read: $!";
while ( <$fh> ) {
    chomp;
    $json_input = $_; 
}
close($fh) or warn "close failed: $!";

ok(defined($json_input), 'login info read from file.');

$json_params   = decode_json $json_input;
my $session_id = $json_params->{session_id};

my %hash;
$hash{old_password}     = $password;
$hash{new_password}     = 'ty*jb7q!4';
$hash{verify_password}  = 'ty*jb7q!4';
$hash{user_name}        = $user_name;
$hash{user_id}          = $user_id;
my $json = encode_json \%hash;

my $headers = {
    'Content-type' => 'application/x-www-form-urlencoded'
};

my $rest = REST::Client->new( {
    host => $api_url,
} );

my $pdata = {
    'json'       => $json,
    'user_name'  => $user_name,
    'user_id'    => $user_id,
    'session_id' => $session_id,
};
my $params = $rest->buildQuery( $pdata );

$params =~ s/\?//;

$rest->PUT( "/users/password" , $params , $headers );

my $rc = $rest->responseCode();

ok($rc >= 200 && $rc < 300, 'password successfully changed.');

