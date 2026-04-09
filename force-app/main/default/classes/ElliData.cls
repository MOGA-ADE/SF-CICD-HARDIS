public class ElliData {
 
    @InvocableMethod(label='Ellisphere Data' description='Get company data by country and identifier')
    public static List <ElliDataResult> process(List<Request> requestList) {

        List<ElliDataResult> responseWrapper = new List<ElliDataResult>();

        for (Request curRequest : requestList) {
            responseWrapper=callData(curRequest.product,curRequest.contract,curRequest.user,curRequest.password, curRequest.companyId, curRequest.companyCountryCode);
        }

        return responseWrapper;
    }

    public class Request {
        @InvocableVariable(required=true)
        public String product;
        @InvocableVariable(required=true)
        public String contract;
        @InvocableVariable(required=true)
        public String user;
        @InvocableVariable(required=true)
        public String password;
        @InvocableVariable(required=false)
        public String companyId = '';
        @InvocableVariable(required=false)
        public String companyCountryCode = 'FRA';
    }

    private static List <ElliDataResult> callData(String product, String contract, String user, String password, String companyId, String companyCountryCode) {
        ElliDataResult callResponse = new ElliDataResult();
        List<ElliDataManager> dataManagers = new List<ElliDataManager>();
        List<ElliDataScore> dataScores = new List<ElliDataScore>();
        List<ElliDataResult> callResponseList = new List<ElliDataResult>();
        ElliDataManager dataManager;
        ElliDataScore dataScore;

        String resultCode;
        String xml;
        Boolean test = true;
        String requestBody;

        if (companyCountryCode.length()==2) {
            companyCountryCode = convertToIso3Country(companyCountryCode);
        }

        if (companyCountryCode == '') {
            companyCountryCode = 'FRA';
        }
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://wsconnect-salesforce.data-access-gateway.com/1/rest/svcOnlineOrder');
        req.setHeader('Content-Type','application/xml');
         
        if (companyId != '') {
            if (companyCountryCode == 'FRA' & companyId.length()==14) {
                requestBody = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><svcOnlineOrderRequest lang="FR" version="2.2"><admin><client><contractId>'+contract+'</contractId><userPrefix>GEOCOM</userPrefix><userId>'+user+'</userId><password>'+password+'</password><privateReference type="order"></privateReference><privateReference type="transaction"></privateReference></client><context><appId version="1">WSCONNECT</appId><date>2023-05-04T09:45:12.417Z</date></context></admin><request><id type="register-estb" idName="SIRET">'+companyId+'</id><product range="'+product+'"/><deliveryOptions><outputMethod>raw</outputMethod></deliveryOptions></request></svcOnlineOrderRequest>';           
            }else{
                requestBody = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><svcOnlineOrderRequest lang="FR" version="2.2"><admin><client><contractId>'+contract+'</contractId><userPrefix>GEOCOM</userPrefix><userId>'+user+'</userId><password>'+password+'</password><privateReference type="order"></privateReference><privateReference type="transaction"></privateReference></client><context><appId version="1">WSCONNECT</appId><date>2023-05-04T09:45:12.417Z</date></context></admin><request><country code="'+companyCountryCode+'" /><id type="src">'+companyId+'</id><product range="'+product+'"/><deliveryOptions><outputMethod>raw</outputMethod></deliveryOptions></request></svcOnlineOrderRequest>';       
            }                    
        }

        req.setBody(requestBody);
        req.setMethod('POST');

        Http http = new Http();
        
        try {
            HTTPResponse res = http.send(req);
            xml = res.getBody();
            DOM.Document document = res.getBodyDocument();
            DOM.XMLNode rootElement = document.getRootElement();

            resultCode = rootElement.getChildElement('result', null).getAttribute('code', null);

            if (resultCode  == 'OK') {

                for (DOM.XmlNode node : rootElement.getChildElement('response', null).getChildElement('intlReport', null).getChildren()){

                    if(node.getName() == 'establishment' && test){
                        for(Dom.XmlNode estbNode: node.getChildElements()) {

                            if(estbNode.getName() == 'name' && estbNode.getAttribute('type','') == 'businessName') {
                                callResponse.companyname = estbNode.getText();
                            }

                            if(estbNode.getName()=='address') {
                                for(Dom.XmlNode addressNode: estbNode.getChildElements()) {
                  
                                    if(addressNode.getName()=='addressLine') {
                                        callResponse.address = addressNode.getText();
                                    }
                                    if(addressNode.getName()=='cityCode') {
                                        callResponse.postcode = addressNode.getText();
                                    }
                                    if(addressNode.getName()=='cityName') {
                                        callResponse.city = addressNode.getText();
                                    }
                                    if(addressNode.getName()=='country') {
                                        callResponse.country = addressNode.getText();
                                    }
                                }
                            }
                        }
                    }

                    if(node.getName() == 'companyAppointments'){
                        for(Dom.XmlNode appointmentNode: node.getChildElements()) {

                            if(appointmentNode.getName()=='manager') {
                                for(Dom.XmlNode managerNode: appointmentNode.getChildElements()) {
                                    
                                    if(managerNode.getName()=='party') {
                                        for(Dom.XmlNode partyNode: managerNode.getChildElements()) {
                                            dataManager = new ElliDataManager();

                                            if(partyNode.getName()=='person') {
                                                for(Dom.XmlNode personNode: partyNode.getChildElements()) {
                                                    if(personNode.getName()=='salutation') {
                                                        dataManager.salutation = personNode.getText();
                                                    }
                                                    if(personNode.getName()=='firstName') {
                                                        dataManager.firstname = personNode.getText();
                                                    }
                                                    if(personNode.getName()=='lastName') {
                                                        dataManager.lastname = personNode.getText();
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    if(managerNode.getName()=='position') {
                                        for(Dom.XmlNode positionNode: managerNode.getChildElements()) {
                                            
                                            if(positionNode.getName() == 'role' && positionNode.getAttribute('origin','') == 'csf') {
                                                dataManager.title = positionNode.getText();
                                            }
                                        }
                                    }
                                }
                                
                                if(dataManager.lastname !=null) {
                                    dataManagers.add(dataManager);
                                }
                            }
                        }
                    }

                    if(node.getName() == 'assessmentData'){
                        for(Dom.XmlNode assessmentData: node.getChildElements()) {
                            

                            if(assessmentData.getName() == 'score') {
                                dataScore = new ElliDataScore();

                                for(Dom.XmlNode scoreNode: assessmentData.getChildElements()) {

                                    if(scoreNode.getName() == 'date') {
                                        dataScore.dateScore = Date.valueOf(scoreNode.getText());
                                    } else if (scoreNode.getName() == 'value') {
                                        String keyNS = scoreNode.getAttributeKeyNsAt(0);

                                        if(scoreNode.getAttributeValue('type', keyNS) == 'score') {
                                            dataScore.score = scoreNode.getText();
                                        }
    
                                        if(scoreNode.getAttributeValue('type', keyNS) == 'riskclass') {
                                            dataScore.riskClass = scoreNode.getText();
                                        }
                                    }
                                }

                                dataScores.add(dataScore);
                            }

                            if(assessmentData.getName() == 'scoreHistory') {
                                dataScore = new ElliDataScore();

                                for(Dom.XmlNode scoreNode: assessmentData.getChildElements()) {

                                    if(scoreNode.getName() == 'date') {
                                        dataScore.dateScore = Date.valueOf(scoreNode.getText());
                                    } else if (scoreNode.getName() == 'value') {
                                        String keyNS = scoreNode.getAttributeKeyNsAt(0);

                                        if(scoreNode.getAttributeValue('type', keyNS) == 'score') {
                                            dataScore.score = scoreNode.getText();
                                        }
    
                                        if(scoreNode.getAttributeValue('type', keyNS) == 'riskclass') {
                                            dataScore.riskClass = scoreNode.getText();
                                        }
                                    }
                                }

                                dataScores.add(dataScore);
                            }
                        }
                    }
                }
                callResponse.error = false;
                callResponse.scores = dataScores;
                callResponse.managers = dataManagers;
            } else {
                callResponse.error = true;
                callResponse.comment = 'Erreur :'+rootElement.getChildElement('result', null).getChildElement('additionalInfo', null).getText();
            }
         } catch(Exception e) {
            callResponse.error = true;
            callResponse.comment = e.getMessage();
        } finally {
            callResponseList.add(callResponse);
            return callResponseList;
        }

        callResponseList.add(callResponse);
        return callResponseList;
    }

    private static String convertToIso3Country(String countryIso2){
        String tmpReturnValue;
        switch on countryIso2 {
            when 'AF' { tmpReturnValue='AFG'; }
            when 'AX' { tmpReturnValue='ALA'; }
            when 'AL' { tmpReturnValue='ALB'; }
            when 'DZ' { tmpReturnValue='DZA'; }
            when 'AS' { tmpReturnValue='ASM'; }
            when 'AD' { tmpReturnValue='AND'; }
            when 'AO' { tmpReturnValue='AGO'; }
            when 'AI' { tmpReturnValue='AIA'; }
            when 'AQ' { tmpReturnValue='ATA'; }
            when 'AG' { tmpReturnValue='ATG'; }
            when 'AR' { tmpReturnValue='ARG'; }
            when 'AM' { tmpReturnValue='ARM'; }
            when 'AW' { tmpReturnValue='ABW'; }
            when 'AU' { tmpReturnValue='AUS'; }
            when 'AT' { tmpReturnValue='AUT'; }
            when 'AZ' { tmpReturnValue='AZE'; }
            when 'BS' { tmpReturnValue='BHS'; }
            when 'BH' { tmpReturnValue='BHR'; }
            when 'BD' { tmpReturnValue='BGD'; }
            when 'BB' { tmpReturnValue='BRB'; }
            when 'BY' { tmpReturnValue='BLR'; }
            when 'BE' { tmpReturnValue='BEL'; }
            when 'BZ' { tmpReturnValue='BLZ'; }
            when 'BJ' { tmpReturnValue='BEN'; }
            when 'BM' { tmpReturnValue='BMU'; }
            when 'BT' { tmpReturnValue='BTN'; }
            when 'BO' { tmpReturnValue='BOL'; }
            when 'BQ' { tmpReturnValue='BES'; }
            when 'BA' { tmpReturnValue='BIH'; }
            when 'BW' { tmpReturnValue='BWA'; }
            when 'BV' { tmpReturnValue='BVT'; }
            when 'BR' { tmpReturnValue='BRA'; }
            when 'IO' { tmpReturnValue='IOT'; }
            when 'BN' { tmpReturnValue='BRN'; }
            when 'BG' { tmpReturnValue='BGR'; }
            when 'BF' { tmpReturnValue='BFA'; }
            when 'BI' { tmpReturnValue='BDI'; }
            when 'CV' { tmpReturnValue='CPV'; }
            when 'KH' { tmpReturnValue='KHM'; }
            when 'CM' { tmpReturnValue='CMR'; }
            when 'CA' { tmpReturnValue='CAN'; }
            when 'KY' { tmpReturnValue='CYM'; }
            when 'CF' { tmpReturnValue='CAF'; }
            when 'TD' { tmpReturnValue='TCD'; }
            when 'CL' { tmpReturnValue='CHL'; }
            when 'CN' { tmpReturnValue='CHN'; }
            when 'CX' { tmpReturnValue='CXR'; }
            when 'CC' { tmpReturnValue='CCK'; }
            when 'CO' { tmpReturnValue='COL'; }
            when 'KM' { tmpReturnValue='COM'; }
            when 'CG' { tmpReturnValue='COG'; }
            when 'CD' { tmpReturnValue='COD'; }
            when 'CK' { tmpReturnValue='COK'; }
            when 'CR' { tmpReturnValue='CRI'; }
            when 'CI' { tmpReturnValue='CIV'; }
            when 'HR' { tmpReturnValue='HRV'; }
            when 'CU' { tmpReturnValue='CUB'; }
            when 'CW' { tmpReturnValue='CUW'; }
            when 'CY' { tmpReturnValue='CYP'; }
            when 'CZ' { tmpReturnValue='CZE'; }
            when 'DK' { tmpReturnValue='DNK'; }
            when 'DJ' { tmpReturnValue='DJI'; }
            when 'DM' { tmpReturnValue='DMA'; }
            when 'DO' { tmpReturnValue='DOM'; }
            when 'EC' { tmpReturnValue='ECU'; }
            when 'EG' { tmpReturnValue='EGY'; }
            when 'SV' { tmpReturnValue='SLV'; }
            when 'GQ' { tmpReturnValue='GNQ'; }
            when 'ER' { tmpReturnValue='ERI'; }
            when 'EE' { tmpReturnValue='EST'; }
            when 'SZ' { tmpReturnValue='SWZ'; }
            when 'ET' { tmpReturnValue='ETH'; }
            when 'FK' { tmpReturnValue='FLK'; }
            when 'FO' { tmpReturnValue='FRO'; }
            when 'FJ' { tmpReturnValue='FJI'; }
            when 'FI' { tmpReturnValue='FIN'; }
            when 'FR' { tmpReturnValue='FRA'; }
            when 'GF' { tmpReturnValue='GUF'; }
            when 'PF' { tmpReturnValue='PYF'; }
            when 'TF' { tmpReturnValue='ATF'; }
            when 'GA' { tmpReturnValue='GAB'; }
            when 'GM' { tmpReturnValue='GMB'; }
            when 'GE' { tmpReturnValue='GEO'; }
            when 'DE' { tmpReturnValue='DEU'; }
            when 'GH' { tmpReturnValue='GHA'; }
            when 'GI' { tmpReturnValue='GIB'; }
            when 'GR' { tmpReturnValue='GRC'; }
            when 'GL' { tmpReturnValue='GRL'; }
            when 'GD' { tmpReturnValue='GRD'; }
            when 'GP' { tmpReturnValue='GLP'; }
            when 'GU' { tmpReturnValue='GUM'; }
            when 'GT' { tmpReturnValue='GTM'; }
            when 'GG' { tmpReturnValue='GGY'; }
            when 'GN' { tmpReturnValue='GIN'; }
            when 'GW' { tmpReturnValue='GNB'; }
            when 'GY' { tmpReturnValue='GUY'; }
            when 'HT' { tmpReturnValue='HTI'; }
            when 'HM' { tmpReturnValue='HMD'; }
            when 'VA' { tmpReturnValue='VAT'; }
            when 'HN' { tmpReturnValue='HND'; }
            when 'HK' { tmpReturnValue='HKG'; }
            when 'HU' { tmpReturnValue='HUN'; }
            when 'IS' { tmpReturnValue='ISL'; }
            when 'IN' { tmpReturnValue='IND'; }
            when 'ID' { tmpReturnValue='IDN'; }
            when 'IR' { tmpReturnValue='IRN'; }
            when 'IQ' { tmpReturnValue='IRQ'; }
            when 'IE' { tmpReturnValue='IRL'; }
            when 'IM' { tmpReturnValue='IMN'; }
            when 'IL' { tmpReturnValue='ISR'; }
            when 'IT' { tmpReturnValue='ITA'; }
            when 'JM' { tmpReturnValue='JAM'; }
            when 'JP' { tmpReturnValue='JPN'; }
            when 'JE' { tmpReturnValue='JEY'; }
            when 'JO' { tmpReturnValue='JOR'; }
            when 'KZ' { tmpReturnValue='KAZ'; }
            when 'KE' { tmpReturnValue='KEN'; }
            when 'KI' { tmpReturnValue='KIR'; }
            when 'KP' { tmpReturnValue='PRK'; }
            when 'KR' { tmpReturnValue='KOR'; }
            when 'KW' { tmpReturnValue='KWT'; }
            when 'KG' { tmpReturnValue='KGZ'; }
            when 'LA' { tmpReturnValue='LAO'; }
            when 'LV' { tmpReturnValue='LVA'; }
            when 'LB' { tmpReturnValue='LBN'; }
            when 'LS' { tmpReturnValue='LSO'; }
            when 'LR' { tmpReturnValue='LBR'; }
            when 'LY' { tmpReturnValue='LBY'; }
            when 'LI' { tmpReturnValue='LIE'; }
            when 'LT' { tmpReturnValue='LTU'; }
            when 'LU' { tmpReturnValue='LUX'; }
            when 'MO' { tmpReturnValue='MAC'; }
            when 'MG' { tmpReturnValue='MDG'; }
            when 'MW' { tmpReturnValue='MWI'; }
            when 'MY' { tmpReturnValue='MYS'; }
            when 'MV' { tmpReturnValue='MDV'; }
            when 'ML' { tmpReturnValue='MLI'; }
            when 'MT' { tmpReturnValue='MLT'; }
            when 'MH' { tmpReturnValue='MHL'; }
            when 'MQ' { tmpReturnValue='MTQ'; }
            when 'MR' { tmpReturnValue='MRT'; }
            when 'MU' { tmpReturnValue='MUS'; }
            when 'YT' { tmpReturnValue='MYT'; }
            when 'MX' { tmpReturnValue='MEX'; }
            when 'FM' { tmpReturnValue='FSM'; }
            when 'MD' { tmpReturnValue='MDA'; }
            when 'MC' { tmpReturnValue='MCO'; }
            when 'MN' { tmpReturnValue='MNG'; }
            when 'ME' { tmpReturnValue='MNE'; }
            when 'MS' { tmpReturnValue='MSR'; }
            when 'MA' { tmpReturnValue='MAR'; }
            when 'MZ' { tmpReturnValue='MOZ'; }
            when 'MM' { tmpReturnValue='MMR'; }
            when 'NA' { tmpReturnValue='NAM'; }
            when 'NR' { tmpReturnValue='NRU'; }
            when 'NP' { tmpReturnValue='NPL'; }
            when 'NL' { tmpReturnValue='NLD'; }
            when 'NC' { tmpReturnValue='NCL'; }
            when 'NZ' { tmpReturnValue='NZL'; }
            when 'NI' { tmpReturnValue='NIC'; }
            when 'NE' { tmpReturnValue='NER'; }
            when 'NG' { tmpReturnValue='NGA'; }
            when 'NU' { tmpReturnValue='NIU'; }
            when 'NF' { tmpReturnValue='NFK'; }
            when 'MK' { tmpReturnValue='MKD'; }
            when 'MP' { tmpReturnValue='MNP'; }
            when 'NO' { tmpReturnValue='NOR'; }
            when 'OM' { tmpReturnValue='OMN'; }
            when 'PK' { tmpReturnValue='PAK'; }
            when 'PW' { tmpReturnValue='PLW'; }
            when 'PS' { tmpReturnValue='PSE'; }
            when 'PA' { tmpReturnValue='PAN'; }
            when 'PG' { tmpReturnValue='PNG'; }
            when 'PY' { tmpReturnValue='PRY'; }
            when 'PE' { tmpReturnValue='PER'; }
            when 'PH' { tmpReturnValue='PHL'; }
            when 'PN' { tmpReturnValue='PCN'; }
            when 'PL' { tmpReturnValue='POL'; }
            when 'PT' { tmpReturnValue='PRT'; }
            when 'PR' { tmpReturnValue='PRI'; }
            when 'QA' { tmpReturnValue='QAT'; }
            when 'RE' { tmpReturnValue='REU'; }
            when 'RO' { tmpReturnValue='ROU'; }
            when 'RU' { tmpReturnValue='RUS'; }
            when 'RW' { tmpReturnValue='RWA'; }
            when 'BL' { tmpReturnValue='BLM'; }
            when 'SH' { tmpReturnValue='SHN'; }
            when 'KN' { tmpReturnValue='KNA'; }
            when 'LC' { tmpReturnValue='LCA'; }
            when 'MF' { tmpReturnValue='MAF'; }
            when 'PM' { tmpReturnValue='SPM'; }
            when 'VC' { tmpReturnValue='VCT'; }
            when 'WS' { tmpReturnValue='WSM'; }
            when 'SM' { tmpReturnValue='SMR'; }
            when 'ST' { tmpReturnValue='STP'; }
            when 'SA' { tmpReturnValue='SAU'; }
            when 'SN' { tmpReturnValue='SEN'; }
            when 'RS' { tmpReturnValue='SRB'; }
            when 'SC' { tmpReturnValue='SYC'; }
            when 'SL' { tmpReturnValue='SLE'; }
            when 'SG' { tmpReturnValue='SGP'; }
            when 'SX' { tmpReturnValue='SXM'; }
            when 'SK' { tmpReturnValue='SVK'; }
            when 'SI' { tmpReturnValue='SVN'; }
            when 'SB' { tmpReturnValue='SLB'; }
            when 'SO' { tmpReturnValue='SOM'; }
            when 'ZA' { tmpReturnValue='ZAF'; }
            when 'GS' { tmpReturnValue='SGS'; }
            when 'SS' { tmpReturnValue='SSD'; }
            when 'ES' { tmpReturnValue='ESP'; }
            when 'LK' { tmpReturnValue='LKA'; }
            when 'SD' { tmpReturnValue='SDN'; }
            when 'SR' { tmpReturnValue='SUR'; }
            when 'SJ' { tmpReturnValue='SJM'; }
            when 'SE' { tmpReturnValue='SWE'; }
            when 'CH' { tmpReturnValue='CHE'; }
            when 'SY' { tmpReturnValue='SYR'; }
            when 'TW' { tmpReturnValue='TWN'; }
            when 'TJ' { tmpReturnValue='TJK'; }
            when 'TZ' { tmpReturnValue='TZA'; }
            when 'TH' { tmpReturnValue='THA'; }
            when 'TL' { tmpReturnValue='TLS'; }
            when 'TG' { tmpReturnValue='TGO'; }
            when 'TK' { tmpReturnValue='TKL'; }
            when 'TO' { tmpReturnValue='TON'; }
            when 'TT' { tmpReturnValue='TTO'; }
            when 'TN' { tmpReturnValue='TUN'; }
            when 'TR' { tmpReturnValue='TUR'; }
            when 'TM' { tmpReturnValue='TKM'; }
            when 'TC' { tmpReturnValue='TCA'; }
            when 'TV' { tmpReturnValue='TUV'; }
            when 'UG' { tmpReturnValue='UGA'; }
            when 'UA' { tmpReturnValue='UKR'; }
            when 'AE' { tmpReturnValue='ARE'; }
            when 'GB' { tmpReturnValue='GBR'; }
            when 'US' { tmpReturnValue='USA'; }
            when 'UM' { tmpReturnValue='UMI'; }
            when 'UY' { tmpReturnValue='URY'; }
            when 'UZ' { tmpReturnValue='UZB'; }
            when 'VU' { tmpReturnValue='VUT'; }
            when 'VE' { tmpReturnValue='VEN'; }
            when 'VN' { tmpReturnValue='VNM'; }
            when 'VG' { tmpReturnValue='VGB'; }
            when 'VI' { tmpReturnValue='VIR'; }
            when 'WF' { tmpReturnValue='WLF'; }
            when 'EH' { tmpReturnValue='ESH'; }
            when 'YE' { tmpReturnValue='YEM'; }
            when 'ZM' { tmpReturnValue='ZMB'; }
            when 'ZW' { tmpReturnValue='ZWE'; }
            when else { tmpReturnValue= ''; }
        }
        return tmpReturnValue;
    }
}