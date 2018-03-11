public class StandardSetDemoController {
     
    public ApexPages.StandardSetController con {get;set;}
    public List<SObject> selectedObjList;
    public List<Wrapper> wrapperList;
    public Map<Integer, List<SObject>> selectedMap;
    public Boolean checkAllFlg {get;set;}
    private Boolean isKeepSelected = false;
    public List<SelectOption> listViewList {get;set;}
    public Id selectedListViewId {get;set;}
    public id currentListViewId {get;set;}
    public Integer pSize {get;set;}
    public Integer pPage {get;set;}
    public String sortOrder {get;set;}
    public String sortOrderKeep {get;set;}
    public Integer selectedCount {
        get{
            if(con == null) {
                return 0;
            } else {
                return con.getSelected().size();
            }
        }
        set;
    }
    public Integer totalPageNo {get;set;}
    public Integer currentPageNo {
        get {
            return con.getPageNumber();
        }
        set;
    }

    public StandardSetDemoController() {
        init();
    }
    
    private void init() {

        if(con == null) {
            Map<String, String> labelNameMap = new Map<String, String>();
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get('Account');

            Map<String, Schema.SObjectField> fieldsMap = targetType.getDescribe().fields.getMap(); // Schema.SOjectType.Account.fields.getMap();
            for(String fName:fieldsMap.keyset()) {
                labelNameMap.put(fieldsMap.get(fName).getDescribe().getLabel(), fName);
            }

            String queryFields = String.join(new List<String>(fieldsMap.keyset()), ',');
            String sortField = '';

            if(String.isBlank(sortOrderKeep)) {
                sortField = 'Createddate';
                sortOrder = ' ASC';
            } else {
                if(sortOrderKeep.indexOf('△') > 0) {
                    sortOrder = ' ASC';
                } else {
                    sortOrder = ' DESC';
                }
                sortField = labelNameMap.get(sortOrderKeep.subString(0, sortOrderKeep.length() - 1));
            }

            String tmpQuertyString = 'SELECT '
                                  + queryFields
                                  + ' FROM '
                                  + targetType.getDescribe().getName()
                                  + ' LIMIT 1';

            ApexPages.StandardSetController listviewCon 
                = new ApexPages.StandardSetController(Database.getQueryLocator(tmpQuertyString));

            listViewList = listviewCon.getListViewOptions();
            listviewCon.setFilterId(listViewList[0].getValue());
            if(String.isBlank(selectedListViewId)) {
                selectedListViewId = listviewCon.getFilterId();
            } else {
                listviewCon.setFilterId(selectedListViewId);
            }
            currentListViewId = listviewCon.getFilterId();

            listviewCon.setPageSize(2000);
            List<SObject> objList = new List<SObject>();
            objList.addAll((List<SObject>)listviewCon.getrecords());
            while(listviewCon.getHasNext()) {
                listviewCon.next();
                objList.addAll((List<SObject>)listviewCon.getrecords());
            }

            String whereClause = getFilteredAccounts(currentListViewId);
            if(String.isBlank(whereClause)) {
                whereClause = '';
            } else {
                whereClause = ' WHERE ' + whereClause;
            }
            System.debug('init===>whereClause ' + whereClause);
            String quertyString = 'SELECT '
                                  + queryFields
                                  + ' FROM '
                                  + targetType.getDescribe().getName()
                                  + whereClause
                                  + ' ORDER BY '
                                  + sortField
                                  + sortOrder;

            System.debug(quertyString);
            List<SObject> sortObjList = Database.query(quertyString);

            Map<Integer, SObject> objMap = new Map<Integer, SObject>();
            for(SObject obj:objList) {
                Integer index = sortObjList.indexOf(obj);
                if(index > 0) {
                    objMap.put(index, obj);
                }
            }

            List<Integer> sortInt = new List<Integer>(objMap.keyset());
            List<SObject> showObjList = new List<SObject>();
            sortInt.sort();
            for(Integer i: sortInt) {
                showObjList.add(objMap.get(i));
            }
            try{
                con = new ApexPages.StandardSetController(showObjList);
            } catch(Exception e) {
                con = new ApexPages.StandardSetController(Database.getQueryLocator(quertyString));
            }


            if(!con.getCompleteResult()) {
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
                    'The maximum record limit for StandardSetController is 10,000 records. '
                    + 'Instantiating StandardSetController using a query locator returning more than 10,000 records causes a LimitException to be thrown. '
                    + 'However, instantiating StandardSetController with a list of more than 10,000 records doesn’t throw an exception, and instead truncates the records to the limit.'));
            }
            if(pSize == null) {
                pSize = con.getPageSize();
            }
            con.setPageSize(pSize);
            totalPageNo = (con.getResultSize() / pSize) + 1;
            
            if(isKeepSelected) {
                System.debug(selectedObjList);
                con.setSelected(selectedObjList);
                isKeepSelected = false;
            }
        }
    }

    public List<Wrapper> getWrappers() {
        wrapperList = new List<Wrapper>();
        Set<SObject> selectedSet = new Set<SObject>(con.getSelected());
        Set<Id> selectedIdSet = new Set<Id>();
        for(SObject obj:selectedSet) {
            selectedIdSet.add(obj.Id);
        }
        for(SObject obj:con.getrecords()) {
            wrapperList.add(new Wrapper(obj, selectedIdSet.contains(obj.Id)));
        }
        if(isAllCheck()) {
            checkAllFlg = true;
        } else {
            checkAllFlg = false;
        }
        return wrapperList;
    }
    
    public class Wrapper {
        public SObject obj {get;set;}
        public Boolean isChecked {get;set;}
        public List<String> valueList {get;set;} 
        public Wrapper(SObject pObj, Boolean pFlg) {
            this.obj = pObj;
            this.isChecked = pFlg;
            valueList = new List<String>();
            Map<String ,Object> FVMap = this.obj.getPopulatedFieldsAsMap();
            //for(String fieldName: FVMap.keyset()) {
                valueList.add((String)FVMap.get('Id'));
                valueList.add((String)FVMap.get('Name'));
            //}
        }
        public String get(String fName) {
            return (String)obj.get(fName);
        } 
    }

    public void first() {
        handleSelectedList();
        con.first();
    }

    public void previous() {
        handleSelectedList();
        con.previous();
    }

    public void next() {
        handleSelectedList();
        con.next();
    }

    public void last() {
        handleSelectedList();
        con.last();
    }
    public void save() {
        handleSelectedList();
        con.save();
    }

    public void handleSelectedList() {
        List<SObject> currentPageSelected = new List<SObject>();
        for(Wrapper w: wrapperList) {
            if(w.isChecked) {
                currentPageSelected.add(w.obj);
            }
        }
        if(selectedMap == null) {
            selectedMap = new Map<Integer, List<SObject>>();
            selectedMap.put(con.getPageNumber(), currentPageSelected);
        } else {
            selectedMap.put(con.getPageNumber(), currentPageSelected);
        }
        List<SObject> tmpSelectedObjList = new List<SObject>();
        if(isKeepSelected && selectedObjList != null) {
             tmpSelectedObjList = selectedObjList;
        }
        selectedObjList = new List<SObject>();
        for(Integer i: selectedMap.keyset()) {
            selectedObjList.addAll(selectedMap.get(i));
        }
        if(isKeepSelected && tmpSelectedObjList.size() > 0){
            selectedObjList.AddAll(tmpSelectedObjList);
        }
        
        Set<SObject> objSet = new Set<SObject>(selectedObjList);
        selectedObjList.clear();
        selectedObjList.addAll(objSet);

        con.setSelected(selectedObjList);
    }

    public Boolean isAllCheck() {
        if(wrapperList == null) {
            return false;
        }
        for(Wrapper w: wrapperList) {
            if(!w.isChecked) {
                return false;
            }
        }
        return true;
    }

    public void toggleAll() {
        Boolean allCheckedFlg = true;
        Boolean allUnCheckedFlg = true;
        for(Wrapper w: wrapperList) {
            if(w.isChecked) {
                allUnCheckedFlg = false;
            } else {
                allCheckedFlg = false;
            }
        }

        if(allCheckedFlg && !allUnCheckedFlg) {
            for(Wrapper w: wrapperList) {
                w.isChecked = false;
            }
        } else {
            for(Wrapper w: wrapperList) {
                w.isChecked = true;
            }
        }

        handleSelectedList();
    }

    public void updateCount() {
        handleSelectedList();
    }

    public void go() {
        selectedMap = null;
        handleSelectedList();
        if(selectedListViewId != currentListViewId) {
            con = null;
            init();
        }
    }

    public void setPaSize() {
        isKeepSelected = true;
        handleSelectedList();
        if(pSize != 0) {
            if(pSize <= 1000) {
                con = null;
                init();
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'PageSize over 1000.')); 
            }

        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'PageSize is 0.'));
        }
    }

    public void gotoPage() {
        handleSelectedList();
        if(pPage != 0) {
            if(pPage <= totalPageNo) {
                con.setPageNumber(pPage);
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'PageNo over max.'));
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'PageNo is 0.'));
        }
    }

    public void sort() {
        isKeepSelected = true;
        handleSelectedList();
        con = null;
        init();
    }
    public static String getFilteredAccounts(String filterId){
        HttpRequest req = new HttpRequest();
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String endPoinURL = baseUrl+'/services/data/v41.0/sobjects/Account/listviews/'+filterId+'/describe';

        req.setEndpoint(endPoinURL);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        Http http = new Http();
        HTTPResponse response = http.send(req);
        Map<String, Object> tokenResponse = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
        String query = (String) tokenResponse.get('query');

        return query.substringBetween('WHERE ', 'ORDER ');
    }
}