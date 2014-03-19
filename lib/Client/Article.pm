package Article;

sub show_static_page {
    my $tmp_hash = shift;  

    my @pages = qw(about help);

    my $page_to_display = $tmp_hash->{one};

    if ( !defined($page_to_display) or !$page_to_display ) {
        Page->report_error("user", "Request could not be completed.", "No web page provided.");
    }

    my $valid_page = 0;
    foreach ( @pages ) {
        $valid_page = 1 if $_ eq $page_to_display;
    } 
        
    if ( !$valid_page ) { 
        Page->report_error("user", "Request could not be completed.", "Web page '$page_to_display' does not exist.");
    }


   my $t = Page->new($page_to_display);
   $t->display_page(ucfirst($page_to_display));

}

1;
