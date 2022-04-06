//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


// import "hardhat/console.sol";

// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
// import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";  //Track Token Supply & Check 
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


import "./interfaces/IJurisdiction.sol";
import "./interfaces/IRules.sol";
import "./interfaces/ICase.sol";
// import "./libraries/DataTypes.sol";
// import "./abstract/ERC1155GUID.sol";
import "./abstract/ERC1155Roles.sol";
import "./abstract/Rules.sol";
// import "./abstract/Opinions.sol";
import "./abstract/CommonYJ.sol";

import "./Case.sol";


/**
 * @title Jurisdiction Contract
 * @dev Retains Group Members in Roles
 * V1: Role NFTs
 * - Mints Member NFTs
 * - One for each
 * - All members are the same
 * - Rules
 * - Creates new Cases
 * - Contract URI
 * - [TODO] Token URIs for Roles
 * - [TODO] Validation: Make Sure Account has an Avatar NFT -- Assign Avatars instead of Accounts
 * - [TODO] Rules are Unique
 * V2:  
 * - [TODO] NFT Trackers - Track the owner of the Avatar NFT
 */
// contract Jurisdiction is IJurisdiction, Rules, CommonYJ, ERC1155 {
// contract Jurisdiction is IJurisdiction, Rules, CommonYJ, ERC1155GUID {
contract Jurisdiction is IJurisdiction, Rules, CommonYJ, ERC1155Roles {
    //--- Storage
    string public constant override symbol = "YJ_Jurisdiction";
    using Strings for uint256;

    using Counters for Counters.Counter;
    // Counters.Counter internal _tokenIds; //Track Last Token ID
    Counters.Counter internal _caseIds;  //Track Last Case ID
    

    // Contract name
    string public name;
    // Contract symbol
    // string public symbol;
    //Contract URI
    string internal _contract_uri;

    // mapping(string => uint256) internal _roles;     //NFTs as Roles
    mapping(uint256 => address) internal _cases;      // Mapping for Case Contracts

    // mapping(uint256 => string) internal _rulesURI;      // Mapping Metadata URIs for Individual Role 

  
    //--- Functions

    /// ERC165 - Supported Interfaces
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IJurisdiction).interfaceId || interfaceId == type(IRules).interfaceId || super.supportsInterface(interfaceId);
    }

    // constructor(address hub) CommonYJ(hub) ERC1155(string memory uri_){
    // constructor(address hub) CommonYJ(hub) ERC1155(""){
    // constructor(address hub, address actionRepo) CommonYJ(hub) ERC1155Roles("") Rules(actionRepo){
    constructor(address hub, address actionRepo) CommonYJ(hub) ERC1155("") Rules(actionRepo){
        name = "Anti-Scam Jurisdiction";
        // symbol = "YJ_J1";
        //Init Default Jurisdiction Roles
        _roleCreate("admin");
        _roleCreate("member");
        _roleCreate("judge");
    }

    //** Case Functions

    
    /// Make a new Case
    // function caseMake(string calldata name_, DataTypes.RoleMappingInput[] memory roleMapping) public returns (uint256, address) {
    // function caseMake(string calldata name_, string calldata affected_) public returns (uint256, address) {
    // function caseMake(string calldata name_) public returns (uint256, address) {
    // function caseMake(string calldata name_, DataTypes.RuleRef[] calldata addRules) public returns (uint256, address) {
    function caseMake(string calldata name_, DataTypes.RuleRef[] calldata addRules, DataTypes.InputRole[] calldata assignRoles) public returns (uint256, address) {
        //TODO: Validate Caller Permissions

        //Rules

        //Role Mapping
        // Account -> Role + Rule Mapping??
        // DataTypes.RoleMappingInput[] memory roleMapping;

        //Assign Case ID
        _caseIds.increment(); //Start with 1
        uint256 caseId = _caseIds.current();

        // address caseContract = _HUB.caseMake(name_, addRules);
        address caseContract = _HUB.caseMake(name_, addRules, assignRoles);

        //Remember
        _cases[caseId] = caseContract;
        
        //Event
        emit CaseCreated(caseId, caseContract);
        
        return (caseId, caseContract);
    }
    

    /// Get Case Address by Case ID
    function getCaseById(uint256 caseId) public view returns (address) {
        return _cases[caseId];
    }
    
    //** Role Functions

    /// Join a role in current jurisdiction
    function join() external override {
        _GUIDAssign(_msgSender(), _stringToBytes32("member"));
    }

    /// Leave Role in current jurisdiction
    function leave() external override {
        _GUIDRemove(_msgSender(), _stringToBytes32("member"));
    }

    /// Assign Someone Else to a Role
    function roleAssign(address account, string memory role) external override roleExists(role) {
        //Validate Permissions
        require(
            _msgSender() == account         //Self
            || owner() == _msgSender()      //Owner
            || roleHas(_msgSender(), "admin")    //Admin Role
            , "INVALID_PERMISSIONS");
        //Add
        _roleAssign(account, role);
    }


    /// Remove Someone Else from a Role
    function roleRemove(address account, string memory role) external override roleExists(role) {
        //Validate Permissions
        require(
            _msgSender() == account         //Self
            || owner() == _msgSender()      //Owner
            || balanceOf(_msgSender(), _roleToId("admin")) > 0     //Admin Token
            , "INVALID_PERMISSIONS");
        //Remove
        _roleRemove(account, role);
    }


    /**
    * @dev Hook that is called before any token transfer. This includes minting and burning, as well as batched variants.
    *  - Max of Single Token for each account
    */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (to != address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                //Validate - Max of 1 Per Account
                uint256 id = ids[i];
                require(balanceOf(to, id) == 0, "ALREADY_ASSIGNED_TO_ROLE");
                uint256 amount = amounts[i];
                require(amount == 1, "ONE_TOKEN_MAX");
            }
        }
    }

    //--- Rules

    /// Create New Rule
    function ruleAdd(DataTypes.Rule memory rule, DataTypes.Confirmation memory confirmation) public override returns (uint256) {
        //Validate Caller's Permissions
        require(roleHas(_msgSender(), "admin"), "Admin Only");
        //Add Rule
        uint256 id = _ruleAdd(rule);
        //Set Confirmations
        _confirmationSet(id, confirmation);
        return id;
    }
    
    /// Update Rule
    function ruleUpdate(uint256 id, DataTypes.Rule memory rule) external override {
        //Validate Caller's Permissions
        require(roleHas(_msgSender(), "admin"), "Admin Only");
        //Update Rule
        _ruleUpdate(id, rule);
    }

    /// Get Token URI
    // function tokenURI(uint256 token_id) public view returns (string memory) {
    // function uri(uint256 token_id) public view returns (string memory) {
    //     require(exists(token_id), "NONEXISTENT_TOKEN");
    //     return _tokenURIs[token_id];
    // }

   /**
     * @dev Contract URI
     *  https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() public view override returns (string memory) {
        return _contract_uri;
    }
}