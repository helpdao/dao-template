# HelpDAO template ⛑

Aragon DAO Membership template with Agent.

Agent app allows the DAO to manage finances and even interact with DeFi. That would allow the DAO to earn interest in funds that aren't allocated yet, for example

You'll then need to configure it with three tokens:

- $DONOR: All donors get it, regardless of their contribution. This token allows them to be part of the help squad's group chat. As a last-resort measure, they can also replace supervisors
- $VOLUNTEER: Enables volunteers to ask for reimbursements to the DAO
- $SUPERVISOR: Enables supervisors to vote on approving reimbursements from volunteers, and also to vote on including or removing volunteers


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

5) Create a new Help Dao on the devchain (for subsequent executions, the `UNIQUE_ID` constant must be changed to an unused ID):
```
$ npx truffle exec scripts/new-dao.js --network rpc
```

6) Copy the output DAO address into this URL and open it in a web browser:
```
http://localhost:3000/#/<DAO address>
```
