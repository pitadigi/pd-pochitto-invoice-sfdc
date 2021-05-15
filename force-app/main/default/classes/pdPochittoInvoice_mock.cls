global class pdPochittoInvoice_mock implements HttpCalloutMock {
    global HttpResponse respond(HTTPRequest req) {
        String endPoint = req.getEndpoint();
        String method = req.getMethod();

        HttpResponse res = new HttpResponse();

        if (endPoint == 'callout:Auth0/api/v2/users') {
            res.setStatusCode(201);
        }
        else if (endPoint == 'callout:Auth0/oauth/token') {
            res.setStatusCode(200);
            String body = '{"token_type": "Bearer","access_token": "eyJXXXXXXXX"}';
            res.setBody(body);
        }
        else if (method == 'POST' && endPoint == 'callout:PochittoInvoiceApi/api/maintenance/userenv') {
            res.setStatusCode(201);
            String body = '{"result": "OK","errorMessage": ""}';
            res.setBody(body);
        }
        else if (method == 'DELETE' && endPoint == 'callout:PochittoInvoiceApi/api/maintenance/userenv') {
            res.setStatusCode(200);
            String body = '{"result": "OK","errorMessage": ""}';
            res.setBody(body);
        }

        return res;
    }
}
