// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract test is
    ERC721A,
    ERC2981,
    Ownable(msg.sender),
    ReentrancyGuard
{
    uint256 public constant MAX_TOKENS = 10000;
    uint256 public presaleTokensSold = 0;
    uint256 public constant NUMBER_RESERVED_TOKENS = 0;
    uint256 public PRICE = 8000000000000000;
    uint256 public perAddressLimit = 2; 

    bool public saleIsActive = false; 
    bool public preSaleIsActiveOne = false; 
    bool public preSaleIsActiveTwo = false;
    bool public preSaleIsActiveThree = false; 
    bool public whitelist = true;
    bool public revealed = false;

    uint256 public reservedTokensMinted = 0;
    string private _baseTokenURI; 
    string public notRevealedUri; 
    bytes32 rootOne;
    bytes32 rootTwo;
    bytes32 rootThree;
    mapping(address => uint256) public addressMintedBalance;

    construct() ERC721A('test', 'test'){}

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function mintToken(
        uint256 amount
    ) external payable {
        require(saleIsActive, "Sale must be active to mint");

        require(
            addressMintedBalance[msg.sender] + amount <= perAddressLimit,
            "Max NFT per address exceeded"
        );
        require(
            totalSupply() + amount <= MAX_TOKENS,
            "Purchase would exceed max supply"
        );
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");

        _safeMint(msg.sender, amount);
    }

    function mintTokenWlOne(
        uint256 amount,
        bytes32[] memory proof
    ) external payable {
        require(preSaleIsActiveOne, "Sale must be active to mint");

        require(
            addressMintedBalance[msg.sender] + amount <= perAddressLimit,
            "Max NFT per address exceeded"
        );
        require(!whitelist || verifyOne(proof), "Address not whitelisted");

        require(
            totalSupply() + amount <=
                MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted),
            "Purchase would exceed max supply"
        );
        require(msg.value >= 4000000000000000 * amount, "Not enough ETH for transaction");

        presaleTokensSold += amount;
        addressMintedBalance[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function mintTokenWlTwo(
        uint256 amount,
        bytes32[] memory proof
    ) external payable {
        require(preSaleIsActiveTwo, "Sale must be active to mint");

        require(
            addressMintedBalance[msg.sender] + amount <= perAddressLimit,
            "Max NFT per address exceeded"
        );
        require(!whitelist || verifyTwo(proof), "Address not whitelisted");

        require(
            totalSupply() + amount <=
                MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted),
            "Purchase would exceed max supply"
        );
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");

        presaleTokensSold += amount;
        addressMintedBalance[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function mintTokenWlThree(
        uint256 amount,
        bytes32[] memory proof
    ) external payable {
        require(preSaleIsActiveThree, "Sale must be active to mint");

        require(
            addressMintedBalance[msg.sender] + amount <= perAddressLimit,
            "Max NFT per address exceeded"
        );
        require(!whitelist || verifyThree(proof), "Address not whitelisted");

        require(
            totalSupply() + amount <=
                MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted),
            "Purchase would exceed max supply"
        );
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");

        presaleTokensSold += amount;
        addressMintedBalance[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function airdropToken(uint256 amount, address to) public onlyOwner {
        require(
            totalSupply() + amount <=
                MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted),
            "Purchase would exceed max supply"
        );

        _safeMint(to, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        require(
            ownerOf(tokenId) == msg.sender,
            "User doesn't own the given token"
        );
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() public onlyOwner {
        super._deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        super._setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) public onlyOwner {
        super._resetTokenRoyalty(tokenId);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        PRICE = newPrice;
    }

    function setPerAddressLimit(uint256 newLimit)
        external
        onlyOwner //Change max per wallet address last minute
    {
        perAddressLimit = newLimit;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleStateOne() external onlyOwner {
        preSaleIsActiveOne = !preSaleIsActiveOne;
    }

    function flipPreSaleStateTwo() external onlyOwner {
        preSaleIsActiveTwo = !preSaleIsActiveTwo;
    }

    function flipPreSaleStateThree() external onlyOwner {
        preSaleIsActiveThree = !preSaleIsActiveThree;
    }

    function flipWhitelistingState() external onlyOwner {
        whitelist = !whitelist;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function setRootOne(bytes32 _root) external onlyOwner {
        rootOne = _root;
    }

    function setRootTwo(bytes32 _root) external onlyOwner {
        rootTwo = _root;
    }

    function setRootThree(bytes32 _root) external onlyOwner {
        rootThree = _root;
    }

    function verifyOne(bytes32[] memory proof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, rootOne, leaf);
    }

    function verifyTwo(bytes32[] memory proof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, rootTwo, leaf);
    }

    function verifyThree(bytes32[] memory proof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, rootThree, leaf);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return
            bytes(_tokenURI).length > 0
                ? string(abi.encodePacked(_tokenURI, ".json"))
                : "";
    }
}
