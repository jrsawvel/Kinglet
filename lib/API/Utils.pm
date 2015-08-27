package Utils;

use Time::Local;
use JRS::DateTimeFormatter;

# links browser does not send the http_referer var to server
sub get_http_referer {
    my $hr = $ENV{HTTP_REFERER};
    if ( !$hr ) {
        $hr = Config::get_value_for("home_page");
    }
    return $hr;
}


# http://stackoverflow.com/questions/1547899/which-characters-make-a-url-invalid
# In general URIs as defined by RFC 3986 may contain any of the following characters:
# ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;=.
#  http://tools.ietf.org/html/rfc3986
# 
# for now, username = profile/display name
# permit alphas, numerica, hyphen, underscore, and period
sub valid_username {
    my $username = shift;
    if ( !defined($username) ) {
        return 0;
    }
    $username = StrNumUtils::trim_spaces($username);
    if ( length($username) < 1 ) {
        return 0;
#    } elsif ( $username !~ /^[0-9a-zA-Z\-\_\ \.]+$/ ) { 
# 30jul2013    } elsif ( $username !~ /^[0-9a-zA-Z\-\_\.]+$/ ) { 
    } elsif ( $username !~ /^\w+$/ ) { 
        return 0;
    } elsif ( length($username) > 30 ) {
        return 0;
    }
    return 1;
}

sub valid_password {
    my $password = shift;
    if ( !defined($password) ) {
        return 0;
    }
    $password = StrNumUtils::trim_spaces($password);
    if ( length($password) < 8 ) {
        return 0;
    } elsif ( $password =~ /[ ]/ ) {
        return 0;
    } elsif ( length($password) > 30 ) {
        return 0;
    }

    return 1;
}


sub is_strong_password {
    my $password = shift;

    my @alpha = $password =~ m/([a-z0-9])/ig;
    my $alpha_len = @alpha;
#    return 0 if $alpha_len < 4; 
# made this change on Aug 22, 2014
# no longer requires a password to contain at least 2 digits and 2 punct chars
# length must contain at least 10 alpha-numeric chars.
return 0 if $alpha_len < 10; 
return 1;


    my @digit = $password =~ m/(\d)/g;
    my $digit_len = @digit;
    return 0 if $digit_len < 2; 

    my @lucky = $password =~ m/([!@\$%\^&\*])/g;
    my $lucky_len = @lucky;
    return 0 if $lucky_len < 2; 

    return 1;
}


