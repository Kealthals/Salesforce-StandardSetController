public class testStandardSet {
	 
	public ApexPages.StandardSetController con;
	public List<Account> selectedAccList;
	public List<Wrapper> wrapperList;
	public Map<Integer, List<Account>> selectedMap;
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
        if(con == null) {
            con = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Id, Name FROM Account]));
            con.setPageSize(10);
            totalPageNo = (con.getResultSize() / 10) + 1;
        }
    }
    
    public List<Wrapper> getWrappers() {
    	wrapperList = new List<Wrapper>();
    	Set<Account> selectedSet = new Set<Account>(getSelectedList());
    	for(Account acc:(List<Account>)con.getrecords()) {
    		wrapperList.add(new Wrapper(acc, selectedSet.contains(acc)));
    	}
    	return wrapperList;
    }
    
    public List<Account> getSelectedList() {
    	return con.getSelected();
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


    public Boolean hasPrevious {
        get{
            return con.getHasPrevious();
        }
        set;
    }

    public Boolean hasNext {
        get{
            return con.getHasNext();
        }
        set;
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
}