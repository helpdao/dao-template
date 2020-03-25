pragma solidity 0.4.24;

import "@aragon/templates-shared/contracts/BaseTemplate.sol";


contract HelpDaoTemplate is BaseTemplate {
    string constant private ERROR_MISSING_MEMBERS = "MEMBERSHIP_MISSING_MEMBERS";
    string constant private ERROR_MISSING_TOKEN_CACHE = "MEMBERSHIP_MISSING_TOKEN_CACHE";
    string constant private ERROR_BAD_VOTE_SETTINGS = "MEMBERSHIP_BAD_VOTE_SETTINGS";

    bool constant private TOKEN_TRANSFERABLE = false;
    uint8 constant private TOKEN_DECIMALS = uint8(0);
    uint256 constant private TOKEN_MAX_PER_ACCOUNT = uint256(1);

    uint64 constant private DEFAULT_FINANCE_PERIOD = uint64(30 days);

    uint64 VOTE_DURATION = 60 * 60 * 24 * 7; // 1 week
    uint64 SUPPORT_REQUIRED = 50 * 10**16; // 50%
    uint64 MIN_ACCEPTANCE_QUORUM = 20 * 10**16; // 20%

    string SUPERVISORS_TOKEN_NAME = "Supervisors";
    string SUPERVISORS_TOKEN_SYMBOL = "SPV";
    string DONORS_TOKEN_NAME = "Donors";
    string DONORS_TOKEN_SYMBOL = "DNS";

    struct StoredContracts {
        address supervisorsToken;
        address donorsToken;
    }

    mapping (address => StoredContracts) internal tokenCache;

    constructor(DAOFactory _daoFactory, ENS _ens, MiniMeTokenFactory _miniMeFactory, IFIFSResolvingRegistrar _aragonID)
        BaseTemplate(_daoFactory, _ens, _miniMeFactory, _aragonID)
        public
    {
        _ensureAragonIdIsValid(_aragonID);
        _ensureMiniMeFactoryIsValid(_miniMeFactory);
    }

    function create(string _id, address _initialSupervisor) external {
        address[] memory members = new address[](1);
        members[0] = _initialSupervisor;
        uint64[3] memory votingSettings = [uint64(SUPPORT_REQUIRED), MIN_ACCEPTANCE_QUORUM, VOTE_DURATION];
        newTokenAndInstance(_id, members, votingSettings, 0, true);
    }

    function createDao(string _id, address _initialSupervisor) external {
        address[] memory members = new address[](1);
        members[0] = _initialSupervisor;
        uint64[3] memory votingSettings = [uint64(SUPPORT_REQUIRED), MIN_ACCEPTANCE_QUORUM, VOTE_DURATION];
        newInstance(_id, members, votingSettings, 0, true);
    }

    function newTokenAndInstance(
        string _id,
        address[] _members,
        uint64[3] _votingSettings, /* supportRequired, minAcceptanceQuorum, voteDuration */
        uint64 _financePeriod,
        bool _useAgentAsVault
    )
        public
    {
        newTokens();
        newInstance(_id, _members, _votingSettings, _financePeriod, _useAgentAsVault);
    }

    function newTokens() public returns (MiniMeToken, MiniMeToken) {
        MiniMeToken supervisorsToken = _createToken(SUPERVISORS_TOKEN_NAME, SUPERVISORS_TOKEN_SYMBOL, TOKEN_DECIMALS);
        MiniMeToken donorsToken = _createToken(DONORS_TOKEN_NAME, DONORS_TOKEN_SYMBOL, TOKEN_DECIMALS);
        _cacheTokens(supervisorsToken, supervisorsToken, msg.sender);
        return (supervisorsToken, supervisorsToken);
    }

    function newInstance(string _id, address[] _members, uint64[3] _votingSettings, uint64 _financePeriod, bool _useAgentAsVault)
        public
    {
        require(_members.length > 0, ERROR_MISSING_MEMBERS);
        require(_votingSettings.length == 3, ERROR_BAD_VOTE_SETTINGS);
        (MiniMeToken supervisorsToken, MiniMeToken donorsToken) = _popTokenCache(msg.sender);

        // Create DAO and install apps
        (Kernel dao, ACL acl) = _createDAO();
        Vault agentOrVault = _useAgentAsVault ? _installDefaultAgentApp(dao) : _installVaultApp(dao);
        Finance finance = _installFinanceApp(dao, agentOrVault, _financePeriod == 0 ? DEFAULT_FINANCE_PERIOD : _financePeriod);
        TokenManager tokenManager = _installTokenManagerApp(dao, supervisorsToken, TOKEN_TRANSFERABLE, TOKEN_MAX_PER_ACCOUNT);
        Voting voting = _installVotingApp(dao, supervisorsToken, _votingSettings[0], _votingSettings[1], _votingSettings[2]);

        // Mint tokens
        _mintTokens(acl, tokenManager, _members, 1);

        // Set up permissions
        if (_useAgentAsVault) {
            _createAgentPermissions(acl, Agent(agentOrVault), voting, voting);
        }
        _createVaultPermissions(acl, agentOrVault, finance, voting);
        _createFinancePermissions(acl, finance, voting, voting);
        _createEvmScriptsRegistryPermissions(acl, voting, voting);
        _createCustomVotingPermissions(acl, voting, tokenManager);
        _createCustomTokenManagerPermissions(acl, tokenManager, voting);
        _transferRootPermissionsFromTemplateAndFinalizeDAO(dao, voting);

        _registerID(_id, dao);
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

    function _cacheTokens(MiniMeToken _supervisorsToken, MiniMeToken _donorsToken, address _owner) internal {
        tokenCache[_owner].supervisorsToken = _supervisorsToken;
        tokenCache[_owner].donorsToken = _donorsToken;
    }

    function _popTokenCache(address _owner) internal returns (MiniMeToken, MiniMeToken) {
        require(tokenCache[_owner].supervisorsToken != address(0), ERROR_MISSING_TOKEN_CACHE);

        MiniMeToken supervisorsToken = MiniMeToken(tokenCache[_owner].supervisorsToken);
        MiniMeToken donorsToken = MiniMeToken(tokenCache[_owner].donorsToken);
        delete tokenCache[_owner];
        return (supervisorsToken, donorsToken);
    }
}
