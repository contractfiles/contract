pragma solidity ^0.4.10;

import "./Table.sol";
import "./ConstantContract.sol";

/*
	描述
	          资产合约
	author 
	    wn
	date
	    201904
*/
contract AssetsContract is ConstantContract {
    
    event TransferEvent(int256 ret, string from_account, string to_account, uint256 amount);
    
    function openTable() private returns(Table) {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable(table_name_assets);
        return table;
    }

    /*
	    描述 ：查询账户资产
	    参数 ：account : 账户
	    返回值：
	          参数一： 账户存在返回0, 不存在返回-1
	          参数二： 账户存在返回对应资产，不存在返回0
    */
    function getBalanceByAccount(string account) public constant returns(int256,uint256) {
        int256 result = isExistAccount(account);
        if(result == 0){
            return (-1,0);
        }
        // 打开表
        Table table = openTable();
        // 查询
        Entries entries = table.select(account, table.newCondition());
        Entry entry = entries.get(0);
        return (0,uint256(entry.getInt("balance")));
    }
    
    /*
	    描述 : 查询资产账户是否存在
	    参数 ：account : 账户
	    返回值：
	          参数一： 不存在返回0, 存在返回1
    */
    function isExistAccount(string account) private constant returns(int256) {
        // 打开表
        Table table = openTable();
        // 查询
        Entries entries = table.select(account, table.newCondition());
        if (0 == uint256(entries.size())) {
            return 0;
        } else {
            return 1;
        }
    }
    
    /*
        描述 : 资产转移
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
    function transfer(string from_account, string to_account, uint256 balance) public returns(int256) {
        // 查询转移资产账户信息
        int ret_code = 0;
        int256 ret = 0;
        uint256 from_asset_value = 0;
        uint256 to_asset_value = 0;
       
        // 转移账户是否存在?
        ret = isExistAccount(from_account);
        if(ret == 0) {
            ret_code = -1;
            // 转移账户不存在
            emit TransferEvent(ret_code, from_account, to_account, balance);
            return ret_code;
        }
        // 接受账户是否存在?
        ret = isExistAccount(to_account);
        if(ret == 0) {
            ret_code = -2;
            // 接收资产的账户不存在
            emit TransferEvent(ret_code, from_account, to_account, balance);
            return ret_code;
        }
       
        (ret,from_asset_value) = getBalanceByAccount(from_account);
        if(ret == -1){
            ret_code = -1;
        }
       
        if(from_asset_value < balance) {
            ret_code = -3;
            // 转移资产的账户金额不足
            emit TransferEvent(ret_code, from_account, to_account, balance);
            return ret_code;
        }
        (ret,to_asset_value) = getBalanceByAccount(to_account);
        if(ret == -1){
            ret_code = -2;
        }
       
        if (to_asset_value + balance < to_asset_value) {
            ret_code = -4;
            // 接收账户金额溢出
            emit TransferEvent(ret_code, from_account, to_account, balance);
            return ret_code;
        }
        Table table = openTable();
        Entry entry0 = table.newEntry();
        entry0.set("account", from_account);
        entry0.set("balance", int256(from_asset_value - balance));
        // 更新转账账户
        int count = table.update(from_account, entry0, table.newCondition());
        if(count != 1) {
            ret_code = -5;
            // 失败? 无权限或者其他错误?
            emit TransferEvent(ret_code, from_account, to_account, balance);
            return ret_code;
        }
        Entry entry1 = table.newEntry();
        entry1.set("account", to_account);
        entry1.set("balance", int256(to_asset_value + balance));
        // 更新接收账户
        table.update(to_account, entry1, table.newCondition());
        emit TransferEvent(ret_code, from_account, to_account, balance);
        return ret_code;
    }
    
    
}