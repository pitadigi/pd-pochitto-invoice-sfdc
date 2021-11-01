global class pdPIHttpCallout_mock implements HttpCalloutMock {
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
        else if (endPoint.startsWith('callout:PochittoInvoiceApi/api/maintenance/invoice')) {
            if (method == 'GET') {
                res.setStatusCode(200);
                String body = '{"result": "OK","errorMessage": "", "issueCount": 100, "pageCount": 200, "issuePostalCount": 10, "pagePostalCount": 20}';
                res.setBody(body);
            }
        }
        else if (endPoint == 'callout:Freee/companies') {
            if (method == 'GET') {
                res.setStatusCode(200);
                String body = '{"companies": [{"id": 12345678}]}';
                res.setBody(body);
            }
        }
        else if(endPoint.startsWith('callout:Freee/partners')) {
            if(method == 'GET') {
                res.setStatusCode(200);
                String body = '{"partners": [{"id": 12345}]}';
                res.setBody(body);
            }
            else if(method == 'POST') {
                res.setStatusCode(201);
                String body = '{"partner": {"id": 12345}}';
                res.setBody(body);
            }
            else if(method == 'PUT') {
                res.setStatusCode(200);
                String body = '{"partner": {"id": 12345}}';
                res.setBody(body);
            }
        }
        else if(endPoint.startsWith('callout:Freee/invoices')) {
            if(method == 'POST') {
                res.setStatusCode(201);
            }
        }
        else if(endPoint.startsWith('callout:Freee/account_items')) {
            if(method == 'GET') {
                res.setStatusCode(200);
                String body = '{"account_items": [{"id": 12345678, "name": "売上高", "default_tax_code": 123}]}';
                res.setBody(body);
            }
        }
        else if(endPoint.startsWith('callout:Svf/oauth2')) {
            res.setStatusCode(200);
            String body = '{"token": "eyJXXXXXXXX"}';
            res.setBody(body);
        }
        else if(endPoint.startsWith('callout:Svf/resources')) {
            if(method == 'POST') {
                res.setStatusCode(201);
            } else if (method == 'DELETE') {
                res.setStatusCode(204);
            }                
        }

        return res;
    }
}
