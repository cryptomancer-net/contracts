pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: GPT-3

import "@openzeppelin/contracts/access/Ownable.sol";

contract Cryptomancer is Ownable {
    uint8 public feePercentage = 1;
    mapping(address => uint256) public balances;
    
    event Sent(address indexed sender, address indexed recipient, uint256 amount);
    event Claimed(address indexed recipient, uint256 amount);
    
    constructor() {}
    
    function setFeePercentage(uint8 percent) public onlyOwner {
        feePercentage = percent;
    }
    
    function send(address[] memory addresses) public payable {
        uint256 fee = (msg.value * uint256(feePercentage * 100)) / uint256(10000); 
        payable(owner()).transfer(fee);
        
        uint256 amount = msg.value - fee;
        
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            uint256 recipientAmount = amount / addresses.length;
            balances[addr] = recipientAmount;
            emit Sent(msg.sender, addr, recipientAmount);
        }
    }
    
    function claim(address recipient, bytes32 sig) public {
        bytes32 message = prefixed(keccak256(abi.encodePacked(recipient, this)));

        require(recoverSigner(message, sig) == recipient);
        require(balances[recipient] > 0);
        
        payable(recipient).transfer(balances[recipient]);
        balances[recipient] = 0;
        emit Claimed(recipient, balances[recipient]);
    }
    
    function prefixed(bytes32 message) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
    }
    
    function splitSignature(bytes32 sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
    
    function recoverSigner(bytes32 message, bytes32 sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }
}