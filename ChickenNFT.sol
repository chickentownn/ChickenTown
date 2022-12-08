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

    IEgg private _Egg = IEgg(0xFB7BAe058261C7e12032ed024c5A2Be2AF116e09);

    uint256 private constant priceOfChicken = 1000 * 10 ** 9;
    address private constant NPC = 0x000000000000000000000000000000000000dEaD;
    address private _chickenTown = 0x61B07aBdf115A7F54a88ecf97Fb82750A99cDa9f;
    address public _treasuryWallet =  payable(0xA7EBBB5C7cc4733853A37bD2Eb3A2920Eff75324);
    uint256 private constant feed = 100 * 10 ** 9;

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
        uint256 countdown;
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

    function setchickenTown(address chickenTown) external onlyOwner {

        require(chickenTown != address(0), "Chicken Town address is not NULL address");

        _chickenTown = chickenTown;
    }


    function getCouple(uint256 ID0, uint256 ID1) external  view returns (uint256, uint256, uint256, uint256, uint256) {

        uint256 ID = uint256(keccak256(abi.encodePacked(ID0, ID1)));

        require(Chickens[ID0].IDCouple == ID && Chickens[ID1].IDCouple == ID, "They are not a couple");

        (uint256 nOE, uint256 countdown) = getEgg(ID0, ID1);

        return(ID, couples[ID].ID0, couples[ID].ID1, nOE, countdown);

    }

    function getChicken(uint256 ID) external view returns (uint256 dateOfBirth, uint256 dateOfDeath, uint256 eatTime, uint256 IDCouple, address Owner) {

        dateOfBirth = Chickens[ID].dateOfBirth;
        dateOfDeath = Chickens[ID].dateOfDeath;
        Owner = Chickens[ID].owner;
        IDCouple = Chickens[ID].IDCouple;
        eatTime = Chickens[ID].eatTime;

    }

    event ChickenInfo(uint256 nftID, address owner);

    function buyChicken(uint256 amount) external {

        uint256 ID = Chickens.length;

        for (uint nftID = ID; nftID < ID + amount; nftID ++) {

            ERC20(_chickenTown).transferFrom(msg.sender, _treasuryWallet, priceOfChicken);

            uint256 dateOfBirth = block.timestamp;
            uint256 dateOfDeath = dateOfBirth + 3 days;
            uint256 eatTime = block.timestamp;

            Chickens.push(ChickenNFT(dateOfBirth, dateOfDeath, 0, eatTime, false, msg.sender));
            
            _safeMint(msg.sender, nftID);

            emit ChickenInfo(nftID, msg.sender);

        }

    }

    function sellChickenForNPC(uint256[] memory IDs) external {
        for (uint ID = 0; ID < IDs.length; ID ++) {

            require(
                !Chickens[IDs[ID]].hasCouple, "Your chicken has couple, dont sell it"
            );

            transferFrom(msg.sender, NPC, IDs[ID]);
        }

    }

    function feedChicken(uint256 ID) private  {
        
        ERC20(_chickenTown).transferFrom(msg.sender, _treasuryWallet, feed);

        Chickens[ID].eatTime = block.timestamp;

    }

    function eatingTimeOfChicken(uint256 ID) private view returns (uint256) {

        if ((Chickens[ID].eatTime + 8 hours < block.timestamp) && (Chickens[ID].eatTime + 16 hours > block.timestamp)) {

            return 1;

            }  else if ((Chickens[ID].eatTime + 16 hours < block.timestamp) && (Chickens[ID].eatTime + 24 hours > block.timestamp)) {

            return 2;

            } else if (Chickens[ID].eatTime + 24 hours < block.timestamp)

            return 3;

        return 0;

    }

    function getEgg(uint256 ID0, uint256 ID1) private view returns (uint256, uint256) {

        uint256 ID = uint256(keccak256(abi.encodePacked(ID0, ID1)));

        if ((eatingTimeOfChicken(ID0) == 0) && (eatingTimeOfChicken(ID1) == 0)) {

            return (0, couples[ID].countdown);


            }  else  if ((eatingTimeOfChicken(ID0) == 1) && (eatingTimeOfChicken(ID1) == 1)) {


            return (1, couples[ID].countdown);

            }  else if ((eatingTimeOfChicken(ID0) == 2) && (eatingTimeOfChicken(ID1) == 2)) {
 
            return (2, couples[ID].countdown);

            }

        return (3, 0);
        
    }


    
    function claimEgg(uint256 ID0, uint256 ID1) external {

        (uint256 amountOfEgg, ) = getEgg(ID0, ID1);

        uint256 ID = uint256(keccak256(abi.encodePacked(ID0, ID1)));

        require(
            ownerOf(ID0) == msg.sender && ownerOf(ID1) == msg.sender, "You are not owner of these chickens");

        require(
            Chickens[ID0].IDCouple == ID && Chickens[ID1].IDCouple == ID, "Couple ID miss match !"
        );

        for (uint i = 0; i < amountOfEgg; i ++) {
            feedChicken(ID0);

            feedChicken(ID1);

            _Egg.getEggFromChicken(ID0, ID1, msg.sender);
        }
            Chickens[ID0].eatTime = block.timestamp;

            Chickens[ID1].eatTime = block.timestamp;

            


    }
    function madeChicken(uint256[] memory IDs) external {
        for (uint ID = 0; ID < IDs.length; ID ++) {
            require(
                !Chickens[IDs[ID]].hasCouple, "Your chicken has couple, dont kill it"
            );

            transferFrom(msg.sender, NPC, IDs[ID]);

            _Egg.getEggFromMadeChicken(IDs[ID], msg.sender);
        }
    }


    function createCouple(uint256 ID0, uint256 ID1) external {

        require(
            !Chickens[ID0].hasCouple && !Chickens[ID1].hasCouple, "Chicken has couple"
        );
        require(
            ownerOf(ID0) == msg.sender && ownerOf(ID1) == msg.sender, "You dont have Chicken"
        );

        ERC20(_chickenTown).transferFrom(msg.sender, _treasuryWallet, feed);

        uint256 ID = uint256(keccak256(abi.encodePacked(ID0, ID1)));
        Chickens[ID0].hasCouple = true;
        Chickens[ID1].hasCouple = true;
        Chickens[ID0].IDCouple = ID;
        Chickens[ID1].IDCouple = ID;
        couples[ID].ID0 = ID0;
        couples[ID].ID1 = ID1;
        couples[ID].countdown = block.timestamp;

        

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
