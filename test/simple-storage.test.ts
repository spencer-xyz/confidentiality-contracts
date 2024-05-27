import hre from "hardhat"
import { expect } from "chai"
import { setupAccounts } from "./util/onboard"

async function deploy() {
  const [owner, otherAccount] = await setupAccounts()

  const SimpleStorage = await hre.ethers.getContractFactory("SimpleStorage")

  const simpleStorage = await SimpleStorage
    .connect(owner.wallet)
    .deploy()

  const contract = await simpleStorage.waitForDeployment()
  
  return { contract, contractAddress: await contract.getAddress(), owner, otherAccount }
}

describe("Simple Storage", function () {
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