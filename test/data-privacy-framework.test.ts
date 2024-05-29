import hre from "hardhat"
import { expect } from "chai"
import { setupAccounts } from "./util/onboard"
import { DataPrivacyFramework } from "../typechain-types"

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

  describe("Allowing operations", function () {
    before(async function() {
      const { contract } = deployment

      const tx = await contract.addAllowedOperation("*")
      
      await tx.wait()
    })

    it("Should update the allowed operations mapping", async function () {
      const { contract } = deployment

      const isAllowed = await contract.allowedOperations("*")

      expect(isAllowed).to.equal(true)
    })

    it("Should allow all operations for all users", async function () {
      const { contract } = deployment

      const permissionGranted = await contract["getPermission(address,string)"](
        "0xB75fc724A3F951b6D25310d476893b60f4B77C8F", // random address
        "yzfsvycmua" // random string
      )

      expect(permissionGranted).to.equal(true)
    })

    it("Should remove '*' from the allowed operations mapping", async function () {
      const { contract } = deployment

      const tx = await contract.removeAllowedOperation("*")
      
      await tx.wait()

      const isAllowed = await contract.allowedOperations("*")

      expect(isAllowed).to.equal(false)
    })
  })

  describe("Restricting operations", function () {
    before(async function() {
      const { contract } = deployment

      let tx = await contract.addAllowedOperation("*")
      
      await tx.wait()

      tx = await contract.addRestrictedOperation("decrypt")
      
      await tx.wait()
    })

    it("Should add 'decrypt' to the restricted operations mapping", async function () {
      const { contract } = deployment

      const isRestricted = await contract.restrictedOperations("decrypt")

      expect(isRestricted).to.equal(true)
    })

    it("Should not allow any user to decrypt", async function () {
      const { contract } = deployment

      const permissionGranted = await contract["getPermission(address,string)"](
        "0xb818166f592329B1c6122c447E078425AF522e96", // random address
        "decrypt"
      )

      expect(permissionGranted).to.equal(false)
    })

    it("Should allow all other operations for all users", async function () {
      const { contract } = deployment

      const permissionGranted = await contract["getPermission(address,string)"](
        "0x21AF6033aaC0E75eD898a9742183aC06B562bc92", // random address
        "mztsdimwve" // random string
      )

      expect(permissionGranted).to.equal(true)
    })

    it("Should remove 'decrypt' from the restricted operations mapping", async function () {
      const { contract } = deployment

      const tx = await contract.removeRestrictedOperation("decrypt")

      await tx.wait()

      const isRestricted = await contract.restrictedOperations("decrypt")

      expect(isRestricted).to.equal(false)
    })

    after(async function() {
      const { contract } = deployment

      let tx = await contract.removeAllowedOperation("*")
      
      await tx.wait()

      tx = await contract.addAllowedOperation("gt")
      
      await tx.wait()
    })
  })

  describe("Updating default permissions", function () {
    before(async function() {
      const { contract } = deployment

      let tx = await contract.setAddressDefaultPermission(false)
      
      await tx.wait()

      tx = await contract.setOperationDefaultPermission(false)
      
      await tx.wait()
    })

    it("Should set default address permissions to false", async function () {
      const { contract } = deployment

      const defaultPermission = await contract.addressDefaultPermission()

      expect(defaultPermission).to.equal(false)
    })

    it("Should set default operation permissions to false", async function () {
      const { contract } = deployment

      const defaultPermission = await contract.operationDefaultPermission()

      expect(defaultPermission).to.equal(false)
    })
  })

  describe("Setting permissions", function () {
    before(async function() {
      const { contract } = deployment

      const inputData: DataPrivacyFramework.InputDataStruct = {
        caller: "0x70D6c0e13B60964D3A3e372Dd86acA7b75dcc562",
        operation: "gt",
        active: true,
        timestampBefore: "0",
        timestampAfter: "0",
        falseKey: false,
        trueKey: false,
        uintParameter: "0",
        addressParameter: "0x0000000000000000000000000000000000000000",
        stringParameter: ""
      }

      const tx = await contract.setPermission(inputData)
      
      await tx.wait()
    })

    it("Should update the permissions mapping", async function () {
      const { contract } = deployment

      const conditionIdx = await contract.permissions("0x70D6c0e13B60964D3A3e372Dd86acA7b75dcc562", "gt")

      expect(conditionIdx).to.equal(1)
    })

    it("Should update the conditions mapping", async function () {
      const { contract } = deployment

      const condition = await contract.conditions(1)

      expect(condition[0]).to.equal(BigInt(1))
      expect(condition[1]).to.equal("0x70D6c0e13B60964D3A3e372Dd86acA7b75dcc562")
      expect(condition[2]).to.equal("gt")
      expect(condition[3]).to.equal(true)
      expect(condition[4]).to.equal(BigInt(0))
      expect(condition[5]).to.equal(BigInt(0))
      expect(condition[6]).to.equal(false)
      expect(condition[7]).to.equal(false)
      expect(condition[8]).to.equal(BigInt(0))
      expect(condition[9]).to.equal("0x0000000000000000000000000000000000000000")
      expect(condition[10]).to.equal("")
    })

    it("Should update the callerRows mapping", async function () {
      const { contract } = deployment

      const rows = await contract.callerRows("0x70D6c0e13B60964D3A3e372Dd86acA7b75dcc562")

      expect(rows).to.equal(1)
    })

    it("Should allow 0x70D6c0e13B60964D3A3e372Dd86acA7b75dcc562 to compute gt", async function () {
      const { contract } = deployment

      const permissionGranted = await contract["getPermission(address,string)"](
        "0x70D6c0e13B60964D3A3e372Dd86acA7b75dcc562",
        "gt"
      )

      expect(permissionGranted).to.equal(true)
    })

    it("Should not allow other addresses to compute gt", async function () {
      const { contract } = deployment

      const permissionGranted = await contract["getPermission(address,string)"](
        "0x7dc13edFF17da7e6D903573E688A5e06746B85e1", // random address
        "gt"
      )

      expect(permissionGranted).to.equal(false)
    })
  })

  describe("Downloading conditions table", function () {
    before(async function() {
      const { contract } = deployment

      let inputData: DataPrivacyFramework.InputDataStruct = {
        caller: "0x2943dE47d15538a99C25246Ac8628da5D3EC7DA8",
        operation: "ntyxygayec",
        active: true,
        timestampBefore: "0",
        timestampAfter: "0",
        falseKey: false,
        trueKey: false,
        uintParameter: "0",
        addressParameter: "0x0000000000000000000000000000000000000000",
        stringParameter: ""
      }

      let tx = await contract.setPermission(inputData)
      
      await tx.wait()

      inputData = {
        caller: "0x9794eA465f89231eaaB730d87A2083E1ae091Bc6",
        operation: "gkdswnhthi",
        active: true,
        timestampBefore: "0",
        timestampAfter: "0",
        falseKey: false,
        trueKey: false,
        uintParameter: "0",
        addressParameter: "0x0000000000000000000000000000000000000000",
        stringParameter: ""
      }

      tx = await contract.setPermission(inputData)
      
      await tx.wait()

      inputData = {
        caller: "0x377005C508C0a44Ee986fA344A61FDCA453Cb31F",
        operation: "zqotxlwxwz",
        active: true,
        timestampBefore: "0",
        timestampAfter: "0",
        falseKey: false,
        trueKey: false,
        uintParameter: "0",
        addressParameter: "0x0000000000000000000000000000000000000000",
        stringParameter: ""
      }

      tx = await contract.setPermission(inputData)
      
      await tx.wait()

      inputData = {
        caller: "0xe57F3505af334be3081F803F0453B1CBD006829d",
        operation: "pavdshgymp",
        active: true,
        timestampBefore: "0",
        timestampAfter: "0",
        falseKey: false,
        trueKey: false,
        uintParameter: "0",
        addressParameter: "0x0000000000000000000000000000000000000000",
        stringParameter: ""
      }

      tx = await contract.setPermission(inputData)
      
      await tx.wait()
    })

    it("Should return the first two conditions", async function () {
      const { contract } = deployment

      const conditions = await contract.getPermissions(1, 2)

      expect(conditions.length).to.equal(2)
    })

    it("Should return the third and fourth conditions", async function () {
      const { contract } = deployment

      const conditions = await contract.getPermissions(3, 2)

      expect(conditions.length).to.equal(2)
    })

    it("Should return the fifth condition", async function () {
      const { contract } = deployment

      const conditions = await contract.getPermissions(5, 2)

      expect(conditions.length).to.equal(1)
    })
  })
})