public class GazelWebhook {

    public void handle(RestRequest req, RestResponse res) {
        String requestBody = req.requestBody.toString();
        
        // Variables pour capturer le résultat du traitement pour le log
        Integer finalStatusCode = 200;
        String finalResponseBody = '';

        try {
            // 1. Vérification présence Body
            if (String.isBlank(requestBody)) {
                finalStatusCode = 400;
                finalResponseBody = '{"error": "Empty Body"}';
                sendResponse(res, finalStatusCode, finalResponseBody);
                return;
            }

            // 2. PRE-PROCESSING
            String cleanJson = requestBody.replace('"date":', '"dateStatut":');

            // 3. DESERIALIZATION TYPÉE
            GazelWebhookDTO.Payload payload;
            try {
                payload = (GazelWebhookDTO.Payload) JSON.deserialize(cleanJson, GazelWebhookDTO.Payload.class);
            } catch (Exception e) {
                finalStatusCode = 400;
                finalResponseBody = '{"error": "JSON Malformé: ' + e.getMessage() + '"}';
                sendResponse(res, finalStatusCode, finalResponseBody);
                return;
            }

            // 4. VALIDATION STRUCTURE
            if (payload.offre == null || String.isBlank(payload.offre.id)) {
                finalStatusCode = 400;
                finalResponseBody = '{"error": "Structure JSON invalide : ID Offre manquant."}';
                sendResponse(res, finalStatusCode, finalResponseBody);
                return;
            }

            // 5. TRAITEMENT MÉTIER
            // Note : Si cette méthode échoue, on tombe dans le catch global
            GazelService.processWebhookUpdate(payload);

            // 6. PRÉPARATION RÉPONSE SUCCÈS
            finalStatusCode = 200;
            finalResponseBody = '{"status": "OK", "message": "Processed successfully"}';
            sendResponse(res, finalStatusCode, finalResponseBody);

        } catch (Exception e) {
            // Gestion globale des erreurs techniques
            finalStatusCode = 500;
            finalResponseBody = '{"error": "Internal Server Error", "details": "' + e.getMessage() + '"}';
            sendResponse(res, finalStatusCode, finalResponseBody);
            
        } finally {
            // PUBLICATION DU LOG
            // On passe null en RecordId car l'ID de la Quote est à l'intérieur du JSON
            ApiLogger.publish('GazelWebhook.handle','GAZEL',req.requestURI,requestBody,finalResponseBody,finalStatusCode,req.httpMethod,null);
        }
    }

    private void sendResponse(RestResponse res, Integer statusCode, String body) {
        res.statusCode = statusCode;
        res.responseBody = Blob.valueOf(body);
    }
}