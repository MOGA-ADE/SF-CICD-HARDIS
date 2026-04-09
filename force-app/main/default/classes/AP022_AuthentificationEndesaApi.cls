public with sharing class AP022_AuthentificationEndesaApi {

    // Méthode permettant de recuperer le token stocké dans la custom metadata Sandboxe ou prod selon environnement
    public static String getToken(){

        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;

        // Recup des identifiants
        Endesa_API__mdt config = [
            SELECT Access_token__c
            FROM Endesa_API__mdt 
            WHERE Sandboxe__c = :isSandbox 
            LIMIT 1
        ];

        if(config != null)  {
            return config.Access_token__c;
        }
        
        return null;
    }

    private static String refreshToken(String endpoint, String refresh_token, String client_id, String client_secret, Integer timeout) {
        System.debug('refreshToken try refresh with refresh_token : ' + refresh_token);
        HttpRequest req = new HttpRequest();
        Http http = new Http();

        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(timeout);

        Map<String, String> bodyMap = new Map<String, String>();
        bodyMap.put('refresh_token', refresh_token);
        bodyMap.put('client_id', '');
        bodyMap.put('client_secret', '');
        System.debug('refreshToken bodyMap : ' + bodyMap);

        req.setBody(JSON.serialize(bodyMap));

        try {
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                API_Endesa_Refresh_Elec_Token resToken = (API_Endesa_Refresh_Elec_Token) JSON.deserialize(res.getBody(), API_Endesa_Refresh_Elec_Token.class);
                if (resToken != null) {
                    UpdateCustomMetadata.updateMetadata(resToken.refresh_token, resToken.access_token);
                    System.debug('refreshToken UpdateCustomMetadata  refresh_token : ' + resToken.refresh_token + ' access_token : ' + resToken.access_token);
                    return resToken.access_token;
                } else {
                    System.debug('Réponse inattendue : ' + res.getBody());
                }
            } else {
                System.debug('Erreur : ' + res.getStatusCode() + ' / ' + res.getBody());
                return null;
            }
        } catch (Exception e) {
            System.debug('Exception lors de l appel : ' + e.getMessage());
        }
        return null;
    }

    // Méthode permettant de s'authentifier
    private static String getAccessToken(String endpoint, String username, String password, Integer timeout) {
        System.debug('getAccessToken try log in with username : ' + username + ' password : ' + password);
        HttpRequest req = new HttpRequest();
        Http http = new Http();

        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(timeout);

        Map<String, String> bodyMap = new Map<String, String>();
        bodyMap.put('username', username);
        bodyMap.put('password', password);

        req.setBody(JSON.serialize(bodyMap));

        try {
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                API_Endesa_Elec_Token resToken = (API_Endesa_Elec_Token) JSON.deserialize(res.getBody(), API_Endesa_Elec_Token.class);
                if (resToken != null && resToken.login != null) {
                    UpdateCustomMetadata.updateMetadata(resToken.login.refresh_token, resToken.login.access_token);
                    System.debug('custom metadata is succes updated new value, refresh_token : ' + resToken.login.refresh_token + ' access_token : ' + resToken.login.access_token);
                    return resToken.login.access_token;
                } else {
                    System.debug('Erreur : ' + res.getStatusCode() + ' / ' + res.getBody());
                    return null;   
                }
            } else {
                System.debug('Erreur : ' + res.getStatusCode() + ' / ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception lors de l appel : ' + e.getMessage());
        }
        return null;
    }  

    /*
        Les fonctions refresh et log commencent toutes les deux par vérifier si on est dans une sandbox.
        Il faut donc sortir cette logique de ces deux fct et les mettre dans la fonction authentifier.
        Authentifier doit donc commencer par vérifier si on est dans une sandbox ou pas puis set les différentes variables
        et lancer les fonctions et font les appels réseaux
    */
    public static String authentifier() {

        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;

        String endpoint = getEndpoint();

        // Recup des identifiants
        Endesa_API__mdt config = [
            SELECT Username__c, Password__c, Timeout__c, Refresh_token__c
            FROM Endesa_API__mdt 
            WHERE Sandboxe__c = :isSandbox 
            LIMIT 1
        ];
        String token;
        if (config != null) {
            token = refreshToken(
                'callout:'+endpoint+'/api/refresh-token/',
                config.Refresh_token__c,
                '',
                '',
                (Integer) config.Timeout__c
            );
        }

        if(token == null){
            System.debug('Refresh KO - try to log in');
            token = getAccessToken(
                'callout:'+endpoint+'/api/login/',
                config.Username__c,
                config.Password__c,
                (Integer) config.Timeout__c
            );
            System.debug('Token Log in : ' + token);
        }
        return token;
    }

    //Prendre en entrée un booleen
    public static String getEndpoint() {

        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        String endpoint = isSandbox ? 'Endesa_Elec_Preprod' : 'Endesa_Elec';
        return endpoint;
    }

    public static String getCallBack() {

        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;

        // Recup callback url
        Endesa_API__mdt config = [
            SELECT Call_back__c
            FROM Endesa_API__mdt 
            WHERE Sandboxe__c = :isSandbox 
            LIMIT 1
        ];

        if(config != null)  {
            return config.Call_back__c;
        }

        return null;
    }

    // Classes internes pour désérialisation
    private class API_Endesa_Elec_Token {
        public String last_name;
        public String first_name;
        public String email;
        public Login login;
    }

    private class API_Endesa_Refresh_Elec_Token {
        public String refresh_token;
        public String access_token;
    }

    private class API_Endesa_Elec_Unauthorized {
        public String message;
        public String code_error;
    }

    private class Login {
        public String access_token;
        public String client_id;
        public String client_secret;
        public String refresh_token;
    }
}