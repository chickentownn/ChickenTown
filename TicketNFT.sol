// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TicketNFT is ERC721, Ownable {
  
  using Counters for Counters.Counter;

  Counters.Counter private currentTokenId;

  string public baseTokenURI;

  address private _gift;

  constructor() ERC721("TicketNFT", "TicketNFT") {

    baseTokenURI = "https://ticket.chickentown.co/metadata/";

  }


    modifier onlyGift() {

        require(owner() == _msgSender() || _gift == _msgSender(), "Err");	

        _;	
    }
      

  function mintTo(address receiver) external onlyGift returns (uint256) {
    
    currentTokenId.increment();

    uint256 newItemId = currentTokenId.current();

    _safeMint(receiver, newItemId);

    return newItemId;
  }

    function setGift(address gift) external onlyGift {

        require(gift != address(0), "Gift is not NULL");

        _gift = gift;
    }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setBaseTokenURI(string memory _baseTokenURI) public onlyGift {
    baseTokenURI = _baseTokenURI;
  }
}
