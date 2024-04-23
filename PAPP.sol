// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract test is ERC721A, ERC2981, Ownable(msg.sender), ReentrancyGuard {
    struct PhaseProps {
        bool saleActive;
        bool whitelistActive;
        bytes32 root;
        uint256 price;
    }

    uint256 public MAX_TOKENS = 10000;
    uint256 public perAddressLimit = 2;

    bool public revealed = false;

    string private _baseTokenURI;
    string public notRevealedUri;
    mapping(address => uint256) public addressMintedBalance;

    mapping(uint8 => PhaseProps) public mintPhases;

    constructor() ERC721A("test", "test") {}

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function mintToken(
        uint256 amount,
        bytes32[] calldata proof,
        uint8 phase
    ) external payable {
        require(mintPhases[phase].saleActive, "Sale must be active to mint");

        require(
            addressMintedBalance[msg.sender] + amount <= perAddressLimit,
            "Max NFT per address exceeded"
        );
        require(
            !mintPhases[phase].whitelistActive || verify(proof, phase),
            "Address not whitelisted"
        );

        require(
            totalSupply() + amount <= MAX_TOKENS,
            "Purchase would exceed max supply"
        );
        require(
            msg.value >= mintPhases[phase].price * amount,
            "Not enough ETH for transaction"
        );

        addressMintedBalance[msg.sender] += amount;

        _mint(msg.sender, amount);
    }

    function changePhaseProps(uint8 phase, PhaseProps calldata phaseProps)
        public
        onlyOwner
    {
        mintPhases[phase] = phaseProps;
    }

    function getPhaseProps(uint8 phase)
        public
        view
        returns (PhaseProps memory)
    {
        return mintPhases[phase];
    }

    function airdropToken(uint256 amount, address to) public onlyOwner {
        require(
            totalSupply() + amount <= MAX_TOKENS,
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
            "Unowned token"
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

    function setPrice(uint256 newPrice, uint8 phase) external onlyOwner {
        mintPhases[phase].price = newPrice;
    }

    function setPerAddressLimit(uint256 newLimit)
        external
        onlyOwner
    {
        perAddressLimit = newLimit;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function flipReveal() public onlyOwner {
        revealed = !revealed;
    }

    function flipSaleState(uint8 phase) external onlyOwner {
        mintPhases[phase].saleActive = !mintPhases[phase].saleActive;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function setRoot(bytes32 _root, uint8 phase) external onlyOwner {
        mintPhases[phase].root = _root;
    }

    function verify(bytes32[] memory proof, uint8 phase)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, mintPhases[phase].root, leaf);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMaxTokens(uint256 amount) external onlyOwner {
        MAX_TOKENS = amount;
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
