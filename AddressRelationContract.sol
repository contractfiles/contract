pragma solidity ^0.4.10;

import "./Table.sol";
import "./ContractUtil.sol";
import "./ConstantContract.sol";

/*
	说明 
	          注册合约账户
	author 
	    wn
	date
	    201904
*/
contract AddressRelationContract is ConstantContract,ContractUtil {

    event BuildAddressRelationEvent(int256 ret);
    
    constructor() public {
        createTable();
        createTable_assets();
    }

    // 创建映射表
    function createTable() private {
        TableFactory tf = TableFactory(0x1001); 
        // 用户表, key : addressKey, field : account、_type、status、addTime、onchainTime
        // 创建表
        tf.createTable(table_name_addressRelation, "addressKey", "account,_type,status,addTime,onchainTime");
    }
    
    // 创建资产表
    function createTable_assets() private {
        TableFactory tf = TableFactory(0x1001); 
        // 合约注册 key : account, field : balance、_type、status、addTime、onchainTime
        tf.createTable(table_name_assets, "account", "balance,_type,status,addTime,onchainTime");
    }
    
    // 打开映射表
    function openTable() private returns(Table) {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable(table_name_addressRelation);
        return table;
    }

    // 打开资产表
    function openTable_assets() private returns(Table) {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable(table_name_assets);
        return table;
    }
    
    // 打开map表
    function openTable_map() private returns(Table) {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable(table_name_map);
        return table;
    }
    
    /*
	    描述 : 查询map表是否存在指定key
	    参数 ：_key : 键
	    返回值：
	          参数一： 存在返回1, 不存在返回0
    */
    function isExistMapKey(string _key) private constant returns(int256) {
        // 打开表
        Table table = openTable_map();
        // 查询
        Entries entries = table.select(_key, table.newCondition());
        if (0 == uint256(entries.size())) {
            return 0;
        } else {
            return 1;
        }
    }
    
    /*
	    描述 : 根据map中的key获取value
	    参数 ：_key 键
	    返回值：
	          参数一： 成功返回0, 键不存在返回-1
	          参数二： 存在键返回value, 不存在键则返回空字符串
    */
    function getValue(string _key) private constant returns(int256,int256) {
        // 查询键是否存在
        int256 ret = isExistMapKey(_key);
        if(ret == 1) {
            // 打开表
            Table table = openTable_map();
            // 查询
            Entries entries = table.select(_key, table.newCondition());
            Entry entry = entries.get(0);
            return (0,entry.getInt("_value"));
        }else {
            return (-1,0);
        }
    }
    
    /*
	    描述 : 向map中添加或修改数据
	    参数 ： 
	      参数一： 键
	      参数二： 值
	    返回值：
                 0 执行成功
                -1 执行异常
    */
    function updateValue(string _key, int256 _value) private returns(int256) {
        int256 ret_code = 0;
        int256 ret= 0;
        int256 value = 0;
        // 查询键是否存在
        ret = isExistMapKey(_key);
        if(ret == 1) { // 修改map中的数据
            
            (ret,value) = getValue(_key);
        
            Table table_update = openTable_map();
            Entry entry_u = table_update.newEntry();
            entry_u.set("_key", _key);
            entry_u.set("_value", value+_value);
            
            Condition c = table_update.newCondition();
            c.EQ("_key", _key);
            
            // 更新
            int count = table_update.update(_key, entry_u, c);
            if (count == 1) {
                // 成功
                ret_code = 0;
            } else {
                // 失败? 无权限或者其他错误
                ret_code = -1;
            }
        } else { // 向map中添加数据
            Table table_add = openTable_map();
            Entry entry_add = table_add.newEntry();
            entry_add.set("_key", _key);
            entry_add.set("_value", _value);
            
            // 插入
            int count_add = table_add.insert(_key, entry_add);
            if (count_add == 1) {
                // 成功
                ret_code = 0;
            } else {
                // 失败? 无权限或者其他错误
                ret_code = -1;
            }
        }
        return ret_code;
    }
    
    /*
	    描述 : 查询账户key对应的address
	    参数 ：addressKey : 账户key
	    返回值：
	          参数一： 成功返回0, 账户不存在返回-1
	          参数二： key不存在返回"",存在返回账户地址
    */
    function getAddressByKey(string addressKey) public constant returns(int256,address,int256) {
        // 打开表
        Table table = openTable();
        // 查询
        Entries entries = table.select(addressKey, table.newCondition());
        address addr ;
        int256 _addTime; 
        if (0 == uint256(entries.size())) {
            return (-1,addr,_addTime);
        } else {
            Entry entry = entries.get(0);
            addr = entry.getAddress("account");
            _addTime = entry.getInt("onchainTime");
            return (0,addr,_addTime);
        }
    }
    
    /*
	    描述 ：根据地址key查询用户账户是否存在
	    参数 ：addressKey : 账户key
	    返回值：
	          参数一： 不存在返回0, 存在返回1
    */
    function isExistKey(string addressKey) private constant returns(int256) {
        // 打开表
        Table table = openTable();
        // 查询
        Entries entries = table.select(addressKey, table.newCondition());
        if (0 == uint256(entries.size())) {
            return 0;
        } else {
            return 1;
        }
    }

    /*
	    描述 ：注册账户
	    参数 ： 
	      addressKey : 账户key
	      account  : 账户
	      type : 账户类型（0:车辆；1：用户；2：节点）
	      status : 状态（0：正常；1：其他）
	      addTime ： 添加时间
	    返回值：
             0 信息添加成功
            -1 信息已存在
            -2 其他错误
    */
    function buildRelation(string addressKey, string account,string _type,string status) public {
        int256 ret_code = 0;
        int256 ret= 0;
        // 查询信息是否存在
        ret = isExistKey(addressKey);
        if(ret == 0) {
            Table table = openTable();
            
            Entry entry = table.newEntry();
            entry.set("addressKey", addressKey);
            entry.set("account", account);
            entry.set("_type", _type);
            entry.set("status", status);
            entry.set("onchainTime", int256(now));
            
            // 插入
            int count = table.insert(addressKey, entry);
            if (count == 1) {
                // 向资产表插入一条记录，默认资产为0
                Table tableAssets = openTable_assets();
                Entry entry_assets = tableAssets.newEntry();
                entry_assets.set("account", account);
                entry_assets.set("balance", 0);
                entry_assets.set("_type", _type);
                entry_assets.set("status", 0);
                entry_assets.set("onchainTime", int256(now));
                tableAssets.insert(account, entry_assets);
                // 成功
                ret_code = 0;
                // 增加统计
                if(equals(_type,"0")){
                    updateValue("_carSum",1);
                }
                if(equals(_type,"1")){
                    updateValue("_userSum",1);
                }
                
            } else {
                // 失败? 无权限或者其他错误
                ret_code = -2;
            }
        } else {
            // 账户已存在
            ret_code = -1;
        }

        emit BuildAddressRelationEvent(ret_code);
    }

}