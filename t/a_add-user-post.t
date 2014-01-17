#!/usr/bin/perl -wT

# a_add-user-post.t
# create new user account with non-existent and syntactically correct username and email.

use strict;

use lib 'lib';

# use Test::More qw(no_plan);
use Test::More tests => 6;

BEGIN {
    use_ok('REST::Client');
    use_ok('JSON::PP');
    use_ok('Config::Config');
}


my $api_url = Config::get_value_for("api_url");
ok(defined($api_url), 'read api url from config file.');

my $test_username = "kinglettest" . time();
my $test_email    = "$test_username\@test.com";

my %hash;
$hash{user_name} = $test_username;
$hash{email}     = $test_email;
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

$rest->POST( "/users" , $params , $headers );

my $rc = $rest->responseCode();

ok($rc >= 200 && $rc < 300, 'new user account successfully created.');

my $json_params = decode_json $rest->responseContent();

ok(defined($json_params->{user_digest}), 'new user digest returned.');

open(my $fh, ">", "t/new-user-info.json") or die "cannot open > new-user-info.json: $!";

print $fh $rest->responseContent() . "\n"; 

close($fh) or warn "close failed: $!";
