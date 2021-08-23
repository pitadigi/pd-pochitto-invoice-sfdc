public with sharing class pdPISvf {
    public virtual class BaseException extends Exception {}
    public class OtherException extends BaseException {}

    /**
     * SVF Cloudからアクセストークンを取得する
     */
    public String getAccessToken() {
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
