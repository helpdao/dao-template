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
    const helpDaoTemplate = await HelpDaoTemplate.at(helpDaoTemplateAddress())

    const createDaoReceipt = await helpDaoTemplate.createDao(INITIAL_SUPERVISOR);
    console.log(`DAO address: ${createDaoReceipt.logs.find(x => x.event === "DeployDao").args.dao} Gas used: ${createDaoReceipt.receipt.gasUsed} `)

  } catch (error) {
    console.log(error)
  }
  callback()
}
