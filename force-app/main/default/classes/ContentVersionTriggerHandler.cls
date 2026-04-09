public with sharing class ContentVersionTriggerHandler {

    public static void zipFileForbidden(List<ContentVersion> newContentVersion) {
        System.debug('zipFileForbidden');


        for(ContentVersion cv : newContentVersion) {
            if (cv.FirstPublishLocationId != null && cv.FirstPublishLocationId.getSobjectType() == Account.SObjectType && cv.PathOnClient != null && cv.PathOnClient.toLowerCase().endsWith('.zip')) {
                cv.addError('Le téléchargement de fichiers .zip est interdit sur les Comptes.');
            }
        }

    }

}