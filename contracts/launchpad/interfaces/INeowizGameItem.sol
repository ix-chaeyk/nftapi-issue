// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface INeowizGameItem {
    event Lock(uint256 tokenId);
    event Unlock(uint256 tokenId);
    event LaunchpadAllowed(address launchpad);
    event LaunchpadDenied(address launchpad);

    error NotAllowedLaunchpad();
    error NotOwnerOrTokenOwner();
    error Locked();
    error NotRevealed();

    function migrate(address _launchpad, uint256 _tokenId) external;

    function mint(address _to, string memory _uri) external;

    function burn(uint256 _tokenId) external;

    function lock(uint256 _tokenId) external;

    function unlock(uint256 _tokenId) external;

    function allowLaunchpad(address _launchpad) external;

    function denyLaunchpad(address _launchpad) external;
}
