-- kinglet-messages.sql
-- 21-Nov-2013

drop table if exists kinglet_messages;
create table kinglet_messages (
    message_id        mediumint unsigned auto_increment primary key,
    parent_id         mediumint unsigned not null default 0, -- (refers_to) id number of the original message that started the thread
    message_text      mediumtext not null,
    message_status    char(1) not null default 'o',  -- (o) open or approved, (d) deleted 
    author_id         smallint unsigned not null,
    author_name	      varchar(30) not null,
    created_date      datetime, 
    content_digest    varchar(255),
    recipient_names   varchar(255),
    reply_count       mediumint unsigned not null default 0,
    last_message_date datetime,
    last_message_author_name varchar(30) not null, 
    last_message_id   mediumint unsigned not null default 0,
    index(parent_id)
) ENGINE = MyISAM;

