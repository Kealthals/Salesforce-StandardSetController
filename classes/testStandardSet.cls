public class testStandardSet {
	 
    public ApexPages.StandardSetController con {get;set;}
    public List<Account> selectedAccList;
    public List<Wrapper> wrapperList;
    public Map<Integer, List<Account>> selectedMap;
    public Boolean checkAllFlg {get;set;}
    public List<SelectOption> listViewList {get;set;}
    public Id selectedListViewId {get;set;}
    public Integer pSize {get;set;}
    public Integer pPage {get;set;}
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

    public testStandardSet() {
        init();
    }
    
    private void init() {
        if(con == null) {
            //con = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Id, Name FROM Account]));
            con = new ApexPages.StandardSetController([SELECT Id, Name FROM Account]);
            if(!con.getCompleteResult()) {
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'The maximum record limit for StandardSetController is 10,000 records. Instantiating StandardSetController using a query locator returning more than 10,000 records causes a LimitException to be thrown. However, instantiating StandardSetController with a list of more than 10,000 records doesn’t throw an exception, and instead truncates the records to the limit.'));
            }
            if(pSize == null) {
                pSize = con.getPageSize();
            }
            con.setPageSize(pSize);
            totalPageNo = (con.getResultSize() / pSize) + 1;
            listViewList = con.getListViewOptions();
            if(String.isBlank(selectedListViewId)) {
                selectedListViewId = con.getFilterId();
            } else {
                con.setFilterId(selectedListViewId);
            }
            
        }
    }

    public List<Wrapper> getWrappers() {
    	wrapperList = new List<Wrapper>();
    	Set<Account> selectedSet = new Set<Account>((List<Account>)con.getSelected());
    	for(Account acc:(List<Account>)con.getrecords()) {
    		wrapperList.add(new Wrapper(acc, selectedSet.contains(acc)));
    	}
        if(isAllCheck()) {
            checkAllFlg = true;
        } else {
            checkAllFlg = false;
        }
    	return wrapperList;
    }
    
    public class Wrapper {
    	public Account acc {get;set;}
    	public Boolean isChecked {get;set;}
    	public Wrapper(Account pAcc, Boolean pFlg) {
    		this.acc = pAcc;
    		this.isChecked = pFlg;
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
        List<Account> currentPageSelected = new List<Account>();
        for(Wrapper w: wrapperList) {
            if(w.isChecked) {
                currentPageSelected.add(w.acc);
            }
        }

        if(selectedMap == null) {
            selectedMap = new Map<Integer, List<Account>>();
            selectedMap.put(con.getPageNumber(), currentPageSelected);
        } else {
            selectedMap.put(con.getPageNumber(), currentPageSelected);
        }

        selectedAccList = new List<Account>();
        for(Integer i: selectedMap.keyset()) {
            selectedAccList.addAll(selectedMap.get(i));
        }

        con.setSelected(selectedAccList);
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
        handleSelectedList();
        con = null;
        init();
    }

    public void setPaSize() {
        handleSelectedList();
        if(pSize != 0) {
            con = null;
            init();
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'PageSize is 0.'));
        }
    }

    public void gotoPage() {
        handleSelectedList();
        if(pPage != 0) {
            if(pPage < totalPageNo) {
                con.setPageNumber(pPage);
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'PageNo over max.'));
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'PageNo is 0.'));
        }
    }
}