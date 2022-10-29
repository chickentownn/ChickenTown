// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


interface IEgg {

    function getEggFromMadeChicken(uint256 ID0, address user) external;
    function getEggFromChicken(uint256 ID0, uint256 ID1, address user) external;
    
}
contract Chicken is ERC721, Ownable {

    using SafeMath for uint256;

    IEgg private _Egg = IEgg(0xCE13Cd5955D3E36815E3Bf01737d3BdBFBc195bf);

    uint256 private constant priceOfChicken = 100000 * 10 ** 18;
    address private constant NPC = 0x000000000000000000000000000000000000dEaD;
    address private chickenTown = 0x4f5e949A3096F5A4604A501B65B658621dbedd33;
    address public _treasuryWallet =  payable(0xA7EBBB5C7cc4733853A37bD2Eb3A2920Eff75324);
    uint256 private constant feed = 10000 * 10 ** 18;

    struct ChickenNFT {
        uint256 dateOfBirth;
        uint256 dateOfDeath;
        uint256 IDCouple;
        uint256 eatTime;
        bool hasCouple;
        address owner;
        
    }

    struct CoupleChicken {
        uint256 ID0;
        uint256 ID1;
        bool hasEgg;
    }

    mapping(uint256 => CoupleChicken) public couples;

    constructor() ERC721("Chicken", "ChickenNFT") {


    }

    ChickenNFT[] private Chickens;

    function EggAddress() external view returns (address Egg) {
        
         Egg = address(_Egg);
    }

    function setEgg(address Egg) external onlyOwner {

        require(Egg != address(0), "Chicken is not NULL");

        _Egg = IEgg(Egg);
    }

    function getCouple(uint256 ID0, uint256 ID1) external  view returns (uint256, uint256, uint256, bool hasEgg) {

        uint256 ID = uint256(keccak256(abi.encodePacked(ID0, ID1)));

        require(Chickens[ID0].IDCouple == ID && Chickens[ID1].IDCouple == ID, "They are not a couple");

        (Chickens[ID0].eatTime + 3 minutes < block.timestamp && Chickens[ID1].eatTime + 3 minutes < block.timestamp) ? hasEgg = true : hasEgg = false;

        return(ID, couples[ID].ID0, couples[ID].ID1, hasEgg);

    }

    function getChicken(uint256 ID) external view returns (uint256 dateOfBirth, uint256 dateOfDeath, uint256 eatTime, uint256 IDCouple, address Owner) {

        dateOfBirth = Chickens[ID].dateOfBirth;
        dateOfDeath = Chickens[ID].dateOfDeath;
        Owner = Chickens[ID].owner;
        IDCouple = Chickens[ID].IDCouple;
        eatTime = Chickens[ID].eatTime;

    }
    function buyChicken(uint256 amount) external {

        uint256 ID = Chickens.length;

        for (uint nftID = ID; nftID < ID + amount; nftID ++) {

            ERC20(chickenTown).transferFrom(msg.sender, _treasuryWallet, priceOfChicken);

            uint256 dateOfBirth = block.timestamp;
            uint256 dateOfDeath = dateOfBirth + 3 days;
            uint256 eatTime = block.timestamp;

            Chickens.push(ChickenNFT(dateOfBirth, dateOfDeath, 0, eatTime, false, msg.sender));
            
            _safeMint(msg.sender, nftID);

        }

    }

    function sellChickenForNPC(uint256 ID) external {

        require(
            !Chickens[ID].hasCouple, "Your chicken has couple, dont sell it"
        );

        transferFrom(msg.sender, NPC, ID);

    }

    function feedChicken(uint256 ID) private  {
        
        ERC20(chickenTown).transferFrom(msg.sender, _treasuryWallet, feed);

        Chickens[ID].eatTime = block.timestamp;

    }

    function getEgg(uint256 ID0, uint256 ID1) external {

        uint256 ID = uint256(keccak256(abi.encodePacked(ID0, ID1)));

        require(
            ownerOf(ID0) == msg.sender && ownerOf(ID1) == msg.sender, "You are not owner of these chickens");

        require(
            Chickens[ID0].IDCouple == ID && Chickens[ID1].IDCouple == ID, "Couple ID miss match !"
        );

        (Chickens[ID0].eatTime + 3 minutes < block.timestamp && Chickens[ID1].eatTime + 3 minutes < block.timestamp) ? couples[ID].hasEgg = true : couples[ID].hasEgg = false;

        require(couples[ID].hasEgg, "You do not have any egg");

        couples[ID].hasEgg = false;

        feedChicken(ID0);

        feedChicken(ID1);

        Chickens[ID0].eatTime = block.timestamp;

        Chickens[ID1].eatTime = block.timestamp;

        _Egg.getEggFromChicken(ID0, ID1, msg.sender);

        
    }

    function madeChicken(uint256 ID) external {

        require(
            !Chickens[ID].hasCouple, "Your chicken has couple, dont kill it"
        );

        transferFrom(msg.sender, NPC, ID);

        _Egg.getEggFromMadeChicken(ID, msg.sender);

    }


    function createCouple(uint256 ID0, uint256 ID1) external {

        require(
            !Chickens[ID0].hasCouple && !Chickens[ID1].hasCouple, "Chicken has couple"
        );
        require(
            ownerOf(ID0) == msg.sender && ownerOf(ID1) == msg.sender, "You dont have Chicken"
        );

        ERC20(chickenTown).transferFrom(msg.sender, _treasuryWallet, feed);

        uint256 ID = uint256(keccak256(abi.encodePacked(ID0, ID1)));
        Chickens[ID0].hasCouple = true;
        Chickens[ID1].hasCouple = true;
        Chickens[ID0].IDCouple = ID;
        Chickens[ID1].IDCouple = ID;
        couples[ID].ID0 = ID0;
        couples[ID].ID1 = ID1;

        

    }

    function deleteCouple(uint256 ID0, uint256 ID1) external  {

        require(
            Chickens[ID0].IDCouple == Chickens[ID1].IDCouple  , "Couple ID miss match !"
        );

        require(
            ownerOf(ID0) == msg.sender && ownerOf(ID1) == msg.sender, "You dont have Chicken"
        );

        Chickens[ID0].hasCouple = false;
        Chickens[ID1].hasCouple = false;
        Chickens[ID0].IDCouple = 0;
        Chickens[ID1].IDCouple = 0;

    }
}