var MINI = require('minified'); 
var $ = MINI.$, $$ = MINI.$$, EE = MINI.EE;

var autoSaveInterval=60000; // every 60 seconds
var intervalID=0;
 
// var dt       = new Date();
// var mepoch   = dt.getTime();
// var utcdate  = dt.toUTCString();
// var epoch    = Math.round(mepoch/1000);


var server_epoch = 0; // server time in epoch seconds
$.request('get', 'http://soupmode.com/api/v1/time/', {})
    .then(function(response) {
        var obj = $.parseJSON(response);
        server_epoch = obj['server_epoch_seconds']; 
    })
        .error(function(status, statusText, responseText) {
        // $('#new_message_count').fill('time response could not be completed.'); 
   });


$(function() {

    var old_message_count = 0;

    // autopreview every 1 minute
   intervalID = setInterval(function(){previewPost()},autoSaveInterval); 

   function previewPost () {

        if ( server_epoch == 0 ) {
            var dt       = new Date();
            var mepoch   = dt.getTime();
            mepoch       = mepoch - (autoSaveInterval * 2);
            server_epoch = Math.round(mepoch/1000);
        }

        var user_name  = getCookie('kingletusername');
        var user_id    = getCookie('kingletuserid');
        var session_id = getCookie('kingletsessionid');
          $.request('get', 'http://soupmode.com/api/v1/messages/since/' + server_epoch + '/', {user_name: user_name, user_id: user_id, session_id: session_id})
            .then(function(response) {
                 var obj = $.parseJSON(response);
                 var msg_count = obj['new_message_count']; 
                 var msg_str = msg_count + " new messages";
                 if ( msg_count == 1 ) {
                     msg_str = msg_count + " new message";                  
                 }          
                 var html_str = '<a href="http://soupmode.com">' + msg_str + '</a>';
                 if ( msg_count > old_message_count ) {
                     old_message_count = msg_count;
                     $('#new_message_count').set('innerHTML', html_str);
                     play_single_sound();
                 }
             })
            .error(function(status, statusText, responseText) {
                // $('#new_message_count').fill('response could not be completed.'); 
            });
    }

    function play_single_sound() {
        document.getElementById('audiotag1').play();
    }

// http://www.w3schools.com/js/js_cookies.asp
    function setCookie(c_name,value,exdays) {
        var exdate=new Date();
        exdate.setDate(exdate.getDate() + exdays);
        var c_value=escape(value) + ((exdays==null) ? "" : "; expires="+exdate.toUTCString());
        document.cookie=c_name + "=" + c_value;
    }

    function getCookie(c_name) {
        var c_value = document.cookie;
        var c_start = c_value.indexOf(" " + c_name + "=");
        if (c_start == -1) {
            c_start = c_value.indexOf(c_name + "=");
        }
        if (c_start == -1) {
            c_value = null;
        }
        else {
            c_start = c_value.indexOf("=", c_start) + 1;
            var c_end = c_value.indexOf(";", c_start);
            if (c_end == -1) {
                c_end = c_value.length;
            }
            c_value = unescape(c_value.substring(c_start,c_end));
        }
        return c_value;
    }


});

