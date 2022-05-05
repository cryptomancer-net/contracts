pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: GPT-3

import "@openzeppelin/contracts/access/Ownable.sol";

contract Cryptomancer is Ownable {
    uint8 public feePercentage = 1;
    mapping(bytes32 => uint256) public balances;
    
    event Deposited(address indexed sender, bytes32 indexed hash, uint256 amount);
    event Claimed(address indexed recipient, bytes32 indexed hash, uint256 amount);
    
    constructor() {}
    
    function deposit(bytes32[] memory shaHashes) public payable {
        uint256 fee = (msg.value * uint256(feePercentage * 100)) / uint256(10000); 
        payable(owner()).transfer(fee);
        
        uint256 amount = msg.value - fee;
        
        for (uint256 i = 0; i < shaHashes.length; i++) {
            bytes32 shaHash = shaHashes[i];
            uint256 recipientAmount = amount / shaHashes.length;
            balances[shaHash] = recipientAmount;
            emit Deposited(msg.sender, shaHash, recipientAmount);
        }
    }
    
    function claim(string memory password, address recipient) public {
        bytes32 shaHash = keccak256(abi.encodePacked(password));
        
        if (balances[shaHash] > 0) {
            payable(recipient).transfer(balances[shaHash]);
            balances[shaHash] = 0;
            emit Claimed(recipient, shaHash, balances[shaHash]);
        }
    }
}