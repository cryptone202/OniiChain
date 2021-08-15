// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IHypnosis.sol";
import "./interfaces/IHypnosisDescriptor.sol";
import "./chainlink/VRFConsumerBase.sol";

/// @title Hypnosis NFTs
/// @notice On-chain generated NFTs
contract Hypnosis is ERC721Enumerable, Ownable, IHypnosis, ReentrancyGuard, VRFConsumerBase {
    /// @dev Price for one Onii
    uint256 private constant _unitPrice = 0.01 ether;

    /// @dev Number of sales to increase the price
    uint256 private constant _step = 5000;

    /// @dev Count the number of calls to the create function
    uint256 private createCall = 0;

    /// @dev The token ID onii detail
    mapping(uint256 => Detail) private _detail;

    /// @dev The address of the token descriptor contract, which handles generating token URIs.
    address private immutable _tokenDescriptor;

    /// @dev all oniis generated based on ids hash
    mapping(bytes32 => bool) private oniis;

    /// @dev Chainlink keyhash
    bytes32 internal keyHash;

    /// @dev Chainlink RNG fee
    uint256 internal fee;

    /// @dev Number received from chainlink RNG
    uint256 internal randomResult = 0;

    /// @dev Rate to request RN to chainlink
    uint256 public chainlinkRate = 20;

    constructor(address _tokenDescriptor_)
        ERC721("Hypnosis", "HYPNO")
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK Token
        )
    {
        _tokenDescriptor = _tokenDescriptor_;
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10**18;
    }

    // save bytecode by removing implementation of unused method
    function _baseURI() internal view virtual override returns (string memory) {}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return IHypnosisDescriptor(_tokenDescriptor).tokenURI(this, tokenId);
    }

    /// @notice Create randomly an Onii
    /// @param qty The quantity to buy
    function create(uint256 qty) public payable nonReentrant {
        require(msg.value >= getUnitPrice() * qty, "Ether sent is not correct");
        createCall++;

        // Every 20 calls, update randomResult
        if (createCall % chainlinkRate == 0 && LINK.balanceOf(address(this)) >= fee) {
            requestRandomness(keyHash, fee);
        }

        for (uint256 i; i < qty; i++) {
            uint256 seed = (block.timestamp + randomResult) << (i + 1);
            uint256 nextTokenId = totalSupply() + 1;
            Detail memory newDetail = Detail({
                hair: IHypnosisDescriptor(_tokenDescriptor).generateHairId(nextTokenId, seed),
                eye: IHypnosisDescriptor(_tokenDescriptor).generateEyeId(nextTokenId, seed),
                eyebrow: IHypnosisDescriptor(_tokenDescriptor).generateEyebrowId(nextTokenId, seed),
                nose: IHypnosisDescriptor(_tokenDescriptor).generateNoseId(nextTokenId, seed),
                mouth: IHypnosisDescriptor(_tokenDescriptor).generateMouthId(nextTokenId, seed),
                tatoo: IHypnosisDescriptor(_tokenDescriptor).generateTatooId(nextTokenId, seed),
                earrings: IHypnosisDescriptor(_tokenDescriptor).generateEarringsId(nextTokenId, seed),
                accessory: IHypnosisDescriptor(_tokenDescriptor).generateAccessoryId(nextTokenId, seed),
                expression: IHypnosisDescriptor(_tokenDescriptor).generateExpressionId(nextTokenId, seed),
                skin: IHypnosisDescriptor(_tokenDescriptor).generateSkinId(nextTokenId, seed),
                original: true,
                timestamp: block.timestamp,
                creator: msg.sender
            });
            newDetail.original = copyOnii(newDetail);
            _detail[nextTokenId] = newDetail;
            _safeMint(msg.sender, nextTokenId);
        }
    }

    /// @notice Get the current price of one Onii
    /// The price is progressive. Every 5000 sales, the price increases by 0.01 ether
    /// @return The Onii price
    function getUnitPrice() public view returns (uint256) {
        return ((totalSupply() / _step) * _unitPrice) + _unitPrice;
    }

    function updateChainlinkRate(uint256 _chainlinkRate) external onlyOwner {
        require(_chainlinkRate > 0, "Must be > 0");
        chainlinkRate = _chainlinkRate;
    }

    /// @notice Send funds from sales to the owner
    function withdrawAll() public payable onlyOwner {
        require(payable(0x838D23a8A17adaa6866969b86D35Ac0941C67510).send(address(this).balance));
    }

    /// @inheritdoc IHypnosis
    function details(uint256 tokenId) external view override returns (Detail memory detail) {
        detail = _detail[tokenId];
    }

    /// @dev Callback function used by VRF Coordinator
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }

    /// @dev Check is an onii already exists (based on details)
    /// @return False if it already exists, true if not
    function copyOnii(Detail memory detail) internal returns (bool) {
        bytes32 hash = keccak256(
            abi.encode(
                detail.hair,
                detail.eye,
                detail.eyebrow,
                detail.nose,
                detail.mouth,
                detail.tatoo,
                detail.earrings,
                detail.accessory,
                detail.expression,
                detail.skin
            )
        );
        if (!oniis[hash]) {
            oniis[hash] = true;
            return true;
        } else {
            return false;
        }
    }
}
