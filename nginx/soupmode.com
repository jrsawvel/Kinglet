
##########
# SOUPMODE Default
##########

server {
	listen   80; ## listen for ipv4; this line is default and implied
	listen   [::]:80 default ipv6only=on; ## listen for ipv6

	# Make site accessible from http://localhost/
	server_name soupmode.com www.soupmode.com;

        return 301 https://$host$request_uri;
}


server {
    listen 443 ssl;
    
    server_name soupmode.com www.soupmode.com;

    ssl_certificate /etc/nginx/ssl/unified.crt;
    ssl_certificate_key /etc/nginx/ssl/ssl.key;


        location ~ ^/(css/|javascript/) {
          root /home/kinglet/Kinglet/root;
          access_log off;
          expires max;
        }

        location /api/v1 {
	     root /home/kinglet/Kinglet/root/api/v1;
             index kingletapi.pl;
             rewrite  ^/(.*)$ /kingletapi.pl?query=$1 break;
             fastcgi_pass  127.0.0.1:8999;
             fastcgi_index kingletapi.pl;
             fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
             include fastcgi_params;
        }

        location / {
	     root /home/kinglet/Kinglet/root;
#            rewrite  ^/(.*)$  http://soupmode.com/index.pl/$1  permanent;
             index kinglet.pl;
             rewrite  ^/(.*)$ /kinglet.pl?query=$1 break;
             fastcgi_pass  127.0.0.1:8999;
             fastcgi_index kinglet.pl;
             fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
             include fastcgi_params;
        }
}

