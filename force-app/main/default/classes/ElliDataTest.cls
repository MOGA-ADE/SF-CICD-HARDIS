@isTest
private class ElliDataTest {
    @isTest static void testData() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new ElliDataTestHTTPMock());
        
        ElliDataResult returnValues= new ElliDataResult();
        ElliData.Request requestValues= new ElliData.Request();
        
        requestValues.contract= 'test';
        requestValues.user= 'test';
        requestValues.password= 'test';
        // requestValues.companyName = 'Ellisphere';
        requestValues.companyId = '123456789';
        // requestValues.companyPostcode= '';
        requestValues.companyCountryCode= 'ZZ';
        
        List<ElliDataResult> responseWrapper = new List<ElliDataResult>();
        List<ElliData.Request> requestWrapper = new List<ElliData.Request>();
        
        requestWrapper.add(requestValues);
        
        responseWrapper = ElliData.process(requestWrapper);
       
        returnValues=responseWrapper.get(0);
        
        System.assertEquals(false,returnValues.error);
        
        requestValues.companyCountryCode= 'FR';
        requestValues.companyId = '12345678912345';
        
        requestWrapper.add(requestValues);
        
        responseWrapper = ElliData.process(requestWrapper);
       
        returnValues=responseWrapper.get(0);
        
        System.assertEquals(false,returnValues.error);
        
        requestValues.companyCountryCode= 'DE';
        requestValues.companyId = '123456789';
        
        requestWrapper.add(requestValues);
        
        responseWrapper = ElliData.process(requestWrapper);
       
        returnValues=responseWrapper.get(0);
        
        System.assertEquals(false,returnValues.error);

    }
}