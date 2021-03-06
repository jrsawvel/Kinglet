# Kinglet User and Programmer Documentation 

Example usage: [http://soupmode.com](http://soupmode.com)

It's a simple, web-based, private messaging app. It uses a basic, responsive design. It contains only a small number of functions. It's part microblog, part e-mail, and part message board.

This web app was created to communicate with friends and family in a different way and to practice API development. The API code is written in Perl, and it only returns JSON.  

The "client" code that accesses the API also exists on the same server, and it is currently written in Perl, but a Node.js "client" will be created. These server-side client pieces could exist on servers different than the API server. 

By having the API created, I can practice creating client code that is written in JavaScript that runs in the browser as a single page application. I can practice iOS and Android app development.

The API code receives REST requests, talks to the database, processes data, and returns JSON. Test scripts work against the API. 


## User Help

### Create an Account

* User visits the sign-up page.
* User enters a username and an e-mail address.
* If configured, the system will send an e-mail with an auto-generated password and a link to activate the account. If the system is set to debug mode, then the password and the activation link will be sent to the browser. In debug mode, a user does not need to provide a valid e-mail address, since no e-mail is sent. But the user needs to provide an e-mail with valid syntax.
* User clicks the link to activate the account.


### Login

* At the homepage or on the login page, the user enters the e-mail address, used to create the account and the password, generated by the system.
* Optionally, a user can check the save login box to avoid having to login the next time the user accesses the site. If using multiple devices, the save login box will have to be checked for each device if the user wants to avoid logging in on all devices.
* If the user forgets the password, the user can request the system to create a new password by entering the username and e-mail address in lost password section of the login page. If configured, the system will send an e-mail with the new password. If the system is in debug mode, then the new password is displayed to the browser.


### Logout

* To remove the save login cookie from the device's browser, the user needs to click the logout link.


### Profile Page

* To change password, e-mail address, or profile description information, the user clicks on his or her username, located in the navigation bar at the top of the site. 
* Next, the user clicks on ``"Change your password, e-mail address, or description info"`` and follows the form fields accordingly. 
* The e-mail address not seen by anyone else.
* If the user enters description or profile information, this information is only seen by others who are on the user's approved list.


### Approved List

* Unless the user only wants to communicate with himself, the user needs to know someone else who has created an account.
* On the profile page, the user enters the username of a known user and clicks the Request Approval button under the text line that says:
  * "In order to message another user, you need to request permission to be added to the user's approved list."
* Users can message others only if the user is on the others' approved list.
* When the user sends the request, that other person is automatically added to the user's approved list as "approved." 
* A user can send only one request to another user.
* If a user tries to send another request, the user will receive one of three messages:
  * request is still pending
  * request was approved
  * request was rejected
* When the other person has approved or rejected the request, the user will receive a system-generated message, indicating what type of action was taken.
 * "System Message: Your request to be added to xxxx's approved list has been approved." (or rejected)
* On the same profile page, the user can click ``"Approval requests received"`` to see if any new requests are pending or to change the status of previous requests. The user can modify his approved list by changing a user's status from approved to rejected and vice versa.


### Messages

* The homepage shows a stream of all messages sent and received.
* Sent messages appear with a light blue background, and the text is displayed smaller and grayer. 
* Received messages appear with a light green background, and the text is displayed larger and darker.
* Each message bubble displayed on the homepage contains links for:
 * displaying the individual message
 * displaying all the messages for the thread
 * replying to the thread
* Each message bubble on the homepage also shows the usernames who received the message.


### Create New Message

* A new message is limited to a max of 300 characters.
* To create a new message, the user clicks the ``"new"`` link, located in the navigation bar.
* In the message box, the user adds the usernames who should receive the message.
* Each username is preceded with the at-sign.
* If multiple recipients, then each username is separated by at least one space.
* Example: 
 * @userA @userB @userC Hello. This is a test message.
* If the user has not been added to a recipient's approved list, then the message will not be sent. Example message:
 * "Error: Bad Request - You cannot message 'userA' because your request to be added to the user's approved list is still pending a decision by the user." (or has been rejected)
* If the user creates or receives a new message that starts a new thread, then that message bubble on the homepage contains an orange bar at the bottom of the bubble.


### Reply to a Message

* A reply message is limited to a max of 300 characters.
* On the homepage, the user can reply to a thread by clicking the ``"reply"`` link.
* Even though each reply contains a reply link, this is not a threaded discussion. Replies to replies to replies is not supported.
* Each reply is for the thread or the message that started the thread. It's like posting a comment to a message board that uses a flat commenting system, where the new comment appears at the bottom of the thread.
* When the user clicks the reply link on the homepage for a message, the first message that started the thread is displayed above the message box, along with a link to the entire thread.
* Clicking the ``"thread"`` link for a message on the homepage will also display the entire thread.


### Show Message

* On the homepage and on the page that shows the entire discussion thread, each message contains its own permalink, which is the date that the message was created.
* Clicking the permalink for a message will display that individual message on its own page.
* When showing a message on its own page, a link will be displayed at the top of the page called ``"discussion thread,"`` which will take the user back to the page that shows the entire discussion thread.
* Also when showing the message on its own page, a reply link exists.


### Threads

* In the navigation bar, a link called ``"threads"`` exists.
* The threads link will show all discussion threads that the user has posted to. These could be discussion threads that the user started, or threads where the user was included on the original message sent by someone else.
* The threads page shows a small portion of the original message that started the thread and the number of replies for that thread. The replies count is a link to that discussion thread.

---

## Programmer Help

  

Kinglet API description. It's currently being used at Soupmode.com. 

It uses REST and JSON.

Each function below is preceded with ``/api/v1`` in the URI. So for Soupmode, it would be ``http://soupmode.com/api/v1``.

Example of activating a new user account:  
``http://soupmode.com/api/v1/users/activate/ru8wkn0ol2ql3bm9``

At the moment, I don't have SSL enabled at Soupmode.com, and OAuth is not used. Strengthening authentication is on the to-do list.


### Users

Except for activating a user account, URIs for GETs and PUTs end with the query string:  
``/?user_name=[user_name]&user_id=[user_id]&session_id=[session_id]``

* Retrieve profile page info for user name JR.  
GET request.  
``/users/JR``

* Create a new user account.  
POST request.  
``/users``  
Client sends JSON to the API:  
``{ "user_name" : "userA", "email"     : "usera@usera.com" }``

* Activate user account.  
GET request.  
``/users/activate/[user_digest]``

* Logout user JR.  
GET request.  
``/users/JR/logout``

* Login user.  
Post request.  
``/users/login``  
Client sends JSON to the API:  
``{ "email"     : "usera@usera.com", "password" : "plaintextpwd" }``

* Retrieve new password for existing account. User would not be logged in. This would be executed for someone who forgot or lost a password.  
POST request.  
``/users/password``  
Client sends JSON to the API:  
``{ "user_name" : "userA", "email"     : "usera@usera.com" }``

* Change password for existing account. User must be logged-in.  
PUT request.  
``/users/password``

* Update e-mail and/or profile description for the user.  
PUT request.  
``/users``


### Lists

In order for User A to message User B, User A needs to be added to User B's approved list of users for messaging. 

When User A makes the request to User B, then User B is automatically added to User A's approved list. User A must wait for User B to approve or reject the request.

URIs for GETs end with the query string:  
``/?user_name=[user_name]&user_id=[user_id]&session_id=[session_id``

* Request to be added to a recipient's approved list of users. User A makes the request to User B.  
GET request.  
``/lists/request/userb``

* Reject the request from user JR to add JR to the other user's approved list.  
GET request.  
``/lists/reject/JR``

* Approve the request from user JR.  
GET request.  
``/lists/approve/JR``

* Logged-in user shows the list of requests received, so that the user can either reject or approve the requests.  
GET request.  
``/lists/requests``


### Messages

For GET requests, each URI ends with the query string:  
``/?user_name=[user_name]&user_id=[user_id]&session_id=[session_id]``

The POST requests will also need the above name=value pairs encoded and sent to the API.

Example displaying message number 5:  
GET request.  
``http://soupmode.com/api/v1/messages/5/?user_name=JR&user_id=23&session_id=ru8er03jjg3k40vjl09``

* Show all messages created by or sent to the logged-in user. This message stream is displayed on the site's homepage.  
GET request.  
``/messages``

* Show page three of the stream.  
GET request.  
``/messages/page/3``

* For the logged-in user, get all new messages received since the supplied date, which is provided in epoch seconds. I access this from the client-side JavaScript.  
GET request.  
``/messages/since/[date]``

* Retrieve message ID number 5.  
GET request.  
``/messages/5``

* Create a new message.  
POST request.   
``/messages``  
In addition to the name=value logged-in credentials listed above, the client sends the following JSON to the API:  
``{ "message_text" : "this is the message text." }``

* Retrieve all reply messages for message ID number 5.  
GET request.  
``/messages/5/replies``

* Create a reply message to message ID number 5.  
POST request.  
``/messages/5/replies``  
In addition to the name=value logged-in credentials listed above, the client sends the following JSON to the API:  
``{ "message_text" : "this is the reply message text.", "reply_to_id" : 5, "reply_to_content_digest" : "sue83jlg9j4qo9l" }``

* List the messages that start new discussions.  
GET request.  
``/messages/threads``


### Returned JSON

If a 400 or 500 type of error, the JSON will return a user_message and system_message.

Example:

    {
        "status"          :  "404",
        "description"     :  "Not Found",
        "user_message"    :  "Invalid input.",
        "system_message"  :  "Username and/or e-mail does not exist."
    }


#### Create New User Account

    {
        "status"       :  201,
        "description"  :  "Created",
        "user_id"      :  "9",
        "user_name"    :  "1389906958",
        "password"     :  "khd7vj4m",
        "email"        :  "1389906958@test.com",
        "user_digest"  :  "p7X4CwwLSuqD2bjYIATcw"      
    }


#### Activate Account

    {
        "status"           :  200,
        "description"      :  "OK",
        "activate_account" : "true"
    }


#### Log In

    {
        "status"      :  200,
        "description" :  "OK",
        "user_id"     :  "17",
        "user_name"   :  "kinglettest1389911089",
        "session_id"  :  "LUb83Dw38nnqMOI47NVZw"
    }


#### Successfully Change Password

    {
        "status"      :  200,
        "user_id"     :  "20",
        "user_name"   :  "kinglettest1389912835",
        "session_id"  :  "3Ms41qwZfjuHW2kUmNeOg"
    }


#### Successfully Updated User Profile Page

    {
        "status"           :  200,
        "description"      : "OK",
        "profile_updated"  : "true"
    }


#### Successfully Displayed User Profile Page for Logged-in User

    {
        "status"        :  200,
        "description"   :  "OK",
        "user_id"       :  "21",
        "user_name"     :  "kinglettest1389915584",
        "email"         :  "kinglettest1389915584@testnew.com",
        "user_status"   :  "o",
        "digest"        :  "q5JUMA9YC2GgkMwb8s19Mg",
        "desc_markup"   :  "this is my boring profile page.",
        "desc_format"   :  "this is my boring profile page.",
        "created_date"  :  "Jan 16, 2014"
    }


#### Successfully Displayed User Profile Page for Another User

If the user is on the other user's approved list.

    {
        "status"        :  200,
        "description"   :  "OK",
        "user_name"     :  "kinglettest1389915584",
        "desc_format"   :  "this is my boring profile page."
    }



#### Successfully Retrieved New Password

    {
        "status"        :  200,
        "description"   :  "OK",
        "email"         :  "kinglettest1389921202@test.com",
        "new_password"  :  "7rqqawh8"
    }


#### Unsuccessfully Retrieved New Password

    {
        "status"          :  "404",
        "description"     :  "Not Found",
        "user_message"    :  "Invalid input.",
        "system_message"  :  "Username and/or e-mail does not exist."
    }


#### Successfully Logged Out

    {
        "status"       :  200,
        "description"  :  "OK",
        "logged_out"   :  "true"
    }


#### Successfully Submitted Approved List Request

    {
        "status"         :  200,
        "description"    :  "OK",
        "made_request"   :  "true"
    }


#### Re-submitting the Same Approved List Request

    {
        "status"          :  400,
        "description"     :  "Bad Request",
        "request_status"  :  "pending",
        "user_message"    :  "Request made earlier.",
        "system_message"  :  "Request is pending approval by the recipient."
    }


#### Re-submitting the Same Approved List Request After Being Rejected

    {
        "status"          :  400,
        "description"     :  "Bad Request",
        "request_status"  :  "rejected",
        "user_message"    :  "Request made earlier.",
        "system_message"  :  "Recipient has already rejected the requester."
    }


#### Re-submitting the Same Approved List Request After Being Approved

    {
        "status"          :  400,
        "description"     :  "Bad Request",
        "request_status"  :  "approved",
        "user_message"    :  "Request made earlier.",
        "system_message"  :  "Recipient has already approved the requester."
    }


#### Approving or Rejecting a Request

    {
        "status"       :  200,
        "description"  :  "OK"
    }


#### List of Approval Requests Received

    {
        "status"       :  200,
        "description"  :  "OK",
        "requests"     :
          [
            {
                "status"        :  "approved",
                "created_date"  :  "Feb 12, 2014",
                "user_name"     :  "testuser1"
            },
            {
                "status"        :  "rejected",
                "created_date"  :  "Feb 25, 2014",
                "user_name"     :  "testuserA"
            },
            {
                "status"        :  "rejected",
                "created_date"  :  "Feb 25, 2014",
                "user_name"     :  "testuserB"
            },
            {
                "status"        :  "rejected",
                "created_date"  :  "Feb 25, 2014",
                "user_name"     :  "testuserC"
            }
          ]
    }


#### Successfully Created a New Message

    {
        "status"       :  201,
        "description"  :  "Created",
        "message_id"   :  "35"
    }


#### Successfully Read a Message

    {
        "status"           :  200,
        "description"      :  "OK",
        "message_id"       :  "36",
        "parent_id"        :  "0",
        "reply_count"      :  "0",
        "author_id"        :  "32",
        "author_name"      :  "kinglettest1389981418",
        "recipient_names"  :  "|kinglettest1389981418|",
        "message_text"     :  "<a href=\"/user/kinglettest1389981418\">@kinglettest1389981418</a> sending a messsage to myself."
        "content_digest"   :  "yGK8VYhKj5dJV7AhJMNP9Q",
        "created_date"     :  "Jan 17, 2014 at 06:03:54 PM",
        "message_status"   :  "o"
    }



#### Successfully Added Reply Message

    {
        "status"      :  201,
        "description" :  "Created",
        "message_id"  :  "37"
    }



#### Successfully Retrieving All Replies

    {
        "status"          :  200,
        "description"     :  "OK",
        "next_link_bool"  :  0,
        "messages":
          [
            {
                "message_id"       :  "37",
                "parent_id"        :  "36",
                "message_status"   :  "o",
                "recipient_names"  :  "kinglettest1389981418",
                "author_name"      :  "kinglettest1389981418",
                "author_type"      :  "you",
                "logged_in_user"   :  "32",
                "created_date"     :  "1 hr ago",
                "message_text"     :  "This is a reply message.","reply_count":"0"
            }
          ]
    }



#### Successfully Retrieved All of a User's Messages, Sent and Received

    {
        "messages" 
          [
            {
                "author_name"      :  "kinglettest1389981418",
                "message_id"       :  "37",
                "message_status"   :  "o",
                "created_date"     :  "1 hr ago",
                "parent_id"        :  "36",
                "recipient_names"  :  "kinglettest1389981418",
                "author_type"      :  "you",
                "logged_in_user"   :  "32",
                "message_text"     :  "This is a reply message.",
                "reply_count"      :  "0"
            },
            {
                "author_name"      :  "kinglettest1389981418",
                "message_id"       :  "36",
                "message_status"   :  "o",
                "created_date"     :  "2 hrs ago",
                "parent_id"        :  "0",
                "recipient_names"  :  "kinglettest1389981418",
                "logged_in_user"   :  "32",
                "author_type"      :  "you",
                "message_text"     :  "<a href=\"/user/kinglettest1389981418\">@kinglettest1389981418</a> sending a messsage to myself.",
                "reply_count"      :  "1"
            }
          ],
        "status"          :  200,
        "description"     :  "OK",
        "next_link_bool"  :  0
    }


#### No New Messages Received Since a Specified Date

    {
        "status"             :  200,
        "description"        :  "OK",
        "new_message_count"  :  0
    }


#### Successfully retrieved all new messages that start new discussions threads involving the user

    {
        "status"       :  200,
        "description"  :  "OK",
        "threads"      :
          [
            {
                "author_name"               :  "kinglettest1389981418",
                "last_message_date"         :  "2 hrs ago",
                "message_id"                :  "36",
                "created_date"              :  "2 hrs ago",
                "last_message_id"           :  "37",
                "recipient_names"           :  "kinglettest1389981418",
                "logged_in_user"            :  "32",
                "message_text"              :  "sending a messsage to myself.",
                "last_message_author_name"  :  "kinglettest1389981418",
                "reply_count"               :  "1"
            }
          ]
    }


#### Retrieve Server Time

    {
        "status"                :  200,
        "description"           :  "OK",
        "server_epoch_seconds"  :  1389992757
    }


