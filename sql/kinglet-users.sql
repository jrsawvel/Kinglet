-- kinglet-users.sql
-- 2-Dec-2013

drop table if exists kinglet_users;
create table kinglet_users (
    user_id		mediumint unsigned auto_increment, 
    user_name		varchar(30) not null,
    password		varchar(30) not null,
    email		varchar(100) not null,
    created_date	datetime,
    user_status		char(1) not null default 'p', -- (o) open, (p) pending, (d) deleted
    desc_markup         mediumtext,
    desc_format         mediumtext,
    digest		varchar(255) not null default '0', -- for password check during login
    orig_email          varchar(255) default NULL,
    session_id		varchar(255) not null default '0', -- send in cookie, maintain login 
    unique(user_name),   
    unique(email),
    unique(orig_email),
    primary key (user_id)
) ENGINE=MyISAM;
