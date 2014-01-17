#!/usr/bin/perl -wT

# c_login-post.t
# log into kinglet.

use strict;

use lib 'lib';

# use Test::More qw(no_plan);
use Test::More tests => 9;

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

ok(defined($json_input), 'user info read from file.');

my $json_params  = decode_json $json_input;
my $email        = $json_params->{email};
my $password     = $json_params->{password};

ok(defined($email),    'account email parsed from json input.');
ok(defined($password), 'account password parsed from jsonn input.');

my %hash;
$hash{email}    = $email;
$hash{password} = $password;
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

$rest->POST( "/users/login" , $params , $headers );

my $rc = $rest->responseCode();

ok($rc >= 200 && $rc < 300, 'user account successfully logged in.');

$json_params = decode_json $rest->responseContent();

ok(defined($json_params->{session_id}), 'user digest returned.');

open($fh, ">", "t/logged-in-info.json") or die "cannot open > logged-in-info.json: $!";

print $fh $rest->responseContent() . "\n"; 

close($fh) or warn "close failed: $!";

