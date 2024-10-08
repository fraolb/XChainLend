"use client";

import { useState } from "react";
import Image from "next/image";
import { useActiveWalletChain } from "thirdweb/react";
import { ConnectButton } from "thirdweb/react";
import { sepolia, baseSepolia, avalancheFuji } from "thirdweb/chains";
import { createWallet } from "thirdweb/wallets";
import { client } from "@/app/client";

import Avax from "@public/avax.png";
import Base from "@public/base.png";
import Optimism from "@public/optimism.png";

type BorrowData = {
  borrowed: { asset: string; amount: number; apy: string; chain: string }[];
  collateral: { asset: string; amount: number; apy: string; chain: string }[];
  tokens: { asset: string }[];
};

const Borrow = () => {
  const activeChain = useActiveWalletChain();

  const borrowData: BorrowData = {
    borrowed: [
      { asset: "ETH", amount: 1.5, apy: "3.5%", chain: "Avax" },
      { asset: "DAI", amount: 500, apy: "4.2%", chain: "Base" },
    ],
    collateral: [
      { asset: "ETH", amount: 1.5, apy: "3.5%", chain: "Avax" },
      { asset: "DAI", amount: 500, apy: "4.2%", chain: "Base" },
    ],
    tokens: [{ asset: "USDT" }, { asset: "WBTC" }],
  };

  return (
    <div>
      <section>
        <div className="bg-secondary text-black rounded-xl p-4 shadow-lg mb-6">
          <h2 className="text-xl font-bold mb-2 ml-4">Borrowed Tokens</h2>
          {activeChain?.id == 84532 ? (
            <table className="w-full text-left">
              <thead>
                <tr>
                  <th className="py-2 px-4 border-b border-gray-700">Assets</th>
                  <th className="py-2 px-4 border-b border-gray-700">Amount</th>
                  <th className="py-2 px-4 border-b border-gray-700">APY</th>
                  <th className="py-2 px-4 border-b border-gray-700">Chain</th>
                  <th className="py-2 px-4 border-b border-gray-700">Action</th>
                </tr>
              </thead>
              <tbody>
                {borrowData.borrowed.map((token, index) => (
                  <tr key={index}>
                    <td className="py-2 px-4 border-b border-gray-700">
                      {token.asset}
                    </td>
                    <td className="py-2 px-4 border-b border-gray-700">
                      {token.amount}
                    </td>
                    <td className="py-2 px-4 border-b border-gray-700">
                      {token.apy}
                    </td>
                    <td className="py-2 px-4 border-b border-gray-700">
                      <Image
                        src={
                          token.chain == "Avax"
                            ? Avax
                            : token.chain == "Base"
                            ? Base
                            : Optimism
                        }
                        alt="Chain"
                        className="w-[30px] h-[30px] md:w-[30px] md:h-[30px]"
                        style={{
                          filter: "drop-shadow(0px 0px 24px #a726a9a8)",
                        }}
                      />
                    </td>
                    <td className="py-2 px-4 border-b border-gray-700">
                      <button className="bg-accent text-white px-4 py-1 rounded">
                        Pay Back
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div>
              <div className="text-center">
                Change the network to Base to see your data.
              </div>
              <div className="text-accent flex justify-center">
                <div className="text-accent pt-2 pr-1">
                  <Image
                    src={
                      activeChain?.id == 43113
                        ? Avax
                        : activeChain?.id == 84532
                        ? Base
                        : Optimism
                    }
                    alt="Chain"
                    className="w-[40px] h-[40px] md:w-[40px] md:h-[40px]"
                    style={{
                      filter: "drop-shadow(0px 0px 24px #a726a9a8)",
                    }}
                  />
                </div>
                <ConnectButton
                  client={client}
                  wallets={[
                    createWallet("io.metamask"),
                    createWallet("com.coinbase.wallet"),
                    createWallet("me.rainbow"),
                  ]}
                  theme="light"
                  chains={[baseSepolia, sepolia, avalancheFuji]}
                  appMetadata={{
                    name: "XChain Lend",
                    url: "https://example.com",
                  }}
                />
              </div>
            </div>
          )}
        </div>
        <div className="bg-secondary text-black rounded-xl p-4 shadow-lg mb-6">
          <h2 className="text-xl font-bold mb-2 ml-4">Collateral Tokens</h2>
          {activeChain?.id == 84532 ? (
            <table className="w-full text-left">
              <thead>
                <tr>
                  <th className="py-2 px-4 border-b border-gray-700">Assets</th>
                  <th className="py-2 px-4 border-b border-gray-700">Amount</th>
                  <th className="py-2 px-4 border-b border-gray-700">APY</th>
                  <th className="py-2 px-4 border-b border-gray-700">Chain</th>
                  <th className="py-2 px-4 border-b border-gray-700">Action</th>
                </tr>
              </thead>
              <tbody>
                {borrowData.collateral.map((token, index) => (
                  <tr key={index}>
                    <td className="py-2 px-4 border-b border-gray-700">
                      {token.asset}
                    </td>
                    <td className="py-2 px-4 border-b border-gray-700">
                      {token.amount}
                    </td>
                    <td className="py-2 px-4 border-b border-gray-700">
                      {token.apy}
                    </td>
                    <td className="py-2 px-4 border-b border-gray-700">
                      <Image
                        src={
                          token.chain == "Avax"
                            ? Avax
                            : token.chain == "Base"
                            ? Base
                            : Optimism
                        }
                        alt="Chain"
                        className="w-[30px] h-[30px] md:w-[30px] md:h-[30px]"
                        style={{
                          filter: "drop-shadow(0px 0px 24px #a726a9a8)",
                        }}
                      />
                    </td>
                    <td className="py-2 px-4 border-b border-gray-700">
                      <button className="bg-accent text-white px-4 py-1 rounded">
                        Redeem
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div>
              <div className="text-center">
                Change the network to Base to see your data.
              </div>
            </div>
          )}
        </div>
        <div className="bg-secondary text-black rounded-xl p-4 shadow-lg">
          <h2 className="text-xl font-bold mb-2 ml-4">Tokens</h2>
          <table className="w-full text-left">
            <thead>
              <tr>
                <th className="py-2 px-4 border-b border-gray-700">Assets</th>
                <th className="py-2 px-4 border-b border-gray-700">Action</th>
              </tr>
            </thead>
            <tbody>
              {borrowData.tokens.map((token, index) => (
                <tr key={index}>
                  <td className="py-2 px-4 border-b border-gray-700">
                    {token.asset}
                  </td>
                  <td className="py-2 px-4 border-b border-gray-700">
                    <button className="bg-accent text-white px-4 py-1 rounded">
                      Deposit Collateral
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
};

export default Borrow;
