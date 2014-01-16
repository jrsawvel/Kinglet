package User;
use strict;
use warnings;

my %parula_h           = _get_user_cookie_settings();

sub _get_user_cookie_settings {
    my $q = new CGI;
    my %h;
    my $cookie_prefix = Config::get_value_for("cookie_prefix");
    if ( defined($q->cookie($cookie_prefix. "userid")) ) {
        $h{userid}            = $q->cookie($cookie_prefix . "userid");
        $h{username}          = $q->cookie($cookie_prefix . "username");
        $h{sessionid}         = $q->cookie($cookie_prefix . "sessionid");
        $h{loggedin}          = 1;
        $h{current}           = defined($q->cookie($cookie_prefix . "current"))  ?  $q->cookie($cookie_prefix . "current")  :  0; 
        $h{textsize}          = defined($q->cookie($cookie_prefix . "textsize"))  ?  $q->cookie($cookie_prefix . "textsize")  :  "medium"; 
        $h{theme}             = defined($q->cookie($cookie_prefix . "theme"))  ?  $q->cookie($cookie_prefix . "theme")  :  $cookie_prefix;
    } else {
        $h{loggedin}          = 0;
        $h{userid}            = -1;
        $h{textsize}          = defined($q->cookie($cookie_prefix . "textsize"))  ?  $q->cookie($cookie_prefix . "textsize")  :  "medium"; 
        $h{theme}             = defined($q->cookie($cookie_prefix . "theme"))  ?  $q->cookie($cookie_prefix . "theme")  :  $cookie_prefix;
    }
    return %h;
}

sub get_text_size {
    return $parula_h{textsize};
}

sub get_theme {
    return $parula_h{theme};
}

sub get_logged_in_flag {
    return $parula_h{loggedin};
}

sub get_current {
    return $parula_h{current};
}

sub get_logged_in_username {
    return $parula_h{username};
}

sub get_logged_in_userid {
    return $parula_h{userid};
}

sub get_logged_in_sessionid {
    return $parula_h{sessionid};
}

1;
