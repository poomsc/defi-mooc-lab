const { expect } = require("chai");
const { network, ethers } = require("hardhat");
const { BigNumber, utils } = require("ethers");
// const { writeFile } = require('fs');

describe("Liquidation", function () {
  it("0x59 - WETH_USDT - full USDT", async function () {
    await network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            jsonRpcUrl: process.env.ALCHE_API,
            blockNumber: 12489619,
          },
        },
      ],
    });
    console.log("block :", (await ethers.provider.getBlock("latest")).number);

    const gasPrice = 0;

    const accounts = await ethers.getSigners();
    const liquidator = accounts[0].address;

    const beforeLiquidationBalance = BigNumber.from(
      await hre.network.provider.request({
        method: "eth_getBalance",
        params: [liquidator],
      })
    );

    const LiquidationOperator = await ethers.getContractFactory(
      "LiquidationOperator"
    );
    const liquidationOperator = await LiquidationOperator.deploy(
      (overrides = { gasPrice: gasPrice })
    );
    await liquidationOperator.deployed();

    const liquidationTx = await liquidationOperator.operate(
      "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
      "0xdAC17F958D2ee523a2206206994597C13D831ec7",
      0,
      2916378221684,
      "0x59CE4a2AC5bC3f5F225439B2993b86B42f6d3e9F",
      (overrides = { gasPrice: gasPrice })
    );
    const liquidationReceipt = await liquidationTx.wait();

    const liquidationEvents = liquidationReceipt.logs.filter(
      (v) =>
        v &&
        v.topics &&
        v.address === "0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9" &&
        Array.isArray(v.topics) &&
        v.topics.length > 3 &&
        v.topics[0] ===
          "0xe413a321e8681d831f4dbccbca790d2952b56f977908e45be37335533e005286"
    );

    const expectedLiquidationEvents = liquidationReceipt.logs.filter(
      (v) =>
        v.topics[3] ===
        "0x00000000000000000000000059ce4a2ac5bc3f5f225439b2993b86b42f6d3e9f"
    );

    expect(
      expectedLiquidationEvents.length,
      "no expected liquidation"
    ).to.be.above(0);
    expect(liquidationEvents.length, "unexpected liquidation").to.be.equal(
      expectedLiquidationEvents.length
    );

    const afterLiquidationBalance = BigNumber.from(
      await hre.network.provider.request({
        method: "eth_getBalance",
        params: [liquidator],
      })
    );

    const profit = afterLiquidationBalance.sub(beforeLiquidationBalance);
    console.log("Profit", utils.formatEther(profit), "ETH");

    expect(profit.gt(BigNumber.from(0)), "not profitable").to.be.true;
    // writeFile('profit.txt', String(utils.formatEther(profit)), function (err) {console.log("failed to write profit.txt: %s", err)});
  });

  it("0x59 - WBTC_USDT - 2000 USDT", async function () {
    await network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            jsonRpcUrl: process.env.ALCHE_API,
            blockNumber: 12489619,
          },
        },
      ],
    });

    const gasPrice = 0;

    const accounts = await ethers.getSigners();
    const liquidator = accounts[0].address;

    const beforeLiquidationBalance = BigNumber.from(
      await hre.network.provider.request({
        method: "eth_getBalance",
        params: [liquidator],
      })
    );

    const LiquidationOperator = await ethers.getContractFactory(
      "LiquidationOperator"
    );
    const liquidationOperator = await LiquidationOperator.deploy(
      (overrides = { gasPrice: gasPrice })
    );
    await liquidationOperator.deployed();

    const liquidationTx = await liquidationOperator.operate(
      "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599",
      "0xdAC17F958D2ee523a2206206994597C13D831ec7",
      0,
      2000 * 1e6,
      "0x59CE4a2AC5bC3f5F225439B2993b86B42f6d3e9F",
      (overrides = { gasPrice: gasPrice })
    );
    const liquidationReceipt = await liquidationTx.wait();

    const liquidationEvents = liquidationReceipt.logs.filter(
      (v) =>
        v &&
        v.topics &&
        v.address === "0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9" &&
        Array.isArray(v.topics) &&
        v.topics.length > 3 &&
        v.topics[0] ===
          "0xe413a321e8681d831f4dbccbca790d2952b56f977908e45be37335533e005286"
    );

    const expectedLiquidationEvents = liquidationReceipt.logs.filter(
      (v) =>
        v.topics[3] ===
        "0x00000000000000000000000059ce4a2ac5bc3f5f225439b2993b86b42f6d3e9f"
    );

    expect(
      expectedLiquidationEvents.length,
      "no expected liquidation"
    ).to.be.above(0);
    expect(liquidationEvents.length, "unexpected liquidation").to.be.equal(
      expectedLiquidationEvents.length
    );

    const afterLiquidationBalance = BigNumber.from(
      await hre.network.provider.request({
        method: "eth_getBalance",
        params: [liquidator],
      })
    );

    const profit = afterLiquidationBalance.sub(beforeLiquidationBalance);
    console.log("Profit", utils.formatEther(profit), "ETH");

    expect(profit.gt(BigNumber.from(0)), "not profitable").to.be.true;
    // writeFile('profit.txt', String(utils.formatEther(profit)), function (err) {console.log("failed to write profit.txt: %s", err)});
  });

  it("0x59 - WBTC_USDT - 5000 USDT", async function () {
    await network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            jsonRpcUrl: process.env.ALCHE_API,
            blockNumber: 12489619,
          },
        },
      ],
    });

    const gasPrice = 0;

    const accounts = await ethers.getSigners();
    const liquidator = accounts[0].address;

    const beforeLiquidationBalance = BigNumber.from(
      await hre.network.provider.request({
        method: "eth_getBalance",
        params: [liquidator],
      })
    );

    const LiquidationOperator = await ethers.getContractFactory(
      "LiquidationOperator"
    );
    const liquidationOperator = await LiquidationOperator.deploy(
      (overrides = { gasPrice: gasPrice })
    );
    await liquidationOperator.deployed();

    const liquidationTx = await liquidationOperator.operate(
      "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599",
      "0xdAC17F958D2ee523a2206206994597C13D831ec7",
      0,
      5000 * 1e6,
      "0x59CE4a2AC5bC3f5F225439B2993b86B42f6d3e9F",
      (overrides = { gasPrice: gasPrice })
    );
    const liquidationReceipt = await liquidationTx.wait();

    const liquidationEvents = liquidationReceipt.logs.filter(
      (v) =>
        v &&
        v.topics &&
        v.address === "0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9" &&
        Array.isArray(v.topics) &&
        v.topics.length > 3 &&
        v.topics[0] ===
          "0xe413a321e8681d831f4dbccbca790d2952b56f977908e45be37335533e005286"
    );

    const expectedLiquidationEvents = liquidationReceipt.logs.filter(
      (v) =>
        v.topics[3] ===
        "0x00000000000000000000000059ce4a2ac5bc3f5f225439b2993b86b42f6d3e9f"
    );

    expect(
      expectedLiquidationEvents.length,
      "no expected liquidation"
    ).to.be.above(0);
    expect(liquidationEvents.length, "unexpected liquidation").to.be.equal(
      expectedLiquidationEvents.length
    );

    const afterLiquidationBalance = BigNumber.from(
      await hre.network.provider.request({
        method: "eth_getBalance",
        params: [liquidator],
      })
    );

    const profit = afterLiquidationBalance.sub(beforeLiquidationBalance);
    console.log("Profit", utils.formatEther(profit), "ETH");

    expect(profit.gt(BigNumber.from(0)), "not profitable").to.be.true;
    // writeFile('profit.txt', String(utils.formatEther(profit)), function (err) {console.log("failed to write profit.txt: %s", err)});
  });

  it("0x59 - WBTC_USDT - 10000 USDT", async function () {
    await network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            jsonRpcUrl: process.env.ALCHE_API,
            blockNumber: 12489619,
          },
        },
      ],
    });

    const gasPrice = 0;

    const accounts = await ethers.getSigners();
    const liquidator = accounts[0].address;

    const beforeLiquidationBalance = BigNumber.from(
      await hre.network.provider.request({
        method: "eth_getBalance",
        params: [liquidator],
      })
    );

    const LiquidationOperator = await ethers.getContractFactory(
      "LiquidationOperator"
    );
    const liquidationOperator = await LiquidationOperator.deploy(
      (overrides = { gasPrice: gasPrice })
    );
    await liquidationOperator.deployed();

    const liquidationTx = await liquidationOperator.operate(
      "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599",
      "0xdAC17F958D2ee523a2206206994597C13D831ec7",
      0,
      10000 * 1e6,
      "0x59CE4a2AC5bC3f5F225439B2993b86B42f6d3e9F",
      (overrides = { gasPrice: gasPrice })
    );
    const liquidationReceipt = await liquidationTx.wait();

    const liquidationEvents = liquidationReceipt.logs.filter(
      (v) =>
        v &&
        v.topics &&
        v.address === "0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9" &&
        Array.isArray(v.topics) &&
        v.topics.length > 3 &&
        v.topics[0] ===
          "0xe413a321e8681d831f4dbccbca790d2952b56f977908e45be37335533e005286"
    );

    const expectedLiquidationEvents = liquidationReceipt.logs.filter(
      (v) =>
        v.topics[3] ===
        "0x00000000000000000000000059ce4a2ac5bc3f5f225439b2993b86b42f6d3e9f"
    );

    expect(
      expectedLiquidationEvents.length,
      "no expected liquidation"
    ).to.be.above(0);
    expect(liquidationEvents.length, "unexpected liquidation").to.be.equal(
      expectedLiquidationEvents.length
    );

    const afterLiquidationBalance = BigNumber.from(
      await hre.network.provider.request({
        method: "eth_getBalance",
        params: [liquidator],
      })
    );

    const profit = afterLiquidationBalance.sub(beforeLiquidationBalance);
    console.log("Profit", utils.formatEther(profit), "ETH");

    expect(profit.gt(BigNumber.from(0)), "not profitable").to.be.true;
    // writeFile('profit.txt', String(utils.formatEther(profit)), function (err) {console.log("failed to write profit.txt: %s", err)});
  });

  it.only("0x12 - DAI_WETH - full DAI", async function () {
    await network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            jsonRpcUrl: process.env.ALCHE_API,
            // jsonRpcUrl: "https://mainnet.infura.io/v3/2f08be40327c46a6b9a38090a2e5b26b",
            blockNumber: 12462000 - 1,
          },
        },
      ],
    });
    console.log("block :", (await ethers.provider.getBlock("latest")).number);

    const gasPrice = 0;

    const accounts = await ethers.getSigners();
    const liquidator = accounts[0].address;

    const beforeLiquidationBalance = BigNumber.from(
      await hre.network.provider.request({
        method: "eth_getBalance",
        params: [liquidator],
      })
    );

    const LiquidationOperator = await ethers.getContractFactory(
      "LiquidationOperator"
    );
    const liquidationOperator = await LiquidationOperator.deploy(
      (overrides = { gasPrice: gasPrice })
    );
    await liquidationOperator.deployed();
    // await liquidationOperator.getReserve_DAI_WETH()

    const liquidationTx = await liquidationOperator.operate(
      "0x6B175474E89094C44Da98b954EedeAC495271d0F",
      "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
      "4472611173945413619164067",
      0,
      "0x12696ad7EA03474ED5D2D2909C52f3d1d997c81e",
      (overrides = { gasPrice: gasPrice })
    );
    const liquidationReceipt = await liquidationTx.wait();

    const liquidationEvents = liquidationReceipt.logs.filter(
      (v) =>
        v &&
        v.topics &&
        v.address === "0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9" &&
        Array.isArray(v.topics) &&
        v.topics.length > 3 &&
        v.topics[0] ===
          "0xe413a321e8681d831f4dbccbca790d2952b56f977908e45be37335533e005286"
    );

    const expectedLiquidationEvents = liquidationReceipt.logs.filter(
      (v) =>
        v.topics[3] ===
        "0x00000000000000000000000012696ad7EA03474ED5D2D2909C52f3d1d997c81e"
    );

    expect(
      expectedLiquidationEvents.length,
      "no expected liquidation"
    ).to.be.above(0);
    expect(liquidationEvents.length, "unexpected liquidation").to.be.equal(
      expectedLiquidationEvents.length
    );

    const afterLiquidationBalance = BigNumber.from(
      await hre.network.provider.request({
        method: "eth_getBalance",
        params: [liquidator],
      })
    );

    const profit = afterLiquidationBalance.sub(beforeLiquidationBalance);
    console.log("Profit", utils.formatEther(profit), "ETH");

    expect(profit.gt(BigNumber.from(0)), "not profitable").to.be.true;
    // writeFile('profit.txt', String(utils.formatEther(profit)), function (err) {console.log("failed to write profit.txt: %s", err)});
  });
});
