pragma solidity ^0.4.10;

/*
    描述
        合约工具类
    author 
	    wn
	date
	    201906
*/
contract ContractUtil { 
    
    function equals(string _self, string _str) internal constant returns (bool _ret) {
        if (bytes(_self).length != bytes(_str).length) {
            return false;
        }

        for (uint i=0; i<bytes(_self).length; ++i) {
            if (bytes(_self)[i] != bytes(_str)[i]) {
                return false;
            }
        }
        
        return true;
	}
    
    function bytes32ToString(bytes32 x) internal constant returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    } 
    
    function trim(string _self) internal returns (string _ret) {
        uint i;
        uint8 ch;
        for (i=0; i<bytes(_self).length; ++i) {
            ch = uint8(bytes(_self)[i]);
            if (!(ch == 0x20 || ch == 0x09 || ch == 0x0D || ch == 0x0A)) {
                break;
            }
        }
        uint start = i;
        
        for (i=bytes(_self).length; i>0; --i) {
            ch = uint8(bytes(_self)[i-1]);
            if (!(ch == 0x20 || ch == 0x09 || ch == 0x0D || ch == 0x0A)) {
                break;
            }
        }
        uint end = i;
        
        _ret = new string(end-start);
        
        uint selfptr;
        uint retptr;
        assembly {
            selfptr := add(_self, 0x20)
            retptr := add(_ret, 0x20)
        }
        
        memcpy(retptr, selfptr+start, end-start);
    }
   
   function memcpy(uint dest, uint src, uint len) private {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
    
}
