const deployTemplate = require('@aragon/templates-shared/scripts/deploy-template')

const TEMPLATE_NAME = 'help-dao-template'
const CONTRACT_NAME = 'HelpDaoTemplate'

module.exports = (callback) => {
  deployTemplate(web3, artifacts, TEMPLATE_NAME, CONTRACT_NAME)
    .then(template => {
      console.log("HelpDaoTemplate address: ", template.address)
    })
    .finally(callback)
}
