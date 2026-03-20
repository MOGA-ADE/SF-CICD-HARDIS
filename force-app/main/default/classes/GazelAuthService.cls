public class GazelAuthService {
    private static final String CACHE_PARTITION = 'local.GazelCache';
    private static final String CACHE_KEY = 'AccessToken';

    public static String getAccessToken() {
        Cache.OrgPartition partition = Cache.Org.getPartition(CACHE_PARTITION);
        String token = (String) partition.get(CACHE_KEY);
        
        // Si pas de token, on en demande un nouveau
        if (token == null) {
            token = requestNewToken(partition);
        }
        return token;
    }

    private static String requestNewToken(Cache.OrgPartition partition) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Gazel_Auth_NC/gazel/oauth/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        
        Gazel_Setting__mdt creds = Gazel_Setting__mdt.getInstance('Prod'); 
        String body = 'grant_type=password&scope=api:partenaire' + 
                      '&username=' + EncodingUtil.urlEncode(creds.Username__c, 'UTF-8') +
                      '&password=' + EncodingUtil.urlEncode(creds.Password__c, 'UTF-8');
        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String token = (String) data.get('access_token');
            Integer exp = (Integer) data.get('expires_in');
            if (token != null) partition.put(CACHE_KEY, token, (exp != null ? exp - 60 : 3540));
            return token;
        }
        throw new CalloutException('Auth Failed: ' + res.getBody());
    }
}