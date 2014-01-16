-- kinglet-recipients.sql
-- 2-Dec-2013

drop table if exists kinglet_recipients;
create table kinglet_recipients (
    id               mediumint unsigned auto_increment primary key,
    message_id       mediumint unsigned not null default 0, 
    user_id          smallint unsigned not null
) ENGINE = MyISAM;

