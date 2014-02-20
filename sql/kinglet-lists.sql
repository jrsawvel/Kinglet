drop table if exists kinglet_lists;
create table kinglet_lists (
    id                     mediumint unsigned NOT NULL auto_increment primary key,
    requester_user_id      mediumint unsigned NOT NULL,
    recipient_user_id      mediumint unsigned NOT NULL,
    status                 char(1) NOT NULL default 'x',
    created_date           datetime,
    modified_date          datetime,
    unique(requester_user_id, recipient_user_id)
) ENGINE=MyISAM;
