const { expect } = require("chai");
const { network, ethers } = require("hardhat");
const { BigNumber, utils }  = require("ethers");
const { writeFile } = require('fs');

describe("Liquidation", function () {
  it("0x59 - WETH_USDT - full USDT", async function () {
    await network.provider.request({
        method: "hardhat_reset",
        params: [{
          forking: {
            jsonRpcUrl: process.env.ALCHE_API,
            blockNumber: 12489619,
          }
        }]
      });
    
    const gasPrice = 0;

    const accounts = await ethers.getSigners();
    const liquidator = accounts[0].address;

    const beforeLiquidationBalance = BigNumber.from(await hre.network.provider.request({
        method: "eth_getBalance",
        params: [liquidator],
    }));

    const LiquidationOperator = await ethers.getContractFactory("LiquidationOperator");
    const liquidationOperator = await LiquidationOperator.deploy(overrides = {gasPrice: gasPrice});
    await liquidationOperator.deployed();

    await liquidationOperator.setLiquidationTarget("0x59CE4a2AC5bC3f5F225439B2993b86B42f6d3e9F");
    const liquidationTx = await liquidationOperator.operate(
      "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", 
      "0xdAC17F958D2ee523a2206206994597C13D831ec7",
      2916378221684,
      overrides = {gasPrice: gasPrice}
    );
    const liquidationReceipt = await liquidationTx.wait();

    const liquidationEvents = liquidationReceipt.logs.filter(
        v => v && v.topics && v.address === '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9' && Array.isArray(v.topics) && 
        v.topics.length > 3 && v.topics[0] === '0xe413a321e8681d831f4dbccbca790d2952b56f977908e45be37335533e005286')

    const expectedLiquidationEvents = liquidationReceipt.logs.filter(v => v.topics[3] === '0x00000000000000000000000059ce4a2ac5bc3f5f225439b2993b86b42f6d3e9f');

    expect(expectedLiquidationEvents.length, "no expected liquidation").to.be.above(0);
    expect(liquidationEvents.length, "unexpected liquidation").to.be.equal(expectedLiquidationEvents.length);

    const afterLiquidationBalance = BigNumber.from(await hre.network.provider.request({
        method: "eth_getBalance",
        params: [liquidator],
    }));

    const profit = afterLiquidationBalance.sub(beforeLiquidationBalance);
    console.log("Profit", utils.formatEther(profit), "ETH");

    expect(profit.gt(BigNumber.from(0)), "not profitable").to.be.true;
    writeFile('profit.txt', String(utils.formatEther(profit)), function (err) {console.log("failed to write profit.txt: %s", err)});
  });
  
  it("0x59 - WBTC_USDT - 50000", async function () {
    await network.provider.request({
        method: "hardhat_reset",
        params: [{
          forking: {
            jsonRpcUrl: process.env.ALCHE_API,
            blockNumber: 12489619,
          }
        }]
      });
    
    const gasPrice = 0;

    const accounts = await ethers.getSigners();
    const liquidator = accounts[0].address;

    const beforeLiquidationBalance = BigNumber.from(await hre.network.provider.request({
        method: "eth_getBalance",
        params: [liquidator],
    }));

    const LiquidationOperator = await ethers.getContractFactory("LiquidationOperator");
    const liquidationOperator = await LiquidationOperator.deploy(overrides = {gasPrice: gasPrice});
    await liquidationOperator.deployed();

    await liquidationOperator.setLiquidationTarget("0x59CE4a2AC5bC3f5F225439B2993b86B42f6d3e9F");
    const liquidationTx = await liquidationOperator.operate(
      "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", 
      "0xdAC17F958D2ee523a2206206994597C13D831ec7",
      50000,
      overrides = {gasPrice: gasPrice}
    );
    const liquidationReceipt = await liquidationTx.wait();

    const liquidationEvents = liquidationReceipt.logs.filter(
        v => v && v.topics && v.address === '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9' && Array.isArray(v.topics) && 
        v.topics.length > 3 && v.topics[0] === '0xe413a321e8681d831f4dbccbca790d2952b56f977908e45be37335533e005286')

    const expectedLiquidationEvents = liquidationReceipt.logs.filter(v => v.topics[3] === '0x00000000000000000000000059ce4a2ac5bc3f5f225439b2993b86b42f6d3e9f');

    expect(expectedLiquidationEvents.length, "no expected liquidation").to.be.above(0);
    expect(liquidationEvents.length, "unexpected liquidation").to.be.equal(expectedLiquidationEvents.length);

    const afterLiquidationBalance = BigNumber.from(await hre.network.provider.request({
        method: "eth_getBalance",
        params: [liquidator],
    }));

    const profit = afterLiquidationBalance.sub(beforeLiquidationBalance);
    console.log("Profit", utils.formatEther(profit), "ETH");

    expect(profit.gt(BigNumber.from(0)), "not profitable").to.be.true;
    writeFile('profit.txt', String(utils.formatEther(profit)), function (err) {console.log("failed to write profit.txt: %s", err)});
  });
  
  it("0x59 - WBTC_USDT - 100000", async function () {
    await network.provider.request({
        method: "hardhat_reset",
        params: [{
          forking: {
            jsonRpcUrl: process.env.ALCHE_API,
            blockNumber: 12489619,
          }
        }]
      });
    
    const gasPrice = 0;

    const accounts = await ethers.getSigners();
    const liquidator = accounts[0].address;

    const beforeLiquidationBalance = BigNumber.from(await hre.network.provider.request({
        method: "eth_getBalance",
        params: [liquidator],
    }));

    const LiquidationOperator = await ethers.getContractFactory("LiquidationOperator");
    const liquidationOperator = await LiquidationOperator.deploy(overrides = {gasPrice: gasPrice});
    await liquidationOperator.deployed();

    await liquidationOperator.setLiquidationTarget("0x59CE4a2AC5bC3f5F225439B2993b86B42f6d3e9F");
    const liquidationTx = await liquidationOperator.operate(
      "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", 
      "0xdAC17F958D2ee523a2206206994597C13D831ec7",
      100000,
      overrides = {gasPrice: gasPrice}
    );
    const liquidationReceipt = await liquidationTx.wait();

    const liquidationEvents = liquidationReceipt.logs.filter(
        v => v && v.topics && v.address === '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9' && Array.isArray(v.topics) && 
        v.topics.length > 3 && v.topics[0] === '0xe413a321e8681d831f4dbccbca790d2952b56f977908e45be37335533e005286')

    const expectedLiquidationEvents = liquidationReceipt.logs.filter(v => v.topics[3] === '0x00000000000000000000000059ce4a2ac5bc3f5f225439b2993b86b42f6d3e9f');

    expect(expectedLiquidationEvents.length, "no expected liquidation").to.be.above(0);
    expect(liquidationEvents.length, "unexpected liquidation").to.be.equal(expectedLiquidationEvents.length);

    const afterLiquidationBalance = BigNumber.from(await hre.network.provider.request({
        method: "eth_getBalance",
        params: [liquidator],
    }));

    const profit = afterLiquidationBalance.sub(beforeLiquidationBalance);
    console.log("Profit", utils.formatEther(profit), "ETH");

    expect(profit.gt(BigNumber.from(0)), "not profitable").to.be.true;
    writeFile('profit.txt', String(utils.formatEther(profit)), function (err) {console.log("failed to write profit.txt: %s", err)});
  });

  it("0x59 - WBTC_USDT - 150000", async function () {
    await network.provider.request({
        method: "hardhat_reset",
        params: [{
          forking: {
            jsonRpcUrl: process.env.ALCHE_API,
            blockNumber: 12489619,
          }
        }]
      });
    
    const gasPrice = 0;

    const accounts = await ethers.getSigners();
    const liquidator = accounts[0].address;

    const beforeLiquidationBalance = BigNumber.from(await hre.network.provider.request({
        method: "eth_getBalance",
        params: [liquidator],
    }));

    const LiquidationOperator = await ethers.getContractFactory("LiquidationOperator");
    const liquidationOperator = await LiquidationOperator.deploy(overrides = {gasPrice: gasPrice});
    await liquidationOperator.deployed();

    await liquidationOperator.setLiquidationTarget("0x59CE4a2AC5bC3f5F225439B2993b86B42f6d3e9F");
    const liquidationTx = await liquidationOperator.operate(
      "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", 
      "0xdAC17F958D2ee523a2206206994597C13D831ec7",
      150000,
      overrides = {gasPrice: gasPrice}
    );
    const liquidationReceipt = await liquidationTx.wait();

    const liquidationEvents = liquidationReceipt.logs.filter(
        v => v && v.topics && v.address === '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9' && Array.isArray(v.topics) && 
        v.topics.length > 3 && v.topics[0] === '0xe413a321e8681d831f4dbccbca790d2952b56f977908e45be37335533e005286')

    const expectedLiquidationEvents = liquidationReceipt.logs.filter(v => v.topics[3] === '0x00000000000000000000000059ce4a2ac5bc3f5f225439b2993b86b42f6d3e9f');

    expect(expectedLiquidationEvents.length, "no expected liquidation").to.be.above(0);
    expect(liquidationEvents.length, "unexpected liquidation").to.be.equal(expectedLiquidationEvents.length);

    const afterLiquidationBalance = BigNumber.from(await hre.network.provider.request({
        method: "eth_getBalance",
        params: [liquidator],
    }));

    const profit = afterLiquidationBalance.sub(beforeLiquidationBalance);
    console.log("Profit", utils.formatEther(profit), "ETH");

    expect(profit.gt(BigNumber.from(0)), "not profitable").to.be.true;
    writeFile('profit.txt', String(utils.formatEther(profit)), function (err) {console.log("failed to write profit.txt: %s", err)});
  });
});
