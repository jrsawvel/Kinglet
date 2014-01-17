#!/usr/bin/perl -wT

# f_get-user-get.pl
# show profile page for logged-in user, which would be the same for showing another user

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

open(my $fh, "<", "t/logged-in-info.json") or die "cannot open < logged-in-info.json for read: $!";
while ( <$fh> ) {
    chomp;
    $json_input = $_; 
}
close($fh) or warn "close failed: $!";

ok(defined($json_input), 'login info read from file.');

my $json_params  = decode_json $json_input;
my $user_id      = $json_params->{user_id};
my $user_name    = $json_params->{user_name};
my $session_id   = $json_params->{session_id};

ok(defined($user_id),     'user id parsed from jsonn input.');
ok(defined($user_name),   'user name parsed from jsonn input.');
ok(defined($session_id),  'session id parsed from jsonn input.');

my $username_for_profile = $user_name; # we'll view our own profile page

my $query_string = "/?user_name=$user_name&user_id=$user_id&session_id=$session_id";

$api_url .=  '/users/' . $username_for_profile;
my $rest = REST::Client->new();
$api_url .= $query_string;
$rest->GET($api_url); 
my $rc = $rest->responseCode();

ok($rc >= 200 && $rc < 300 , 'showing profile page was successful.');

