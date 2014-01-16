drop table if exists kinglet_sessionids;
create table kinglet_sessionids (
  id 			        mediumint unsigned NOT NULL auto_increment primary key,
  user_id 		        mediumint unsigned NOT NULL,
  session_id		        varchar(255) not null default '0', -- send in cookie, maintain login 
  created_date	                datetime,
  session_status               	char(1) NOT NULL default 'x', -- o open, d deleted
  unique(user_id,session_id)
) ENGINE=MyISAM;
