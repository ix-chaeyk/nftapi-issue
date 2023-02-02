// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {BaseTransferHelper} from "./BaseTransferHelper.sol";

contract ERC721TransferHelper is BaseTransferHelper {
    constructor(address _moduleManager) BaseTransferHelper(_moduleManager) {}

    function safeTransferFrom(address _token, address _from, address _to, uint256 _tokenId)
        public
        onlyRegisteredModule
    {
        IERC721(_token).safeTransferFrom(_from, _to, _tokenId);
    }

    function transferFrom(address _token, address _from, address _to, uint256 _tokenId) public onlyRegisteredModule {
        IERC721(_token).transferFrom(_from, _to, _tokenId);
    }
}
