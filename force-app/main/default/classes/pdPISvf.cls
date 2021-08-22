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
        String base = EncodingUtil.urlEncode(EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(jwtHeader))), 'UTF-8') + '.' + EncodingUtil.urlEncode(EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(jwtClaimSet))), 'UTF-8');
        base = base.replace('+', '-').replace('/', '_').replace('=', '');
        String sig = EncodingUtil.urlEncode(EncodingUtil.base64Encode(Crypto.sign('RSA-SHA256', Blob.valueOf(base), privateKey)), 'UTF-8');
        base = base.replace('+', '-').replace('/', '_').replace('=', '');
        String body = base + '.' + sig;

        system.debug(body);
        
        return 'ok';
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