sub otp_encrypt_decrypt {

##     Otp v1.0
##     Last modified: March 2nd, 2000
##
##     Copyright (c) 2000 by Trans-Euro I.T Ltd
##     All Rights Reserved
##
##     E-Mail: tigger@marketrends.net
##
##	This module can be used to encrypt and decrypt
##	character strings. Using an xor operation.
##	As long as the same 'key' is used, the original
##	string can always be derived from its encryption.
##	The 'key' may be any length although keys longer
##	than the string to be encrypted are truncated.


    my $P1 = shift;
    my $K1 = shift;
    my $func = shift;


    if ( $func eq "dec" ) {
        $P1 =~ s/%([a-f0-9][a-f0-9])/chr( hex( $1 ) )/eig; 
    }

    my @_p = ();
    my @_k = ();
    my @_e = ();
    my $_l = "";
    my $_i = 0;
    my $_r = "";

    while ( length($K1) < length($P1) ) { $K1=$K1.$K1;}

    $K1=substr($K1,0,length($P1));

    @_p=split(//,$P1);
    @_k=split(//,$K1);

    foreach $_l (@_p) {
       $_e[$_i] = chr(ord($_l) ^ ord($_k[$_i]));
       $_i++;
                      }

    $_r = join '',@_e;

    if ( $func eq "enc" ) {
        $_r =~ s/([^a-z0-9_.!~*() -])/sprintf "%%%02X", ord($1)/eig;
    }

    return $_r;    
}

sub get_time_offset {
    my $offset = -5;     # EST offset from GMT
    # determine if it's daylight savings time for eastern time zone
    my $isdst = (localtime)[8];
    if ( $isdst ) {
        $offset = -4;
    } 
    return $offset;
}

# creates string for DATETIME field in database as
# YYYY-MM-DD HH:MM:SS    (24 hour time)
# Date and time is GMT not local.
sub create_datetime_stamp {
    return DateTimeFormatter::create_date_time_stamp_utc("(yearfull)-(0monthnum)-(0daynum) (24hr):(0min):(0sec)"); 
}

sub get_power_command_on_off_setting_for {
    my ($command, $str, $default_value) = @_;

    my $binary_value = $default_value;   # default value should come from config file
    
    if ( $str =~ m|^$command[\s]*=[\s]*(.*?)$|mi ) {
        my $string_value = StrNumUtils::trim_spaces(lc($1));
        if ( $string_value eq "no" ) {
            $binary_value = 0;
        } elsif ( $string_value eq "yes" ) {
            $binary_value = 1;
        }
    }
    return $binary_value;
}

sub format_date_time_for_rss {
    my $date = shift;
    my $time = shift;
 
    my %hash = ();
 
    my @short_month_names = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    
    my %months = (Jan => 0, 
                  Feb => 1,
                  Mar => 2,
                  Apr => 3,
                  May => 4,
                  Jun => 5,
                  Jul => 6,
                  Aug => 7,
                  Sep => 8,
                  Oct => 9,
                  Nov => 10,
                  Dec => 11);

    my @dow = qw(Sun Mon Tue Wed Thu Fri Sat);
 
    $time =~ m/(\d+):(\d+):(\d+)/; 
    my $hr  = $1;
    my $min = $2;
    my $sec = $3;

    if ( $time =~ m/pm/i and $hr != 12 ) {
        $hr+=12;    
    }

    $date =~ m/(\w+) (\d+), (\d+)/g;
    my $mon = $months{$1};
    my $day = $2;
    my $year = $3 - 1900;

    my $time_1 = timelocal($sec, $min, $hr, $day, $mon, $year); 

    my ($seconds, $minutes, $hours, $day_of_month, $month_of_year, $current_year, $wday) = (gmtime($time_1))[0,1,2,3,4,5,6];

    # pubDate format: Tue, 04 Oct 2005 12:52:43 Z

    $hash{date} = sprintf "%s, %02d %s %d", $dow[$wday], $day_of_month, $short_month_names[$month_of_year], 1900 + $current_year;

    $hash{time} = sprintf "%02d:%02d:%02d Z", $hours, $minutes, $seconds;

    return %hash;
}

sub format_creation_date {
    my $creationdate = shift;
    my $dateepochseconds = shift;

#    my $offset = Utils::get_time_offset();
    my $offset = 0;

    my $current_epochseconds = time(); 
    my $twenty_four_hours = 86400;

#    my $tmp_offset = $offset - 3;   # include the three hours for Pacific time for server location
     my $tmp_offset = 0;

       my $tmp_dateepochseconds = $dateepochseconds + (3600 * $tmp_offset);
       my $tmp_diff = $current_epochseconds - $tmp_dateepochseconds;

       if ( $tmp_diff < $twenty_four_hours ) {
           $creationdate = " ";
           if ( $tmp_diff < 3600 ) {
               my $tmp_min = int($tmp_diff / 60); 
               if ( $tmp_min == 0 ) {
                   $creationdate = $tmp_diff . " secs ago";
               } elsif ( $tmp_min == 1 ) {
                   $creationdate = $tmp_min . " min ago";
               } else {
                   $creationdate = $tmp_min . " mins ago";
               }
           } else {
               my $tmp_hr = int($tmp_diff / 3600); 
               if ( $tmp_hr == 1 ) {
                   $creationdate = $tmp_hr . " hr ago";
               } else {
                   $creationdate = $tmp_hr . " hrs ago";
               }
           }
       }
    return $creationdate;
}

1;

