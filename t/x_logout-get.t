#!/usr/bin/perl -wT

# h_logout-get.t
# logout

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

my $query_string = "/?user_name=$user_name&user_id=$user_id&session_id=$session_id";

$api_url .=  '/users/' . $user_name . '/logout/';
my $rest = REST::Client->new();
$api_url .= $query_string;
$rest->GET($api_url); 
my $rc = $rest->responseCode();

ok($rc >= 200 && $rc < 300 , 'successfully logged out..');

