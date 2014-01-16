package Client::Dispatch;
use strict;
use Client::Modules;

my %cgi_params = Function::get_cgi_params_from_path_info("function", "one", "two", "three", "four");

my $dispatch_for = {
    homepage      =>   sub { return \&do_sub(       "Homepage",       "show_homepage"            ) },
    stream        =>   sub { return \&do_sub(       "Homepage",       "show_homepage"            ) },
    showerror     =>   sub { return \&do_sub(       "Function",       "do_invalid_function"      ) },
    addmessage    =>   sub { return \&do_sub(       "AddMessage",     "add_message"              ) },
    addreply      =>   sub { return \&do_sub(       "AddMessage",     "add_reply"                ) },
    showmessage   =>   sub { return \&do_sub(       "ShowMessage",    "show_message"             ) },
    compose       =>   sub { return \&do_sub(       "Compose",        "show_new_message_form"    ) },
    reply         =>   sub { return \&do_sub(       "Compose",        "show_new_reply_form"      ) },
    replies       =>   sub { return \&do_sub(       "Replies",        "show_replies"             ) },
    threads       =>   sub { return \&do_sub(       "Threads",        "show_threads"             ) },
    user          =>   sub { return \&do_sub(       "Profile",        "show_user"                ) },
    loginform     =>   sub { return \&do_sub(       "LoginUser",      "show_login_form"          ) },
    login         =>   sub { return \&do_sub(       "LoginUser",      "login"                    ) },
    logout        =>   sub { return \&do_sub(       "LogoutUser",     "logout"                   ) },
    settings      =>   sub { return \&do_sub(       "Profile",        "show_user_settings_form"  ) },
    customizeuser =>   sub { return \&do_sub(       "Profile",        "customize_user"           ) },
    changepassword=>   sub { return \&do_sub(       "Profile",        "change_password"          ) },
    newpassword   =>   sub { return \&do_sub(       "Profile",        "create_new_password"      ) },
    signup        =>   sub { return \&do_sub(       "Signup",         "show_signup_form"         ) },
    createnewuser =>   sub { return \&do_sub(       "Signup",         "create_new_user"          ) },
    activate      =>   sub { return \&do_sub(       "Signup",         "activate_account"         ) },
};

sub execute {
    my $function = $cgi_params{function};
    $dispatch_for->{homepage}->() if !defined $function;
    $dispatch_for->{showerror}->($function) unless exists $dispatch_for->{$function};
    defined $dispatch_for->{$function}->();
}

sub do_sub {
    my $module = shift;
    my $subroutine = shift;
    eval "require Client::$module" or do Page->report_error("user", "Runtime Error (1):", $@);
    my %hash = %cgi_params;
    my $coderef = "$module\:\:$subroutine(\\%hash)"  or do Page->report_error("user", "Runtime Error (2):", $@);
    eval "{ &$coderef };";
}

1;
