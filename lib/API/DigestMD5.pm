package DigestMD5;

use strict;
use warnings;

use Digest::MD5;

sub create {
    my @params = @_;

    my $md5 = Digest::MD5->new;

    foreach my $p (@params) {
        $md5->add(lc($p));
    }

    return $md5->b64digest;
}

1;

