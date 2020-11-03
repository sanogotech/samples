import ballerina/http;

http:WebSocketCaller[] callers = [];

@http:WebSocketServiceConfig {
    path: "/ws/subscribe"
}
service subscriber on new http:Listener(8080) {

    resource function onOpen(http:WebSocketCaller caller) {
        callers.push(caller);
    }

}

service broadcaster on new http:Listener(8081) {

    resource function broadcast(http:Caller caller, http:Request request) 
                                returns @tainted error? {
        foreach var targetCaller in callers {
            check targetCaller->pushText(check request.getTextPayload());
            check caller->ok();
        }
    }

}
