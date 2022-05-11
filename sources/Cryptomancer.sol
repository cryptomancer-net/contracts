pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: GPT-3

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
// import "@opengsn/contracts/src/BaseRelayRecipient.sol";

contract Cryptomancer is Ownable {
    using ECDSA for bytes32;

    uint8 public largeFeePercentage = 5;
    uint8 public smallFeePercentage = 1;
    address public administrator;
    mapping(address => uint256) public balances;
    mapping(address => address) public recipientDepositors;
    
    event Deposited(address indexed depositor, address indexed recipient, uint256 amount, bool paidGasFees);
    event Claimed(address indexed recipient, uint256 amount);
    event Revoked(address indexed depositor, address indexed recipient, uint256 amount);
    
    constructor(address _admin) {
        administrator = _admin;
    }
    
    function setFeePercentage(uint8 percent, bool large) public onlyOwner {
        if (large) {
            largeFeePercentage = percent;
        } else {
            smallFeePercentage = percent;
        }
    }
    
    function deposit(address[] memory recipients, bool payGasFees) public payable {
        uint256 amount = msg.value;

        if (payGasFees) {
            uint256 gasFee = tx.gasprice * gasleft() * recipients.length;
            require(msg.value >= gasFee + (0.001 ether), 'Minimum value is (gasFee * count(recipients)) + 0.001 ETH');
            payable(administrator).transfer(gasFee);
            amount -= gasFee;

            uint256 fee = (amount * uint256(smallFeePercentage * 100)) / uint256(10000); 
            payable(owner()).transfer(fee);
            amount -= fee;
        } else {
            require(msg.value >= 0.001 ether, 'Minimum value is 0.001 ETH');

            uint256 fee = (amount * uint256(largeFeePercentage * 100)) / uint256(10000); 
            payable(owner()).transfer(fee);
            amount -= fee;
        }
        
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 recipientAmount = amount / recipients.length;
            if (payGasFees) {
                balances[recipient] = recipientAmount;
                recipientDepositors[recipient] = msg.sender;
            } else {
                payable(recipient).transfer(recipientAmount);
            }
            emit Deposited(msg.sender, recipient, recipientAmount, payGasFees);
        }
    }
    
    function claim(address recipient, bytes memory signature) public {
        require(balances[recipient] > 0, 'No balance for recipient');

        bytes32 message = keccak256(abi.encodePacked(recipient));
        address signer = message.toEthSignedMessageHash().recover(signature);

        require(signer == recipient, 'Signer not the same as recipient');
        
        payable(recipient).transfer(balances[recipient]);
        emit Claimed(recipient, balances[recipient]);
        balances[recipient] = 0;
    }
    
    function revoke(address[] memory recipients) public {
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            require(balances[recipient] > 0, 'No deposit for this recipient');
            require(recipientDepositors[recipient] == msg.sender, 'Not the depositor for this recipient');
            payable(msg.sender).transfer(balances[recipient]);
            emit Revoked(msg.sender, recipient, balances[recipient]);
            balances[recipient] = 0;
        }
    }
    
    function addToGasPool() public payable {
        payable(administrator).transfer(msg.value);
    }
}