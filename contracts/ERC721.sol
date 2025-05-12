// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC721Full.sol";

contract ERC721 {
    string public name;
    string public symbol;

    uint256 public nextTokenIdToMint;
    address public owner;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;
    // Mapping from owner address to token count
    mapping(address => uint256) internal _balances;
    // Mapping from token ID to approved address
    mapping(uint256 => address) internal _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;
    // Mapping from token ID to token URI
    mapping(uint256 => string) internal _tokenURIs;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        nextTokenIdToMint = 1;
        owner = msg.sender;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(
            _owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[_owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address ownerAddress = _owners[tokenId];
        require(
            ownerAddress != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return ownerAddress;
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public {
        require(
            ownerOf(_tokenId) == msg.sender ||
                _tokenApprovals[_tokenId] == msg.sender ||
                _operatorApprovals[ownerOf(_tokenId)][msg.sender],
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(_from, _to, _tokenId);

        require(
            _checkOnERC721Received(_from, _to, _tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public payable {
        require(
            ownerOf(_tokenId) == msg.sender ||
                _tokenApprovals[_tokenId] == msg.sender ||
                _operatorApprovals[ownerOf(_tokenId)][msg.sender],
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public {
        require(
            ownerOf(_tokenId) == msg.sender,
            "ERC721: approve caller is not token owner"
        );
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(ownerOf(_tokenId), _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        require(_operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        require(
            _owners[_tokenId] != address(0),
            "ERC721: approved query for nonexistent token"
        );
        return _tokenApprovals[_tokenId];
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) public view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function mint(address _to, string memory _tokenURI) public {
        require(msg.sender == owner, "Only the contract owner can mint tokens");

        uint256 tokenId = nextTokenIdToMint;
        _owners[tokenId] = _to;
        _balances[_to] += 1;
        _tokenURIs[tokenId] = _tokenURI;

        emit Transfer(address(0), _to, tokenId);

        nextTokenIdToMint++;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(
            _owners[tokenId] != address(0),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return _tokenURIs[tokenId];
    }

    function totalSupply() public view returns (uint256) {
        return nextTokenIdToMint - 1;
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == 0x80ac58cd || // ERC721
            interfaceId == 0x5b5e139f || // ERC721Metadata
            interfaceId == 0x01ffc9a7; // ERC165
    }

    // INTERNAL FUNCTIONS
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.code.length > 0) {
            try
                IERC721Full(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Full.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // unsafeTransferFrom
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(
            ownerOf(_tokenId) == _from,
            "ERC721: transfer of token that is not own"
        );
        require(_to != address(0), "ERC721: transfer to the zero address");

        delete _tokenApprovals[_tokenId];
        _balances[_from] -= 1;
        _balances[_to] += 1;
        _owners[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }
}
