pragma solidity 0.4.24;

import "@aragon/templates-shared/contracts/BaseTemplate.sol";


contract HelpDaoTemplate is BaseTemplate {

    string constant private ERROR_INITIAL_SUPERVISOR = "MEMBERSHIP_INITIAL_SUPERVISOR";
    string constant private ERROR_ARAGON_ID_NOT_PROVIDED = "MEMBERSHIP_ARAGON_ID_NOT_PROVIDED";

    uint64 constant private SUPPORT_REQUIRED = 50 * 10**16; // 50%
    uint64 constant private MIN_ACCEPTANCE_QUORUM = 20 * 10**16; // 20%
    uint64 constant private VOTE_DURATION = 60 * 60 * 24 * 7; // 1 week

    string constant private SUPERVISORS_TOKEN_NAME = "Supervisors";
    string constant private SUPERVISORS_TOKEN_SYMBOL = "SPV";

    bool constant private TOKEN_TRANSFERABLE = false;
    uint8 constant private TOKEN_DECIMALS = uint8(0);
    uint256 constant private TOKEN_MAX_PER_ACCOUNT = uint256(1);
    uint64 constant private DEFAULT_FINANCE_PERIOD = uint64(30 days);

    constructor(DAOFactory _daoFactory, ENS _ens, MiniMeTokenFactory _miniMeFactory, IFIFSResolvingRegistrar _aragonID)
    BaseTemplate(_daoFactory, _ens, _miniMeFactory, _aragonID)
    public
    {
        _ensureAragonIdIsValid(_aragonID);
        _ensureMiniMeFactoryIsValid(_miniMeFactory);
    }

    function createDao(address _initialSupervisor) public {
        require(_initialSupervisor != address(0), ERROR_INITIAL_SUPERVISOR);

        address[] memory members = new address[](1);
        members[0] = _initialSupervisor;

        MiniMeToken token = _createToken(SUPERVISORS_TOKEN_NAME, SUPERVISORS_TOKEN_SYMBOL, TOKEN_DECIMALS);

        // Create DAO and install apps
        (Kernel dao, ACL acl) = _createDAO();
        Vault agentOrVault = _installDefaultAgentApp(dao);
        Finance finance = _installFinanceApp(dao, agentOrVault, DEFAULT_FINANCE_PERIOD);
        TokenManager tokenManager = _installTokenManagerApp(dao, token, TOKEN_TRANSFERABLE, TOKEN_MAX_PER_ACCOUNT);
        Voting voting = _installVotingApp(dao, token, SUPPORT_REQUIRED, MIN_ACCEPTANCE_QUORUM, VOTE_DURATION);

        // Mint tokens
        _mintTokens(acl, tokenManager, members, 1);

        // Set up permissions
        _createAgentPermissions(acl, Agent(agentOrVault), voting, voting);
        _createVaultPermissions(acl, agentOrVault, finance, voting);
        _createFinancePermissions(acl, finance, voting, voting);
        _createEvmScriptsRegistryPermissions(acl, voting, voting);
        _createCustomVotingPermissions(acl, voting, tokenManager);
        _createCustomTokenManagerPermissions(acl, tokenManager, voting);
        _transferRootPermissionsFromTemplateAndFinalizeDAO(dao, voting);

        _registerID(dao);
    }

    function _createCustomVotingPermissions(ACL _acl, Voting _voting, TokenManager _tokenManager) internal {
        _acl.createPermission(_tokenManager, _voting, _voting.CREATE_VOTES_ROLE(), _voting);
        _acl.createPermission(_voting, _voting, _voting.MODIFY_QUORUM_ROLE(), _voting);
        _acl.createPermission(_voting, _voting, _voting.MODIFY_SUPPORT_ROLE(), _voting);
    }

    function _createCustomTokenManagerPermissions(ACL _acl, TokenManager _tokenManager, Voting _voting) internal {
        _acl.createPermission(_voting, _tokenManager, _tokenManager.BURN_ROLE(), _voting);
        _acl.createPermission(_voting, _tokenManager, _tokenManager.MINT_ROLE(), _voting);
    }

    function _registerID(address _owner) internal {
        require(address(aragonID) != address(0), ERROR_ARAGON_ID_NOT_PROVIDED);
        aragonID.register(keccak256(abi.encodePacked(now, msg.sender)), _owner);
    }
}