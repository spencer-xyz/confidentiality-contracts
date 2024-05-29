import hre from "hardhat"
import { expect } from "chai"
import { setupAccounts } from "./util/onboard"

async function deploy() {
  const [owner, otherAccount] = await setupAccounts()

  const DataPrivacyFramework = await hre.ethers.getContractFactory("MockDataPrivacyFramework")

  const dataPrivacyFramework = await DataPrivacyFramework
    .connect(owner.wallet)
    .deploy()

  const contract = await dataPrivacyFramework.waitForDeployment()
  
  return { contract, contractAddress: await contract.getAddress(), owner, otherAccount }
}

describe("Data Privacy Framework", function () {
  let deployment: Awaited<ReturnType<typeof deploy>>

  before(async function () {
    deployment = await deploy()
  })

  describe("Deployment", function () {
    it("Deployed address should not be undefined", async function () {
      const { contractAddress } = deployment

      expect(contractAddress).to.not.equal(undefined)
    })
  })
})