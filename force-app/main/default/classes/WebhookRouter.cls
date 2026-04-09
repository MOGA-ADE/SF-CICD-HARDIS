@RestResource(urlMapping='/callback/*')
global without sharing class WebhookRouter {

    @HttpPost
    global static void handler() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            String requestURI = req.requestURI;
            List<String> segments = requestURI.split('/');
            String rawWebhookName = segments.isEmpty() ? null : segments[segments.size() - 1];
            String webhookName = rawWebhookName.trim().toLowerCase();

            switch on webhookName {
                when 'turpewebhook' {
                    try {
                        AP034_TURPEWebhookHandler handler = new AP034_TURPEWebhookHandler();
                        handler.handle(req);
                        res.statusCode = 200;
                        res.responseBody = Blob.valueOf('{"received": true}');
                        System.debug('turpewebhook : {"received": true}');
                        return;
                    } catch (Exception e) {
                        res.statusCode = 202;
                        res.responseBody = Blob.valueOf('{"received": true, "warning": "Invalid format"}');
                        System.debug('turpewebhook : {"received": true, "warning": "Invalid format"}');
                        return;
                    }
                }

                when 'gazelwebhook' {
                    GazelWebhook gazelWebhook = new GazelWebhook();
                    gazelWebhook.handle(req, res);
                }

                when else {
                    res.statusCode = 404;
                    res.responseBody = Blob.valueOf('{"error": "Handler not found"}');
                    System.debug(webhookName + ' : {"error": "Handler not found"}');
                    return;
                }
            }
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('{"error": "Internal server error"}');
            System.debug('{"error": "Internal server error"}');
        }
    }
}