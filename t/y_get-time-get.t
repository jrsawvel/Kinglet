#!/usr/bin/perl -wT

# y_get-time-get.t 
# get server time. this is used by client-side javascript via ajax.

use strict;

use lib 'lib';

# use Test::More qw(no_plan);
use Test::More tests => 5;

BEGIN {
    use_ok('REST::Client');
    use_ok('JSON::PP');
    use_ok('Config::Config');
}

my $api_url = Config::get_value_for("api_url");
ok(defined($api_url), 'read api url from config file.');

$api_url .=  '/time/?';
my $rest = REST::Client->new();
$rest->GET($api_url); 
my $rc = $rest->responseCode();

ok($rc >= 200 && $rc < 300 , 'successfully retrieved server time.');

print $rest->responseContent();

