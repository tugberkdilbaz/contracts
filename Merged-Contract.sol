// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "base64-sol/base64.sol";

contract ONCHAIN is ERC721A, Ownable {

    using Strings for uint256;

    uint256 public price = 0 ether;

    uint256 public maxPerTx = 50;

    uint256 public maxFreePerWallet = 5;

    uint256 public totalFree = 3000;

    uint256 public maxSupply = 5000;

    bool public mintEnabled = true;
    
    uint   public totalFreeMinted = 0;

    mapping(address => uint256) private _mintedFreeAmount;

    using Strings for uint256;
  
 string[] public wordsValues = ["accomplish","accepted","absolutely","admire","achievement","active","adorable","affirmative","appealing","approve","amazing","awesome","beautiful","believe","beneficial","bliss","brave","brilliant","calm","celebrated","champion","charming","congratulation","cool","courageous","creative","dazzling","delightful","divine","effortless","electrifying","elegant","enchanting","energetic","enthusiastic","excellent","exciting","exquisite","fabulous","fantastic","fine","fortunate","friendly","fun","funny","generous","giving","great","happy","harmonious","healthy","heavenly","honest","honorable","impressive","independent","innovative","intelligent","intuitive","kind","knowledgeable","legendary","lucky","lovely","marvelous","motivating","nice","perfect","phenomenal","popular","positive","productive","refreshing","remarkable","skillful","sparkling","stunning","successful","supporting","terrific","tranquil","trusting","vibrant","wholesome","worthy","wonderful"];
  
   struct Word { 
      string name;
      string description;
      string value;
   }
  
  mapping (uint256 => Word) public words;

    constructor() ERC721A("On Chain", "ONCHAIN") {}

   function mint(uint256 count) external payable {
        uint256 supply = totalSupply();
    
        Word memory newWord = Word(
        string(abi.encodePacked('PWA #', uint256(supply + 1).toString())), 
        "Pretty Awesome Words are all you need to feel good. These NFTs are there to inspire and uplift your spirit.",
        wordsValues[randomNum(wordsValues.length, block.difficulty, supply)]);
        
        uint256 cost = price;
        bool isFree = ((totalFreeMinted + count < totalFree + 1) &&
            (_mintedFreeAmount[msg.sender] < maxFreePerWallet));
        
        if (isFree) { 
            require(mintEnabled, "Mint is not live yet");
            require(totalSupply() + count <= maxSupply, "No more");
            require(count <= maxPerTx, "Max per TX reached.");
            if(count >= (maxFreePerWallet - _mintedFreeAmount[msg.sender]))
            {
             require(msg.value >= (count * cost) - ((maxFreePerWallet - _mintedFreeAmount[msg.sender]) * cost), "Please send the exact ETH amount");
             _mintedFreeAmount[msg.sender] = maxFreePerWallet;
             totalFreeMinted += maxFreePerWallet;
            }
            else if(count < (maxFreePerWallet - _mintedFreeAmount[msg.sender]))
            {
             require(msg.value >= 0, "Please send the exact ETH amount");
             _mintedFreeAmount[msg.sender] += count;
             totalFreeMinted += count;
            }
        }

        else{
        require(mintEnabled, "Mint is not live yet");
        require(msg.value >= count * cost, "Please send the exact ETH amount");
        require(totalSupply() + count <= maxSupply, "Sold out");
        require(count <= maxPerTx, "Max per TX reached.");
        }

         words[supply + 1] = newWord;
        _safeMint(msg.sender, count);
    }

   function randomNum(uint256 _mod, uint256 _seed, uint _salt) public view returns(uint256) {
      uint256 num = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, _salt))) % _mod;
      return num;
  }

  
  function buildImage(uint256 _tokenId) public view returns(string memory) {
      Word memory currentWord = words[_tokenId];
      return Base64.encode(bytes(
          abi.encodePacked(
              '<svg width="500" height="500" xmlns="http://www.w3.org/2000/svg">',
              '<text x="50%" y="50%" dominant-baseline="middle" fill="#FFFFFF" text-anchor="middle" font-size="41">',currentWord.value,'</text>',
              '</svg>'
          )
      ));
  }
  
  function buildMetadata(uint256 _tokenId) public view returns(string memory) {
      Word memory currentWord = words[_tokenId];
      return string(abi.encodePacked(
              'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                          '{"name":"', 
                          currentWord.name,
                          '", "description":"', 
                          currentWord.description,
                          '", "image": "', 
                          'data:image/svg+xml;base64,', 
                          buildImage(_tokenId),
                          '"}')))));
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
      return buildMetadata(_tokenId);
  }


    function setFreeAmount(uint256 amount) external onlyOwner {
        totalFree = amount;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function toggleMint() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
    

}
