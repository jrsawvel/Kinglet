#!/usr/bin/perl -wT

# i_add-message-post.t
# create a new message to start a new thread

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

my %hash;
$hash{message_text} = "\@$user_name sending a message to myself.";
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

$rest->POST( "/messages" , $params , $headers );

my $rc = $rest->responseCode();

ok($rc >= 200 && $rc < 300, 'message successfully created.');

open(my $fh, ">", "t/message-info.json") or die "cannot open > message-info.json: $!";

print $fh $rest->responseContent() . "\n"; 

close($fh) or warn "close failed: $!";


