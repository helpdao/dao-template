pragma solidity 0.4.24;

import "@aragon/templates-shared/contracts/BaseTemplate.sol";


contract HelpDaoTemplate is BaseTemplate {
    string constant private ERROR_MISSING_MEMBERS = "MEMBERSHIP_MISSING_MEMBERS";
    string constant private ERROR_MISSING_TOKEN_CACHE = "MEMBERSHIP_MISSING_TOKEN_CACHE";

    uint64 constant private VOTE_DURATION = 60 * 60 * 24 * 7; // 1 week
    uint64 constant private SUPPORT_REQUIRED = 50 * 10**16; // 50%
    uint64 constant private MIN_ACCEPTANCE_QUORUM = 20 * 10**16; // 20%

    string constant private SUPERVISORS_TOKEN_NAME = "Supervisors";
    string constant private SUPERVISORS_TOKEN_SYMBOL = "SPV";
    string constant private DONORS_TOKEN_NAME = "Donors";
    string constant private DONORS_TOKEN_SYMBOL = "DNS";
    string constant private VOLUNTEERS_TOKEN_NAME = "Volunteers";
    string constant private VOLUNTEERS_TOKEN_SYMBOL = "VLN";

    bool constant private TOKEN_TRANSFERABLE = false;
    uint8 constant private TOKEN_DECIMALS = uint8(0);
    uint256 constant private TOKEN_MAX_PER_ACCOUNT = uint256(1);

    uint64 constant private DEFAULT_FINANCE_PERIOD = uint64(30 days);

    struct StoredContracts {
        address supervisorsToken;
        address donorsToken;
        address volunteersToken;
    }

    mapping (address => StoredContracts) internal tokenCache;

    constructor(DAOFactory _daoFactory, ENS _ens, MiniMeTokenFactory _miniMeFactory, IFIFSResolvingRegistrar _aragonID)
        BaseTemplate(_daoFactory, _ens, _miniMeFactory, _aragonID)
        public
    {
        _ensureAragonIdIsValid(_aragonID);
        _ensureMiniMeFactoryIsValid(_miniMeFactory);
    }

    function createDaoTxOne()
        public
        returns (MiniMeToken, MiniMeToken, MiniMeToken)
    {
        MiniMeToken supervisorsToken = _createToken(SUPERVISORS_TOKEN_NAME, SUPERVISORS_TOKEN_SYMBOL, TOKEN_DECIMALS);
        MiniMeToken donorsToken = _createToken(DONORS_TOKEN_NAME, DONORS_TOKEN_SYMBOL, TOKEN_DECIMALS);
        MiniMeToken volunteersToken = _createToken(VOLUNTEERS_TOKEN_NAME, VOLUNTEERS_TOKEN_SYMBOL, TOKEN_DECIMALS);
        _cacheTokens(supervisorsToken, donorsToken, volunteersToken, msg.sender);
        return (supervisorsToken, donorsToken, volunteersToken);
    }

    function createDaoTxTwo(string _id, address _initialSupervisor)
        public
    {
        address[] memory members = new address[](1);
        members[0] = _initialSupervisor;

        require(members.length > 0, ERROR_MISSING_MEMBERS);
        (MiniMeToken supervisorsToken, MiniMeToken donorsToken, MiniMeToken volunteersToken) = _popTokenCache(msg.sender);

        // Create DAO and install apps
        (Kernel dao, ACL acl) = _createDAO();
        Vault agentOrVault = _installDefaultAgentApp(dao);
        Finance finance = _installFinanceApp(dao, agentOrVault, DEFAULT_FINANCE_PERIOD);
        TokenManager supervisorTokenManager = _installTokenManagerApp(dao, supervisorsToken, TOKEN_TRANSFERABLE, TOKEN_MAX_PER_ACCOUNT);
        Voting supervisorVoting = _installVotingApp(dao, supervisorsToken, SUPPORT_REQUIRED, MIN_ACCEPTANCE_QUORUM, VOTE_DURATION);
        TokenManager donorsTokenManager = _installTokenManagerApp(dao, donorsToken, TOKEN_TRANSFERABLE, TOKEN_MAX_PER_ACCOUNT);
        Voting donorsVoting = _installVotingApp(dao, donorsToken, SUPPORT_REQUIRED, MIN_ACCEPTANCE_QUORUM, VOTE_DURATION);
        TokenManager volunteersTokenManager = _installTokenManagerApp(dao, volunteersToken, TOKEN_TRANSFERABLE, TOKEN_MAX_PER_ACCOUNT);

        // Mint tokens
        _mintTokens(acl, supervisorTokenManager, members, 1);

        // Set up permissions
//    _createEvmScriptsRegistryPermissions(acl, supervisorVoting, supervisorVoting); ???
        _createFinancePermissions(acl, finance, supervisorVoting, supervisorVoting);
        _createFinanceCreatePaymentsPermission(acl, finance, supervisorVoting, supervisorVoting);
        _createAgentPermissions(acl, Agent(agentOrVault), supervisorVoting, supervisorVoting);
        _createVaultPermissions(acl, agentOrVault, finance, supervisorVoting);
        _createCustomTokenManagerPermissions(acl, supervisorTokenManager, donorsVoting);
        _createCustomTokenManagerPermissions(acl, donorsTokenManager, supervisorVoting);
        _createCustomVotingPermissions(acl, supervisorVoting, volunteersTokenManager);

        _transferRootPermissionsFromTemplateAndFinalizeDAO(dao, donorsVoting);

        _registerID(_id, dao);
    }

    function _createCustomVotingPermissions(ACL _acl, Voting _voting, TokenManager _tokenManager) internal {
        _acl.createPermission(_tokenManager, _voting, _voting.CREATE_VOTES_ROLE(), _voting);
    }

    function _createCustomTokenManagerPermissions(ACL _acl, TokenManager _tokenManager, Voting _voting) internal {
        _acl.createPermission(_voting, _tokenManager, _tokenManager.BURN_ROLE(), _voting);
        _acl.createPermission(_voting, _tokenManager, _tokenManager.MINT_ROLE(), _voting);
    }

    function _cacheTokens(MiniMeToken _supervisorsToken, MiniMeToken _donorsToken, MiniMeToken _volunteersToken, address _owner) internal {
        tokenCache[_owner].supervisorsToken = _supervisorsToken;
        tokenCache[_owner].donorsToken = _donorsToken;
        tokenCache[_owner].volunteersToken = _volunteersToken;
    }

    function _popTokenCache(address _owner) internal returns (MiniMeToken, MiniMeToken, MiniMeToken) {
        require(tokenCache[_owner].supervisorsToken != address(0), ERROR_MISSING_TOKEN_CACHE);

        MiniMeToken supervisorsToken = MiniMeToken(tokenCache[_owner].supervisorsToken);
        MiniMeToken donorsToken = MiniMeToken(tokenCache[_owner].donorsToken);
        MiniMeToken volunteersToken = MiniMeToken(tokenCache[_owner].volunteersToken);
        delete tokenCache[_owner];

        return (supervisorsToken, donorsToken, volunteersToken);
    }
}
