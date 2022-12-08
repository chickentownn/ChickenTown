// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface ITicketNFT {

    function mintTo(address receiver) external returns (uint256) ;

}

interface IcChickenTown {

    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256); 
    
}

contract ChristmasTree is Ownable {

    using SafeMath for uint256;

    ITicketNFT private ticketAddress = ITicketNFT(0x941C502ae24f133AD63d9505fB9752665D0682e2) ; 

    IcChickenTown private cChickenTown = IcChickenTown(0x176cd780f9aB07d9046aA91b90C15d08E15993db); 

    uint256 _startBlock;

    uint256 _endBlock;

    uint256 private currentGift;

    uint256 private currentToken;

    uint256 private currentNFT;

    uint256 private airDrop = 2500 * 10 ** 9;

    mapping(address => bool) private isClaimed;
    
    function setInformation(uint256 startBlock, uint256 endBlock) external onlyOwner {

        _startBlock = startBlock;
        _endBlock = endBlock;
        
    }

    function claimGift() external {

        require(block.number >= _startBlock || block.number <= _endBlock, "Not time to mint");

        require(!isClaimed[msg.sender], "Only one");

        uint256 xFactor = getGift(msg.sender);

        xFactor > 50 ? NFT(msg.sender) : Token(msg.sender);

        currentGift += 1;

        isClaimed[msg.sender] == true;


    }

    function getGift(address receiver) private  view returns (uint256) {

        bytes memory randomNumber;

        randomNumber = abi.encodePacked(
            receiver,
            address(this),
            block.gaslimit,
            gasleft(),
            block.timestamp,
            block.number,
            msg.sig,
            blockhash(block.number),
            block.difficulty
        );  

        return uint(keccak256(randomNumber)).mod(100);
    }

    function getInformation() public view returns (uint256, uint256, uint256, uint256, uint256) {

        return ( _startBlock, _endBlock, currentGift, currentToken, currentNFT);

    }

    event GiftInfo(uint256 typeOfGift);

    function NFT(address receiver) private {

        ticketAddress.mintTo(receiver);

        currentNFT += 1;

        emit GiftInfo(0);

    }


    function Token(address receiver) private {

        if (IcChickenTown(cChickenTown).balanceOf(address(this)) == 0) {

            NFT(receiver);

        } else {

            IcChickenTown(cChickenTown).transfer(receiver, airDrop);

            currentToken += airDrop;

            emit GiftInfo(1);

        }

    }

}
