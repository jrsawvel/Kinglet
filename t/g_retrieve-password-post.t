#!/usr/bin/perl -wT

# g_retrieve-password-post.t 
# request system to create a new password for user

use strict;

use lib 'lib';

# use Test::More qw(no_plan);
use Test::More tests => 8; 

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
my $email        = $json_params->{email};

ok(defined($user_name),   'user name parsed from jsonn input.');
ok(defined($email),     'email parsed from jsonn input.');


my %hash;
$hash{user_name}  = $user_name;
$hash{email}      = $user_id . $email; # to match the changed e-mail in an earlier test script
my $json = encode_json \%hash;


my $headers = {
        'Content-type' => 'application/x-www-form-urlencoded'
};

my $rest = REST::Client->new( {
        host => $api_url,
} );

my $pdata = {
        'json' => $json,
};
my $params = $rest->buildQuery( $pdata );

$params =~ s/\?//;

$rest->POST( "/users/password" , $params , $headers );

my $rc = $rest->responseCode();

ok($rc >= 200 && $rc < 300 , 'retrieving new password was successful.');

print $rest->responseContent() . "\n";

