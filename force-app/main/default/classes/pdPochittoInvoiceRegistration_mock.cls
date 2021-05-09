global class pdPochittoInvoiceRegistration_mock implements HttpCalloutMock {
    global HttpResponse respond(HTTPRequest req) {
        String endPoint = req.getEndpoint();

        HttpResponse res = new HttpResponse();

        if (endPoint == 'callout:Auth0/api/v2/users') {
            res.setStatusCode(201);
        }
        else if (endPoint == 'callout:PochittoInvoiceApi/api/registration') {
            res.setStatusCode(201);
            String body = '{"result": "OK","errorMessage": ""}';
            res.setBody(body);
        }
        else if (endPoint == 'callout:Auth0/oauth/token') {
            res.setStatusCode(200);
            String body = '{"token_type": "Bearer","access_token": "eyJXXXXXXXX"}';
            res.setBody(body);
        }

        return res;
    }
}
