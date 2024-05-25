// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MyNFT is ERC721 {
    uint256 public tokenIds = 1;

    constructor() ERC721("TicketGo", "TG") {}

    function mint(address _address, uint256 concertId, string memory credential, string memory areaName)
        public
        returns (bytes32)
    {
        // address audienceAddress;
        // uint256 concertId;
        // string credential;
        // string areaName;

        uint256 newItemId = tokenIds;
        _mint(_address, newItemId);
        tokenIds++;

        bytes32 hash = keccak256(abi.encode(concertId, credential, areaName));

        return hash;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {}

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {}
}
