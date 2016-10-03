package Format;

use strict;
use warnings;

use URI;

sub post_id_to_link {
    my $str = shift;

    $str = " " . $str; # hack to make regex work

    my @post_ids = ();
    my $postidsearchstr = "";
    my $postidsearchurl = Config::get_value_for("cgi_app") . "/post/";
    if ( (@post_ids = $str =~ m|\s/([0-9]+)/|gsi) ) {
        foreach (@post_ids) {
            $postidsearchstr = "<a href=\"$postidsearchurl$_\">/$_/</a>";
            $str =~ s|/$_/|$postidsearchstr|isg;
        }
    }
    $str = StrNumUtils::trim_spaces($str);
    return $str;
}

sub check_for_external_links {
    my $str = shift;

    my @a;

    my $intlink = Config::get_value_for("email_host");

    if ( @a = $str =~ m/href="(http[s]?):\/\/(www\.)?([^\/|^"]*)[\/|"]/igs ) {
        my $len = @a;
        for (my $i=0; $i<$len; $i+=3) {
            my $http = $a[$i];
            my $www =  $a[$i+1];
            my $link = $a[$i+2];

            if ( lc($link) ne $intlink ) {
                $str =~ s/href="$http:\/\/$www$link/ class="extlink" href="$http:\/\/$www$link/g;
            } else {
                $str =~ s/href="$http:\/\/$www$link/ class="intlink" href="$http:\/\/$www$link/g;
            }
        }
    }
    return $str;
}

