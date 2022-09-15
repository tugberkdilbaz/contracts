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

    string private baseURI ;

    uint256 public price = 0.002 ether;

    uint256 public maxPerTx = 50;

    uint256 public maxFreePerWallet = 1;

    uint256 public totalFree = 3000;

    uint256 public maxSupply = 5000;

    bool public mintEnabled = true;
    
    uint   public totalFreeMinted = 0;

    mapping(address => uint256) private _mintedFreeAmount;

    constructor() ERC721A("On Chain", "ONCHAIN") {}

   function mint(uint256 count) external payable {
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

        _safeMint(msg.sender, count);
    }

    function tokenURI(uint256 tokenId)
        public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
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
