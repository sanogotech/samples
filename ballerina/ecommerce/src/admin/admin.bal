import ballerina/http;
import laf/commons as x;

http:Client cartClient = new("http://localhost:8080/ShoppingCart");
http:Client orderMgtClient = new("http://localhost:8081/OrderMgt");
http:Client billingClient = new("http://localhost:8082/Billing");
http:Client shippingClient = new("http://localhost:8083/Shipping");

service Admin on new http:Listener(8084) {

    @http:ResourceConfig {
        path: "/checkout/{accountId}"
    }
    resource function checkout(http:Caller caller, http:Request request, int accountId) returns @tainted error? {
        http:Response resp = check cartClient->get("/items/" + <@untainted> accountId.toString());
        x:Item[] items = check x:Item[].constructFrom(check resp.getJsonPayload());
        if items.length() == 0 {
            http:Response respx = new;
            respx.statusCode = 400;
            respx.setTextPayload("Empty cart");
            check caller->respond(respx);
            return;
        }
        x:Order order = { accountId, items };
        resp = check orderMgtClient->post("/order", <@untainted> check json.constructFrom(order));
        string orderId = check resp.getTextPayload();
        x:Payment payment = { orderId };
        resp = check billingClient->post("/payment", <@untainted> check json.constructFrom(payment));
        string receiptNumber = check resp.getTextPayload();
        x:Delivery delivery = { orderId };
        resp = check shippingClient->post("/delivery", <@untainted> check json.constructFrom(delivery));
        string trackingNumber = check resp.getTextPayload();
        _ = check cartClient->delete("/items/" + <@untainted> accountId.toString());
        check caller->ok(<@untainted> { accountId: accountId, orderId: orderId, receiptNumber: receiptNumber, 
                                        trackingNumber: trackingNumber });
    }

}