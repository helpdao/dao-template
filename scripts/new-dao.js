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

    const createDaoTxOneReceipt = await helpDaoTemplate.createDaoTxOne()
    console.log(`Tx one gas used: ${createDaoTxOneReceipt.receipt.gasUsed}`)

    const createDaoTxTwoReceipt = await helpDaoTemplate.createDaoTxTwo(uniqueId, INITIAL_SUPERVISOR);
    console.log(`Tx two gas used: ${createDaoTxTwoReceipt.receipt.gasUsed} DAO address: ${createDaoTxTwoReceipt.logs.find(x => x.event === "DeployDao").args.dao} `)
  } catch (error) {
    console.log(error)
  }
  callback()
}
