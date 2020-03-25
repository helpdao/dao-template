const HelpDaoTemplate = artifacts.require("HelpDaoTemplate")

const INITIAL_SUPERVISOR = "0xb4124cEB3451635DAcedd11767f004d8a28c6eE7"
const NETWORK_ARG = "--network"

const network = () => process.argv.includes(NETWORK_ARG) ? process.argv[process.argv.indexOf(NETWORK_ARG) + 1] : "local"

const helpDaoTemplateAddress = () => {
  if (network() === "rinkeby") {
    const Arapp = require("../arapp")
    return Arapp.environments.rinkeby.address
  } else {
    const Arapp = require("../arapp_local")
    return Arapp.environments.devnet.address
  }
}

module.exports = async (callback) => {
  try {
    const uniqueId = new Date().getTime().toString().slice(10) // Must be different for each DAO deployed.
    const helpDaoTemplate = await HelpDaoTemplate.at(helpDaoTemplateAddress())

    // const newTokens = await helpDaoTemplate.newTokens()
    // console.log("Tokens created...")
    // const createDaoReceipt = await helpDaoTemplate.createDao(UNIQUE_ID, INITIAL_SUPERVISOR);

    const createDaoReceipt = await helpDaoTemplate.create(uniqueId, INITIAL_SUPERVISOR);

    console.log(`DAO address: ${createDaoReceipt.logs.find(x => x.event === "DeployDao").args.dao} Gas used: ${createDaoReceipt.receipt.gasUsed}`)
  } catch (error) {
    console.log(error)
  }
  callback()
}
