package DateTimeUtils;

use strict;
use warnings;
use Time::Local;

sub create_database_datetime_stamp {
    my $minutes_to_add = shift;

    # creates string for DATETIME field in database as
    # YYYY-MM-DD HH:MM:SS    (24 hour time)
    # Date and time is GMT not local.

    if ( !$minutes_to_add ) {
        $minutes_to_add = 0;
    }

    my $epochsecs = time() + ($minutes_to_add * 60);
    my ($sec, $min, $hr, $mday, $mon, $yr)  = (gmtime($epochsecs))[0,1,2,3,4,5];
    my $datetime = sprintf "%04d-%02d-%02d %02d:%02d:%02d", 2000 + $yr-100, $mon+1, $mday, $hr, $min, $sec;
    return $datetime;
}


# receives date string as: YYYY-MM-DD HH-MM-SS
# date format used in database date field
# code from: http://stackoverflow.com/users/4234/dreeves
# in post: http://stackoverflow.com/questions/95492/how-do-i-convert-a-date-time-to-epoch-time-aka-unix-time-seconds-since-1970
# I changed timelocal to timegm
sub convert_date_to_epoch {
  my($s) = @_;
  my($year, $month, $day, $hour, $minute, $second);

  if($s =~ m{^\s*(\d{1,4})\W*0*(\d{1,2})\W*0*(\d{1,2})\W*0*
                 (\d{0,2})\W*0*(\d{0,2})\W*0*(\d{0,2})}x) {
    $year = $1;  $month = $2;   $day = $3;
    $hour = $4;  $minute = $5;  $second = $6;
    $hour |= 0;  $minute |= 0;  $second |= 0;  # defaults.
    $year = ($year<100 ? ($year<70 ? 2000+$year : 1900+$year) : $year);
    return timegm($second,$minute,$hour,$day,$month-1,$year);  
  }
  return -1;

}

# receives formatted date and time to local time
# and converts to Z time for pubDate RSS tag as:
# Tue, 04 Oct 2005 12:52:43 Z
sub format_date_time_for_rss {
    my $date = shift;  # format as: Jun 22, 2013
    my $time = shift;  # format as: 01:34:55 PM
 
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


    $hash{date} = sprintf "%s, %02d %s %d", $dow[$wday], $day_of_month, $short_month_names[$month_of_year], 1900 + $current_year;

    $hash{time} = sprintf "%02d:%02d:%02d Z", $hours, $minutes, $seconds;

    return %hash;
}

# convert this 2013-06-23T11:52:00-04:00 into a better format
sub reformat_nws_date_time {
    my $nws_date_time_str = shift;
    
    my %hash = ();

    if ( !$nws_date_time_str ) {
        $hash{date} = "-";
        $hash{time} = "-";
        $hash{period} = "-";
        return %hash;
    }

    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

    my @values = split('T', $nws_date_time_str);

    # work on time first
    my @hrminsec = split('-', $values[1]);
    my @time = split(':', $hrminsec[0]);
    my $hr = $time[0];
    my $min = $time[1];

    my $prd = "am";
    if ( $hr >= 12 ) {
        $prd = "pm";
    }
    if ( $hr > 12 ) {
        $hr = $hr - 12;
    }
    if ( $hr == 0 ) {
        $hr = 12;
    }

    my $time_str = sprintf("%d:%02d", $hr, $min); 

    # work on date
    my @yrmonday = split('-', $values[0]);
    my $date_str = sprintf("%s %d, %d", $months[$yrmonday[1]-1], $yrmonday[2], $yrmonday[0]);

    $hash{date} = $date_str;
    $hash{time} = $time_str;
    $hash{period} = $prd;

    return %hash;
}

1;


