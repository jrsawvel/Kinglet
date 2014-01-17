#!/usr/bin/perl -wT

# b_activate-account-get.t
# create new user account with non-existent and syntactically correct username and email.

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
my $user_digest  = $json_params->{user_digest};
my $user_name    = $json_params->{user_name};

ok(defined($user_digest), 'new user digest parsed from json input.');
ok(defined($user_name),   'new user name parsed from jsonn input.');

my $rest = REST::Client->new();
$rest->GET($api_url . '/users/activate/' . $user_digest);

my $rc = $rest->responseCode();

ok($rc >= 200 && $rc < 300, 'new user account successfully created.');

