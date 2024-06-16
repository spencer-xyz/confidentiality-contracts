import hre from "hardhat"
import { expect } from "chai"
import { setupAccounts } from "./util/onboard"
import { DataPrivacyFramework } from "../typechain-types"

async function deploy() {
  const [owner, otherAccount] = await setupAccounts()

  const OnChainDatabaseFactory = await hre.ethers.getContractFactory("OnChainDatabase")

  const onChainDatabase = await OnChainDatabaseFactory
    .connect(owner.wallet)
    .deploy({ gasLimit: 15000000 })

  const contract = await onChainDatabase.waitForDeployment()
  
  return { contract, contractAddress: await contract.getAddress(), owner, otherAccount }
}

describe("On-chain Database", function () {
    let deployment: Awaited<ReturnType<typeof deploy>>
  
    before(async function () {
      deployment = await deploy()
    })

    describe("Deployment", function () {
        it("Deployed address should not be undefined", async function () {
          const { contractAddress } = deployment
    
          expect(contractAddress).to.not.equal(undefined)
        })

        it("'op_get_clear_coti_usd_price' should be an allowed operation", async function () {
            const { contract, owner } = deployment
      
            const isAllowed = await contract["isOperationAllowed(address,string)"](owner.wallet, "op_get_clear_coti_usd_price")

            expect(isAllowed).to.equal(true)
        })
    })

    describe("Setting permissions", function () {
        it("'op_get_clear_coti_usd_price' should not be an allowed operation", async function () {
            const { contract, owner } = deployment

            let table = await contract.getConditions(1, 10);

            console.log(table)

            let inputData: DataPrivacyFramework.InputDataStruct = {
                caller: "0x0000000000000000000000000000000000000001",
                operation: "*",
                active: false,
                timestampBefore: "0",
                timestampAfter: "0",
                falseKey: false,
                trueKey: true,
                uintParameter: "0",
                addressParameter: owner.wallet,
                stringParameter: ""
              }

            const tx = await contract.setPermission(inputData)
      
            await tx.wait()

            table = await contract.getConditions(1, 10);

            console.log(table)
      
            const isAllowed = await contract["isOperationAllowed(address,string)"](owner.wallet, "op_get_clear_coti_usd_price")

            expect(isAllowed).to.equal(false)
        })
    })
})