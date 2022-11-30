// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


contract Egg is ERC721, Ownable {

    using SafeMath for uint256;

    uint256 private constant priceOfEgg = 100000 * 10 ** 18;
    uint256 private constant standardPrize = 1000000 * 10 ** 18;

    address private constant BUSDAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private constant USDTAddress = 0x55d398326f99059fF775485246999027B3197955;
    address private constant USDCAddress = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    address private _chicken;
    address private _NPC = payable(0xA7EBBB5C7cc4733853A37bD2Eb3A2920Eff75324);

    address private _chickenTown = 0x4f5e949A3096F5A4604A501B65B658621dbedd33;
    address public _treasuryWallet =  payable(0xA7EBBB5C7cc4733853A37bD2Eb3A2920Eff75324);

    IUniswapV2Router02 uniswapV2Router;

    constructor() ERC721("Egg", "EggNFT") {

        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        uniswapV2Router = _uniswapV2Router;

    }

    modifier onlyNPC() {

        require(owner() == _msgSender() || _NPC == _msgSender(), "Caller is not the NPC");	

        _;	
    }

    modifier onlyChicken() {

        require(owner() == _msgSender() || _chicken == _msgSender(), "Caller is not the Chicken");	

        _;	
    }
    

    struct EggNFT {
        uint256 attribute;
    }

    EggNFT[] private Eggs;

    struct Prizes {
        uint16 firstPrize;
        uint16 secondPrize;
        uint16 thirdPrize;
        uint16 fourthPrize;
        uint16 fifthPrize;
        uint16 sixthPrize;

    }

    Prizes public _prizes = Prizes({
        firstPrize: 20000,
        secondPrize: 15000,
        thirdPrize: 10000,
        fourthPrize: 8000,
        fifthPrize: 5000,
        sixthPrize: 3000
    });

    function ChickenAddress() external view returns (address chicken) {
        
         chicken = _chicken;
    }

    function setChicken(address chicken) external onlyOwner {

        require(chicken != address(0), "Chicken is not NULL");

        _chicken = chicken;
    }

    function NPCAddress() external view returns (address NPC) {
        
         NPC = _NPC;
    }

    function setNPC(address NPC) external onlyOwner {

        require(NPC != address(0), "NPC is not NULL");

        _NPC = NPC;
    }

    function swapExactTokensForBNB(uint256 amount, address user) private {
        ERC20 Token = ERC20(_chickenTown);
        Token.approve(address(uniswapV2Router), amount);
        address[] memory path = new address[](2);
        path[0] = _chickenTown;
        path[1] = uniswapV2Router.WETH();
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            user,
            block.timestamp
        );
        
    }

    function swapExactTokensForBUSD(uint256 amount, address user) private {
        ERC20 Token = ERC20(_chickenTown);
        Token.approve(address(uniswapV2Router), amount);
        address[] memory path = new address[](2);
        path[0] = _chickenTown;
        path[1] = BUSDAddress;
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            user,
            block.timestamp
        );
        
    }

    function swapExactTokensForUSDT(uint256 amount, address user) private {
        ERC20 Token = ERC20(_chickenTown);
        Token.approve(address(uniswapV2Router), amount);
        address[] memory path = new address[](2);
        path[0] = _chickenTown;
        path[1] = USDTAddress;
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            user,
            block.timestamp
        );
        
    }

    function Prize(uint256 ID) private view returns (uint256) {

        if (Eggs[ID].attribute < 100 && Eggs[ID].attribute > 97) {

            return _prizes.fifthPrize * standardPrize ;

        } else if (Eggs[ID].attribute < 98 && Eggs[ID].attribute > 96) {

            return _prizes.secondPrize * standardPrize;

        } else if (Eggs[ID].attribute < 95 && Eggs[ID].attribute > 91) {

            return _prizes.thirdPrize * standardPrize;

        } else if (Eggs[ID].attribute < 90 && Eggs[ID].attribute > 71) {

            return _prizes.fourthPrize * standardPrize;

        } else if (Eggs[ID].attribute < 70 && Eggs[ID].attribute > 41) {

            return _prizes.fifthPrize * standardPrize;

        } else {

            return _prizes.sixthPrize * standardPrize;

        }

    }

    function getAttribute(uint256 xFactor) private  view returns (uint256) {
        bytes memory randomNumber;

        randomNumber = abi.encodePacked(
            xFactor,
            address(this),
            block.gaslimit,
            gasleft(),
            block.timestamp,
            block.number,
            msg.sig,
            blockhash(block.number),
            block.difficulty,
            msg.sender
        );  

        return uint(keccak256(randomNumber)).mod(90);
    }


    function getEggFromChicken(uint256 ID0, uint256 ID1, address user) external onlyChicken {

        uint256 ID = Eggs.length;

        uint256 attribute = getAttribute(uint256(keccak256(abi.encodePacked(ID0, ID1, user)))).add(8);

        Eggs.push(EggNFT(attribute));

        _safeMint(user, ID);

    }


    function getEggFromMadeChicken(uint256 ID0, address user) external onlyChicken {

        uint256 ID = Eggs.length;

        uint256 attribute = getAttribute(uint256(keccak256(abi.encodePacked(ID0, user))));

        Eggs.push(EggNFT(attribute));

        _safeMint(user, ID);

    }

    function getEggFromNPC(uint8 amount) external {

        require(ERC20(_chickenTown).balanceOf(msg.sender) >= amount * priceOfEgg, "You do not have enough ChickenTown");

        ERC20(_chickenTown).transferFrom(msg.sender, _NPC, amount * priceOfEgg);

        uint256 ID = Eggs.length;

        for (uint nftID = ID; nftID < ID + amount; nftID ++) {

            uint256 attribute = getAttribute(uint256(keccak256(abi.encodePacked(msg.sender)))).add(10);

            Eggs.push(EggNFT(attribute));

            _safeMint(msg.sender, nftID);

        }

    }


    function openEgg(uint256[] memory IDs) external {

        for (uint ID = 0; ID < IDs.length; ID++) {

            require(
                ownerOf(IDs[ID]) == msg.sender, "You are not owner"
            );

            uint256 factor = uint256(keccak256(abi.encodePacked(IDs[ID], block.number, msg.sender))).mod(4);

            if (factor == 0) {

                // swapExactTokensForBNB(Prize(ID), msg.sender);
                ERC20(_chickenTown).transferFrom(msg.sender, _treasuryWallet, Prize(IDs[ID]));

            } else if (factor == 1) {

                // swapExactTokensForBNB(Prize(ID), msg.sender);
                ERC20(_chickenTown).transferFrom(msg.sender, _treasuryWallet, Prize(IDs[ID]));

            } else if (factor == 2) {

                // swapExactTokensForUSDT(Prize(ID), msg.sender);
                ERC20(_chickenTown).transferFrom(msg.sender, _treasuryWallet, Prize(IDs[ID]));

            } else {

                ERC20(_chickenTown).transferFrom(msg.sender, _treasuryWallet, Prize(IDs[ID]));

            }

            transferFrom(msg.sender, DEAD, IDs[ID]);

        }

        


        
    }
}
