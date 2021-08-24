public with sharing class pdPISvf {
    public virtual class BaseException extends Exception {}
    public class OtherException extends BaseException {}

    /**
     * 契約に関するフォルダ、初期レポート(トライアルで利用)を登録する
     */
    public Boolean regist(String contractId) {
        Boolean result = true;

        try {
            String accessToken = this.getAccessToken();

            this.createResourceFolder(contractId, accessToken);

            this.uploadForms(contractId, accessToken);
        } catch (Exception e) {
            result = false;
        }

        return result;
    }

    /**
     * 契約に関するフォルダ、初期レポート(トライアルで利用)を削除する
     */
    public Boolean remove(String contractId) {
        Boolean result = true;

        try {
            String accessToken = this.getAccessToken();

            this.removeResourceFolder(contractId, accessToken);

        } catch (Exception e) {
            result = false;
        }

        return result;
    }

    /**
     * SVF Cloudにトライアルで利用するフォームをアップロードする
     */
    private void uploadForms(String contractId, String accessToken) {
        List<SvfReportFile__mdt> svfReportFiles = [SELECT FileName__c,Report__c,SortOrder__c FROM SvfReportFile__mdt ORDER BY SortOrder__c];

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type', 'application/octet-stream');
        httpRequest.setHeader('Authorization', 'Bearer ' + accessToken);
        httpRequest.setTimeout(60000);

        Http http = new Http();

        for (SvfReportFile__mdt svfReportFile : svfReportFiles) {
            httpRequest.setEndpoint('callout:Svf/resources/form/' + contractId + '/' + svfReportFile.FileName__c);
            httpRequest.setBodyAsBlob(Blob.valueOf(svfReportFile.Report__c));
            httpRequest.setHeader('Content-Length', String.valueOf(httpRequest.getBodyAsBlob().size()));
        
            HTTPResponse httpResponse = http.send(httpRequest);

            if (httpResponse.getStatusCode() != 201) {
                throw new CalloutException('Can not upload report form to SVF Cloud: ' + httpResponse.toString());
            }
        }
    }

    /**
     * SVF Cloudに契約のリソースフォルダを作成する
     */
    private void createResourceFolder(String contractId, String accessToken) {
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint('callout:Svf/resources/form/' + contractId);
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        httpRequest.setHeader('Authorization', 'Bearer ' + accessToken);

        Http http = new Http();
        HTTPResponse httpResponse = http.send(httpRequest);

        if (httpResponse.getStatusCode() != 201 && httpResponse.getStatusCode() != 400) {
            throw new CalloutException('Can not create resource folder of SVF Cloud: ' + httpResponse.toString());
        }
    }

    /**
     * SVF Cloudの契約のリソースフォルダを削除する
     */
    private void removeResourceFolder(String contractId, String accessToken) {
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint('callout:Svf/resources/form/' + contractId);
        httpRequest.setMethod('DELETE');
        httpRequest.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        httpRequest.setHeader('Authorization', 'Bearer ' + accessToken);

        Http http = new Http();
        HTTPResponse httpResponse = http.send(httpRequest);

        if (httpResponse.getStatusCode() != 204 && httpResponse.getStatusCode() != 400) {
            throw new CalloutException('Can not remove resource folder of SVF Cloud: ' + httpResponse.toString());
        }
    }

    /**
     * SVF Cloudからアクセストークンを取得する
     */
    private String getAccessToken() {
        Svf__mdt svf = [SELECT ClientId__c,Secret__c,TimeZone__c,UserId__c,UserName__c,Locale__c,PrivateKey__c FROM Svf__mdt LIMIT 1];

        JWTHeader jwtHeader = new JwtHeader();
        jwtHeader.alg = 'RS256';
        jwtHeader.type = 'JWT';

        JWTClaimSet jwtClaimSet = new JWTClaimSet();
        jwtClaimSet.iss = svf.ClientId__c;
        jwtClaimSet.sub = svf.UserId__c + '@api.svfcloud.com';
        jwtClaimSet.exp = (Integer)((Datetime.now().getTime() / 1000) + (10 * 60));
        jwtClaimSet.userName = svf.UserName__c;
        jwtClaimSet.timeZone = svf.TimeZone__c;
        jwtClaimSet.locale = svf.Locale__c;

        String auth = EncodingUtil.base64Encode(Blob.valueOf(svf.ClientId__c + ':' + svf.Secret__c));

        Blob privateKey = EncodingUtil.base64Decode(svf.PrivateKey__c);
        String header = this.urlEncode(EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(jwtHeader))));
        String payload = this.urlEncode(EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(jwtClaimSet))));
        String base = header + '.' + payload;
        String sig = this.urlEncode(EncodingUtil.base64Encode(Crypto.sign('RSA-SHA256', Blob.valueOf(base), privateKey)));
        String jwt = base + '.' + sig;
        
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint('callout:Svf/oauth2/token');
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        httpRequest.setHeader('Authorization', 'Basic ' + auth);
        String body = 'grant_type=' + EncodingUtil.urlEncode('urn:ietf:params:oauth:grant-type:jwt-bearer', 'UTF-8');
        body += '&assertion=' + jwt;
        httpRequest.setBody(body);

        Http http = new Http();
        HTTPResponse httpResponse = http.send(httpRequest);

        if (httpResponse.getStatusCode() != 200) {
            throw new CalloutException('Can not get accesss token from SVF Cloud: ' + httpResponse.toString());
        }

        Map<String, Object> mapBody = (Map<String, Object>)JSON.deserializeUntyped(httpResponse.getBody());

        return (String)mapBody.get('token');
    }

    /**
     * 文字列をURLエンコードする(JWT対応)
     */
    private String urlEncode(String str) {
        String result = str.replaceAll('\\+', '-').replaceAll('/', '_');

        while(result.endsWith('=')) {
            result = result.left(result.length() - 1);
        }

        return result;
    }

    class JWTHeader {
        String alg;
        String type;
    }

    class JWTClaimSet {
        String iss;
        String sub;
        Integer exp;
        String userName;
        String timeZone;
        String locale;
    }

}
