package StrNumUtils;

use strict;
use warnings;

sub trim_spaces {
    my $str = shift;
    if ( !defined($str) ) {
        return "";
    }
    # remove leading spaces.   
    $str  =~ s/^\s+//;
    # remove trailing spaces.
    $str  =~ s/\s+$//;
    return $str;
}

# todo is this used? What about a perl module?
sub url_encode {
    my $text = shift;
    $text =~ s/([^a-z0-9_.!~*'() -])/sprintf "%%%02X", ord($1)/eig;
    $text =~ tr/ /+/;
    return $text;
}

# todo is this needed?
sub url_decode {
    my $text = shift;
    $text =~ tr/\+/ /;
    $text =~ s/%([a-f0-9][a-f0-9])/chr( hex( $1 ) )/eig;
    return $text;
}

sub url_to_link {
    my $str_orig = shift;
    # from Greymatter
    # two lines of code written in part by Neal Coffey (cray@indecisions.org)
    $str_orig =~ s#(^|\s)(\w+://)([A-Za-z0-9?=:\|;,_\-/.%+&'~\(\)\#@!\^]+)#$1<a href="$2$3">$2$3</a>#isg;
        $str_orig =~ s#(^|\s)(www.[A-Za-z0-9?=:\|;,_\-/.%+&'~\(\)\#@!\^]+)#$1<a href="http://$2">$2</a>#isg;

    # next line a modification from jr to accomadate e-mail links created with anchor tag
    $str_orig =~ s/(^|\s)(\w+\@\w+\.\w+)/<a href="mailto:$2">$1$2<\/a>/isg;
    return $str_orig;
}

sub br_to_newline {
    my $str = shift;
    $str =~ s/<br \/>/\r\n/g;
    return $str;
}

sub remove_html {
    my $str = shift;
    # remove ALL html
    $str =~ s/<([^>])+>|&([^;])+;//gsx;
    return $str;
}

sub newline_to_br {
    my $str = shift;
    $str =~ s/[\r][\n]/<br \/>/g;
    $str =~ s/[\n]/<br \/>/g;
    return $str;
}

sub remove_newline {
    my $str = shift;
#    $str =~ s/[\r][\n]//gs;
#    $str =~ s/\n.*//s;
#    $str =~ s/\s.*//s;
    $str =~ s/\n//gs;
    return $str;
}

sub is_numeric {
    my $str = shift;
    my $rc = 0;
    if ( $str =~ m|^[0-9]+$| ) {
        $rc = 1;
    }
    return $rc;
}

sub is_float {
    my $str = shift;
    my $rc = 0;
    if ( $str =~ m|^[0-9\.]+$| ) {
        $rc = 1;
    }
    return $rc;
}

sub trim_br {
    my $str = shift;
    # remove leading <br />
    $str =~ s|^(<br />)+||g;
    # remove trailing br 
    $str =~ s|(<br />)+$||g;
    return $str;
}

sub round {
    my $number = shift;
    return int($number + .5 * ($number <=> 0));
}

# http://stackoverflow.com/questions/77226/how-can-i-capitalize-the-first-letter-of-each-word-in-a-string-in-perl
sub ucfirst_each_word {
    my $str = shift;
    $str =~ s/(\w+)/\u$1/g;
    return $str;
}
    
sub is_valid_email {
  my $mail = shift;                                                  #in form name@host
  return 0 if ( $mail !~ /^[0-9a-zA-Z\.\-\_]+\@[0-9a-zA-Z\.\-]+$/ ); #characters allowed on name: 0-9a-Z-._ on host: 0-9a-Z-. on between: @
  return 0 if ( $mail =~ /^[^0-9a-zA-Z]|[^0-9a-zA-Z]$/);             #must start or end with alpha or num
  return 0 if ( $mail !~ /([0-9a-zA-Z]{1})\@./ );                    #name must end with alpha or num
  return 0 if ( $mail !~ /.\@([0-9a-zA-Z]{1})/ );                    #host must start with alpha or num
  return 0 if ( $mail =~ /.\.\-.|.\-\..|.\.\..|.\-\-./g );           #pair .- or -. or -- or .. not allowed
  return 0 if ( $mail =~ /.\.\_.|.\-\_.|.\_\..|.\_\-.|.\_\_./g );    #pair ._ or -_ or _. or _- or __ not allowed
  return 0 if ( $mail !~ /\.([a-zA-Z]{2,3})$/ );                     #host must end with '.' plus 2 or 3 alpha for TopLevelDomain (MUST be modified in future!)
  return 1;
}
   
sub shuffle_array {
    my $array = shift;
    my $i;
    for ($i = @$array; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
        @$array[$i, $j] = @$array[$j,$i];
    }
}

sub quote_string {
    my $str = shift;
    return "NULL" unless defined $str;
    $str =~ s/'/''/g;
    return "'$str'";
}

sub clean_title {
    my $str = shift;

    $str =~ s|[-]||g;
    $str =~ s|[ ]|-|g;
    $str =~ s|[:]|-|g;
    $str =~ s|--|-|g;

    # only use alphanumeric, underscore, and dash in friendly link url
    $str =~ s|[^\w-]+||g;

    return $str;
}

1;

