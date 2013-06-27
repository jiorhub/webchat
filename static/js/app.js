var MESSAGE_TYPES = {
    1: 'other',
    2: 'owner',
    3: 'system' 
};

function getNewLine(user, message, type) {
    var user_info = $("<div class='user-info'>" + user + "</div>");
    if (type)
        user_info.addClass('user-info-' + MESSAGE_TYPES[type]);
    return $("<div class='line'></div>")
        .append(user_info)
        .append("<div class='text'>" + message + "</div>");
}

$(document).ready(function() {
    var send_button = $("#send-button");
    var message = $("#message");
    var contacts = $("#contacts");
    var status = $("#status");
    var chat = $("#chat");

    var location = window.location.href;
    location = location.substr(7, location.indexOf('/', 7));

    var webSocket = new WebSocket("ws://" + location + "ws");
    webSocket.onopen = function(event) {
        chat.append(getNewLine('system', 'Connect to server', 3));
    };    
    
    webSocket.onclose = function(event) {
        chat.append(getNewLine('system', 'Disconnect server', 3));
    };

    webSocket.onmessage = function(event) {
        var mess = JSON.parse(event.data);
        chat.append(getNewLine(mess.user, mess.text, 1));           
    };

    function send_message(message) {
        message = message.trim();
        if (message) {
            var mess = {'user': username, 'text': message};
            webSocket.send(JSON.stringify(mess));
            chat.append(getNewLine(username, message, 2));
            chat.animate({ scrollTop: chat[0].scrollHeight }, "slow");  
        }   
    }

    send_button.click(function() {
        send_message(message.val());
        message.val('');    
    });

    message.keyup(function(e) {
        if(e.which == 13) {
            send_message(message.val());
            message.val("");
        }
    });
});
