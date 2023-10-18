// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract Ex4_34 {
    function fun1() public pure returns(uint) {
        uint result = 0;
        for(uint a = 0; a<4; ++a){
            if(a==1){
                continue;
            }
            result = result + a;
        }
        return result;
    }
}
