// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./details/BackgroundDetail.sol";
import "./details/BodyDetail.sol";
import "./details/HairDetail.sol";
import "./details/MouthDetail.sol";
import "./DetailCaller.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library NFTDescriptor {
    struct SVGParams {
        uint8 hair;
        uint8 eye;
        uint8 nose;
        uint8 mouth;
        uint8 background;
        uint8 skin;
        uint256 timestamp;
        address creator;
    }

    function generateSVGImage(SVGParams memory params) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    generateSVGHead(),
                    DetailCaller.getDetailSVG(address(BackgroundDetail), params.background),
                    DetailCaller.getDetailSVG(address(BodyDetail), params.skin),
                    DetailCaller.getDetailSVG(address(MouthDetail), params.mouth),
                    DetailCaller.getDetailSVG(address(HairDetail), params.hair),
                    "</svg>"
                )
            );
    }

    function generateName(uint8 backgroundId, uint256 tokenId) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(BackgroundDetail.getItemNameById(backgroundId), " Onii ", Strings.toString(tokenId))
            );
    }

    function generateSVGHead() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" x="0px" y="0px"',
                    'viewBox="0 0 420 420" style="enable-background:new 0 0 420 420;" xml:space="preserve">'
                )
            );
    }
}
