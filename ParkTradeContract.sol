pragma solidity ^0.4.10;

import "./Table.sol";
import "./ContractUtil.sol";
import "./ConstantContract.sol";

/*
    描述
        停车交易合约
    author 
	    wn
	date
	    201904
*/
contract ParkTradeContract is ConstantContract,ContractUtil {
	
    event addParkTradeEvent(int256 ret);
	    
    constructor() public {
        // 构造函数中创建
        createTable();
    }

    function createTable() private {
        TableFactory tf = TableFactory(0x1001); 
        // 停车交易, key : cAccount, field : nAccount,orderNo、amount、payType、pCode、carNo、payTime、onchainTime
        tf.createTable(table_name_park_trade, "cAccount", "nAccount,orderNo,amount,payType,pCode,carNo,payTime,onchainTime");
    }

    function openTable() private returns(Table) {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable(table_name_park_trade);
        return table;
    }
    
    // 打开资产表
    function openTable_assets() private returns(Table) {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable(table_name_assets);
        return table;
    }
    
    /*
	    描述 : 查询资产账户是否存在
	    参数 ：account : 账户
	    返回值：
	          参数一： 不存在返回0, 存在返回1
    */
    function isExistAccount(string account) private constant returns(int256) {
        // 打开表
        Table table = openTable_assets();
        // 查询
        Entries entries = table.select(account, table.newCondition());
        if (0 == uint256(entries.size())) {
            return 0;
        } else {
            return 1;
        }
    }
    
    /*
	    描述 : 查询账户资产
	    参数 ：account : 账户
	    返回值：
	          参数一： 账户存在返回0, 不存在返回-1
	          参数二： 账户存在返回对应资产，不存在返回0
    */
    function getBalanceByAccount(string account) private constant returns(int256,int256) {
        int256 result = isExistAccount(account);
        if(result == 0){
            return (-1,0);
        }
        // 打开表
        Table table = openTable_assets();
        // 查询
        Entries entries = table.select(account, table.newCondition());
        Entry entry = entries.get(0);
        return (0,int256(entry.getInt("balance")));
    }
    
    /*
	    描述 : 根据车牌账户和订单号查询订单信息
	    参数 ：
	          参数一：车牌账户
	          参数二：订单号
	    返回值：
	          参数一： 车牌账户和订单号同时存在返回0, 不存在返回-1
	          参数二： 节点地址
	          参数三： 停车交易详情（支付金额、支付类型(1：现金；2：支付宝；3：微信；4：其他)、场库编号、车牌号、支付时间、上链时间）
    */
    function getOrderDetailByAccount(string cAccount,string orderNo) public constant returns(int256,address,bytes32[]) {
        // 打开表
        Table table = openTable();
        // 查询
        Condition condition = table.newCondition();
        condition.EQ("orderNo",orderNo);
        Entries entries = table.select(cAccount, condition);
        bytes32[] memory res = new bytes32[](6);
        address nAccount;
        address uAccount;
        if (0 == uint256(entries.size())) {
            return (-1,nAccount,res);
        } else {
            Entry entry = entries.get(0);
            nAccount = entry.getAddress("nAccount");
            
            res[0] = entry.getBytes32("amount");
            res[1] = entry.getBytes32("payType");
            res[2] = entry.getBytes32("pCode");
            res[3] = entry.getBytes32("carNo");
            res[4] = entry.getBytes32("payTime");
            res[5] = entry.getBytes32("onchainTime");
            
            return (0,nAccount,res);
        }
    }
    
    /*
	    描述 : 根据车牌账户查询历史交易记录
	    参数 ：
	          参数一：车牌账户
	    返回值：
	          参数一： 车牌账户存在返回0, 不存在返回-1
	          参数三： 支付金额、支付类型、支付订单号、支付时间、
    */
    function getOrdersByCarNo(string cAccount) public constant returns (int[],int[],bytes32[],bytes32[]) {
        // 打开表
        Table table = openTable();
        // 查询
        Condition condition = table.newCondition();
        condition.EQ("cAccount",cAccount);
        condition.limit(0,5);
        Entries entries = table.select(cAccount, condition);
        bytes32[] memory orderList = new bytes32[](uint256(entries.size()));
        bytes32[] memory payTimeList = new bytes32[](uint256(entries.size()));
        int[] memory amountList = new int[](uint256(entries.size()));
        int[] memory payTypeList = new int[](uint256(entries.size()));
        
        for(int i=0; i<entries.size(); ++i) {
            Entry entry = entries.get(i);
            
            orderList[uint256(i)] = entry.getBytes32("orderNo");
            payTimeList[uint256(i)] = entry.getBytes32("payTime");
            amountList[uint256(i)] = entry.getInt("amount");
            payTypeList[uint256(i)] = entry.getInt("payType");
        }
        
        return (amountList, payTypeList, orderList, payTimeList);
        
    }
    
    /*
	    描述 ：
	          根据账户和订单号判断记录否存在
	    参数 ：
	          参数一：车牌账户
	          参数二：订单号
	    返回值：
	          参数一： 账户和订单号同时存在返回0, 不存在返回-1
    */
    function isExistTrade(string cAccount,string orderNo) private constant returns(int256) {
        // 打开表
        Table table = openTable();
        // 查询
        Condition condition = table.newCondition();
        condition.EQ("orderNo",orderNo);
        Entries entries = table.select(cAccount, condition);
        if (0 == uint256(entries.size())) {
            return 0; //不存在记录
        } else {
            return -1; // 存在记录
        }
    }

    /*
	    描述 ：
	        上传停车交易
	    参数 ： 
	        参数一： 车牌账户
	        参数二： 节点账户
	        参数三： 订单号
	        参数四： 支付金额以分为单位）
	        参数一： 订单数据[]
	        		    订单号、
	        		    支付类型(1：现金；2：支付宝；3：微信；4：其他)、
	        		    场库编号、
	        		    车牌号、
	        		    支付时间
	    返回值：
             0 添加成功
            -1 用户对应的车辆信息已存在
            -2 合约的其他错误
            -3 车牌账户不存在
		    -4 节点账户不存在
		    -5 支付金额不能为负值
    */
    function addParkTrade(string cAccount,string nAccount,string carNo,int256 amount,bytes32[] parmList) public returns (bool){
        int256 ret_code = 0;
        int256 ret= 2;
        
        if(amount < 0){
            ret_code = -5;
            emit addParkTradeEvent(ret_code);
            return false;
        }
        ret = isExistAccount(cAccount);
        if(ret == 0) {
            ret_code = -3;
            emit addParkTradeEvent(ret_code);
            return false;
        }
        
        ret = isExistAccount(nAccount);
        if(ret == 0) {
            ret_code = -4;
            emit addParkTradeEvent(ret_code);
            return false;
        }
        
        // 查询订单号是否存在
        ret = isExistTrade(cAccount,trim(bytes32ToString(parmList[0])));
        
        if(ret == 0) {
            Table table = openTable();
            
            Entry entry = table.newEntry();
            entry.set("cAccount", cAccount);
            entry.set("nAccount", nAccount);
            entry.set("carNo",carNo);
            entry.set("amount", int256(amount));
            entry.set("orderNo", trim(bytes32ToString(parmList[0])));
            entry.set("payType", trim(bytes32ToString(parmList[1])));
            entry.set("pCode", trim(bytes32ToString(parmList[2])));
            entry.set("payTime", trim(bytes32ToString(parmList[3])));
            entry.set("onchainTime", int256(now));
            
            // 插入
            int count = table.insert(cAccount, entry);
            if (count == 1) {
                // 创生资产
                transfer(nAccount,cAccount,amount);
                // 成功
                ret_code = 0;
            } else {
                // 失败? 无权限或者其他错误
                ret_code = -2;
            }
        } else {
            // 信息已存在
            ret_code = -1;
        }
        
        emit addParkTradeEvent(ret_code);
        return true;
    }
    
    /*
	    描述 : 停车业务资产转移（仅且只对停车业务）
	    参数 ： 
	        from_account : 转移资产账户
	        to_account ： 接收资产账户
	        balance ： 转移金额
	    返回值：
             0 资产转移成功
            -1 转移资产账户不存在
            -2 接收资产账户不存在
            -3 金额不足
            -4 金额溢出
            -5 其他错误
    */
    function transfer(string from_account, string to_account, int256 balance) private returns (int256) {
        // 查询转移资产账户信息
        int ret_code = 0;
        int256 ret = 0;
        int256 from_asset_value = 0;
        int256 to_asset_value = 0;
        
        // 获取转账户的资产
        (ret,from_asset_value) = getBalanceByAccount(from_account);
        if(ret == -1){
            ret_code = -1;
        }

        // 获取接收方账户资产信息
        (ret,to_asset_value) = getBalanceByAccount(to_account);
        if(ret == -1){
            ret_code = -2;
        }
        
        if (to_asset_value + balance < to_asset_value) {
            ret_code = -4;
            // 接收账户金额溢出
            return ret_code;
        }

        Table table = openTable_assets();

        Entry entry0 = table.newEntry();
        entry0.set("account", from_account);
        entry0.set("balance", add(from_asset_value,balance));
        
        // 更新转账账户资产
        int count = table.update(from_account, entry0, table.newCondition());
        if(count != 1) {
            ret_code = -5;
            // 失败? 无权限或者其他错误?
            return ret_code;
        }
        
        Entry entry1 = table.newEntry();
        entry1.set("account", to_account);
        entry1.set("balance", add(to_asset_value,balance));
        // 更新接收账户
        table.update(to_account, entry1, table.newCondition());
    }
   
    function add(int256 a, int256 b) internal returns (int256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
   
}