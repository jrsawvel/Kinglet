package Config;
use strict;
use warnings;

use YAML::Tiny;

my $yml_file = "/home/kinglet/Kinglet/yaml/kinglet.yml";

my $yaml = YAML::Tiny->new;

$yaml = YAML::Tiny->read($yml_file);

sub get_value_for {
    my $name = shift;

    if ( !exists($yaml->[0]->{$name}) ) {
        return 0;
    }
    return $yaml->[0]->{$name};
}

sub set_value_for {
    my $name = shift;
    my $value = shift;

    if ( !exists($yaml->[0]->{$name}) ) {
        return 0;
    }
    $yaml->[0]->{$name} = $value;
  
    return 1;
}

1;

