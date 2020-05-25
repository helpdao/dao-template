# HelpDAO template ⛑

Aragon DAO Membership template with Agent.

Agent app allows the DAO to manage finances and even interact with DeFi. That would allow the DAO to earn interest in 
funds that aren't allocated yet, for example

It will be configured with one token:

- $SUPERVISOR: Enables supervisors to vote on approving reimbursements from volunteers, and also to vote on adding or 
removing volunteer permissions to create votes for claiming reimbursement.

Rinkeby deployment - 0x7dc048743dc198184fb73cfcd3dbca71ac60e7c4

Mainnet deployment - 0xbd060d1701ade4197b17b2ed5732a58353c4103c

## Local deployment

To deploy the DAO to a local `aragon devchain`:

1) Install dependencies:
```
$ npm install
```

2) In a separate console run Aragon Devchain:
```
$ npx aragon devchain
```

3) In a separate console run the Aragon Client:
```
$ npx aragon start
```

4) Deploy the template with:
```
$ npm run deploy:rpc
```

5) Create a new Help Dao on the devchain:
```
$ npx truffle exec scripts/new-dao.js --network rpc
```

6) Copy the output DAO address into this URL and open it in a web browser:
```
http://localhost:3000/#/<DAO address>
```