sub hashtag_to_link {
    my $str = shift;

    $str = " " . $str . " "; # hack to make regex work

    my @tags = ();
    my $tagsearchstr = "";
    my $tagsearchurl = Config::get_value_for("cgi_app") . "/tag/";
    if ( (@tags = $str =~ m|\s#(\w+)|gsi) ) {
            foreach (@tags) {
                next if  StrNumUtils::is_numeric($_); 
                $tagsearchstr = " <a href=\"$tagsearchurl$_\">#$_</a>";
                $str =~ s|\s#$_|$tagsearchstr|is;
        }
    }
    $str = StrNumUtils::trim_spaces($str);
    return $str;
}

sub at_name_to_link {
    my $str = shift;

    $str = " " . $str . " "; # hack to make regex work

    my @tags = ();
    my $tagsearchstr = "";
    my $tagsearchurl = Config::get_value_for("cgi_app") . "/user/";
    if ( (@tags = $str =~ m|\s@(\w+)|gsi) ) {
            foreach (@tags) {
                $tagsearchstr = " <a href=\"$tagsearchurl$_\">\@$_</a>";
                $str =~ s|\s\@$_|$tagsearchstr|is;
        }
    }
    $str = StrNumUtils::trim_spaces($str);
    return $str;
}

sub create_recipient_list_str {
    my $str = shift; # using the markup code content

    $str = lc($str);

    my $recipient_list_str = "";

    $str = " " . $str . " "; # hack to make regex work
    my @recipients = ();

    if ( (@recipients = $str =~ m|\s@(\w+)|gsi) ) {
        $recipient_list_str = "|";
            foreach (@recipients) {
               my $tmp_recipient = $_;
               if ( $recipient_list_str !~ m|$tmp_recipient| ) {
                   $recipient_list_str .= "$tmp_recipient|";
               }
           }
    }
    return $recipient_list_str;
}

sub format_urls {
    my $str = shift;
    $str = _format_urls_1($str);
    $str = _format_urls_2($str);
    return $str;
}

sub _format_urls_1 {
    my $str = shift;
    my @a;

    if ( @a = $str =~ m#(^|\s)(\w+://)([A-Za-z0-9?=:\|;,_\-/.%+&'~\(\)\#@!\^]+)#isg  ) {
        my $len = @a;
        for (my $i=0; $i<$len; $i+=3) {
            my $url_str      = $a[$i+1] . $a[$i+2];
            my $uri_obj  = URI->new($url_str); 
            my $link     = _create_link($url_str, $uri_obj);
            $str =~ s/\Q$url_str/$link/s;
        }
    }
    return $str;
}

sub _format_urls_2 {
    my $str = shift;
    my @a;

    if ( @a = $str =~ m#(^|\s)(www.[A-Za-z0-9?=:\|;,_\-/.%+&'~\(\)\#@!\^]+)#isg ) {
        my $len = @a;
        for (my $i=0; $i<$len; $i+=2) {
            my $url_str  = $a[$i+1];
            my $uri_obj  = URI->new($url_str); 
            my $link     = _create_link($url_str, $uri_obj);
            $str =~ s/\Q$url_str/$link/s;
        }
    }
    return $str;
}

sub _create_link {
    my $url_str = shift;
    my $uri_obj = shift;

    my $s = $uri_obj->scheme;

    my $rest = do {
        if( ! $s ) {
            $uri_obj
            }
        elsif( $s =~ /(?:https?|ftp)/ ) {
            $uri_obj->host . $uri_obj->path_query
            }
        elsif( $s eq 'mailto' ) {
            $uri_obj->path
            }
        };

    my $final = $rest;

    if ( $final =~ m/^www\./i ) {
        $final =~ s/^www\.//i;
        $url_str = "http://" . $rest;
    }

    if ( length($final) > 30 ) {
        $final = substr $final, 0, 30;
        $final .= " ...";
    }

    my $link = "<a title=\"$url_str\" href=\"$url_str\">$final</a>";

    return $link;
}


# https://en.wikipedia.org/wiki/List_of_emoticons
# http://cool-smileys.com/text-emoticons
# http://pc.net/emoticons/smiley/angry

sub add_emojis {
    my $str = shift;

    my $image_dir = "/images/smileys/";

    my $smile     = '<img src="' . $image_dir . "smile.png"     . '">';  # :)
    my $biggrin   = '<img src="' . $image_dir . "biggrin.png"   . '">';  # :))
    my $dance     = '<img src="' . $image_dir . "dance.gif"     . '">';  # :)))
    my $wink      = '<img src="' . $image_dir . "wink.png"      . '">';  # ;)
    my $cool      = '<img src="' . $image_dir . "cool.png"      . '">';  # 8) - smiley with sunglasses
    my $eek       = '<img src="' . $image_dir . "eek.png"       . '">';  # :o  or :O
    my $frown     = '<img src="' . $image_dir . "frown.png"     . '">';  # :(
    my $mad       = '<img src="' . $image_dir . "mad.png"       . '">';  # x(  or  X(
    my $banghead  = '<img src="' . $image_dir . "banghead.gif"  . '">';  # x((  or  X((
    my $stomp     = '<img src="' . $image_dir . "stomp.gif"     . '">';  # x(((  or  X(((
    my $furious   = '<img src="' . $image_dir . "furious.gif"   . '">';  # x((((  or  X((((
    my $cry       = '<img src="' . $image_dir . "cry.gif"       . '">';  # :'(
    my $sleep     = '<img src="' . $image_dir . "sleep.gif"     . '">';  # |)
    my $help      = '<img src="' . $image_dir . "help.gif"      . '">';  # !)!



    $str =~ s|:\)\)\)|$dance|gs;
    $str =~ s|:\)\)|$biggrin|gs;
    $str =~ s|:\)|$smile|gs;
    $str =~ s|;\)|$wink|gs;
    $str =~ s|8\)|$cool|gs;
    $str =~ s|:o|$eek|igs;
    $str =~ s|:\(|$frown|gs;
    $str =~ s|x\(\(\(\(|$furious|igs;
    $str =~ s|x\(\(\(|$stomp|igs;
    $str =~ s|x\(\(|$banghead|igs;
    $str =~ s|x\(|$mad|igs;
    $str =~ s|:'\(|$cry|gs;
    $str =~ s/\|\)/$sleep/gs;
    $str =~ s/!\)!/$help/gs;


    return $str;
}


1;

