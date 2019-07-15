pragma solidity ^0.4.10;

import "./Table.sol";
import "./ContractUtil.sol";
import "./ConstantContract.sol";


/*
    key / value 存储合约
*/
contract FidesumMapContract is ConstantContract,ContractUtil {

    
    // event
    event FidesumMapEvent(int256 ret);
    
    constructor() public {
        // 构造函数中创建表
        createTable();
    }

    function createTable() private {
        TableFactory tf = TableFactory(0x1001); 
        // map表, key : _key, field : _value
        // 创建表
        tf.createTable(table_name_map, "_key", "_value");
    }

    function openTable() private returns(Table) {
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
    function isExistKey(string _key) private constant returns(int256) {
        // 打开表
        Table table = openTable();
        // 查询
        Entries entries = table.select(_key, table.newCondition());
        if (0 == uint256(entries.size())) {
            return 0;
        } else {
            return 1;
        }
    }
    
    /*
	    描述 : 根据key获取value
	    参数 ：_key 键
	    返回值：
	          参数一： 成功返回0, 键不存在返回-1
	          参数二： 存在键返回value, 不存在键则返回空字符串
    */
    function getValue(string _key) public constant returns(int256,string) {
        // 查询键是否存在
        int256 ret = isExistKey(_key);
        if(ret == 1) {
            // 打开表
            Table table = openTable();
            // 查询
            Entries entries = table.select(_key, table.newCondition());
            Entry entry = entries.get(0);
            return (0,trim(bytes32ToString(entry.getBytes32("_value"))));
        }else {
            return (-1,"");
        }
    }

    /*
	    描述 : 向map表中添加数据
	    参数 ： 
	      参数一： 键
	      参数二： 值
	    返回值：
                 0 添加成功
                -1 键已存在
                -2 其他错误
    */
    function setValue(string _key, string _value) public returns(int256){
        int256 ret_code = 0;
        int256 ret= 0;
        // 查询键是否存在
        ret = isExistKey(_key);
        if(ret == 0) {
            Table table = openTable();
            
            Entry entry = table.newEntry();
            entry.set("_key", _key);
            entry.set("_value", _value);
            
            // 插入
            int count = table.insert(_key, entry);
            if (count == 1) {
                // 成功
                ret_code = 0;
            } else {
                // 失败? 无权限或者其他错误
                ret_code = -2;
            }
        } else {
            // 键已存在
            ret_code = -1;
        }

        emit FidesumMapEvent(ret_code);

        return ret_code;
    }
    
    /*
	    描述 : 修改map中的数据
	    参数 ： 
	      参数一： 键
	      参数二： 值
	    返回值：
                 0 修改成功
                -1 键不存在
                -2 其他错误
    */
    function updateValue(string _key, string _value) private returns(int256){
        int256 ret_code = 0;
        int256 ret= 0;
        // 查询键是否存在
        ret = isExistKey(_key);
        if(ret == 1) {
            Table table = openTable();
            
            Entry entry = table.newEntry();
            entry.set("_key", _key);
            entry.set("_value", _value);
            
            Condition condition = table.newCondition();
            condition.EQ("_key", _key);
            
            // 修改
            int count = table.update(_key, entry, condition);
            if (count == 1) {
                // 成功
                ret_code = 0;
            } else {
                // 失败? 无权限或者其他错误
                ret_code = -2;
            }
        } else {
            // 键不存在
            ret_code = -1;
        }

        emit FidesumMapEvent(ret_code);

        return ret_code;
    }
    
}