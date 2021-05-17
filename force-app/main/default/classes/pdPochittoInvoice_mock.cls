global class pdPochittoInvoice_mock implements HttpCalloutMock {
    global HttpResponse respond(HTTPRequest req) {
        String endPoint = req.getEndpoint();
        String method = req.getMethod();

        HttpResponse res = new HttpResponse();

        if (endPoint.startsWith('callout:Auth0/api/v2/users')) {
            if (method == 'POST') {
                res.setStatusCode(201);
            } else if (method == 'PATCH') {
                res.setStatusCode(200);
            } else if (method == 'DELETE') {
                res.setStatusCode(204);
            } else if (method == 'GET') {
                res.setStatusCode(200);
                String body = '[{"user_id": "auth0|aaaaa"}]';
                res.setBody(body);
            }
        }
        else if (endPoint.startsWith('callout:Auth0/oauth/token')) {
            res.setStatusCode(200);
            String body = '{"token_type": "Bearer","access_token": "eyJXXXXXXXX"}';
            res.setBody(body);
        }
        else if (endPoint.startsWith('callout:PochittoInvoiceApi/api/maintenance/userenv')) {
            if (method == 'POST') {
                res.setStatusCode(201);
                String body = '{"result": "OK","errorMessage": ""}';
                res.setBody(body);
            } else if (method == 'DELETE') {
                res.setStatusCode(200);
                String body = '{"result": "OK","errorMessage": ""}';
                res.setBody(body);
            } else if (method == 'PUT') {
                res.setStatusCode(200);
                String body = '{"result": "OK","errorMessage": ""}';
                res.setBody(body);
            }
        }

        return res;
    }
}
