"use client";

import { useState } from "react";
import Image from "next/image";
import { useActiveWalletChain } from "thirdweb/react";
import { ConnectButton } from "thirdweb/react";
import { optimismSepolia, baseSepolia, avalancheFuji } from "thirdweb/chains";
import { createWallet } from "thirdweb/wallets";
import { client } from "@/app/client";

import Lend from "./Lend";
import Borrow from "./Borrow";

import Avax from "@public/avax.png";
import Base from "@public/base.png";
import Optimism from "@public/optimism.png";

import BorrowModal from "./modals/BorrowModal";
import WithdrawModal from "./modals/WithdrawModal";
import DepositModal from "./modals/DepositModal";

type BorrowData = {
  borrowed: { asset: string; amount: number; apy: string; chain: string }[];
  collateral: { asset: string; amount: number; chain: string }[];
  tokens: { asset: string; chains: string[] }[];
};

const LendBorrow = () => {
  const activeChain = useActiveWalletChain();
  const [selectedOption, setSelectedOption] = useState<"borrow" | "lend">(
    "borrow"
  );

  // states for borrow
  const [isBorrowModalOpen, setIsBorrowModalOpen] = useState(false);
  const openBorrowModal = () => setIsBorrowModalOpen(true);
  const closeBorrowModal = () => setIsBorrowModalOpen(false);
  const [isDepositModalOpen, setIsDepositModalOpen] = useState(false);
  const openDepositModal = () => setIsDepositModalOpen(true);
  const closeDepositModal = () => setIsDepositModalOpen(false);
  const [isWithdrawModalOpen, setIsWithdrawModalOpen] = useState(false);
  const openWithdrawModal = () => setIsWithdrawModalOpen(true);
  const closeWithdrawModal = () => setIsWithdrawModalOpen(false);

  // states for lend
  const [isSupplyModalOpen, setIsSupplyModalOpen] = useState(false);
  const openSupplyModal = () => setIsSupplyModalOpen(true);
  const closeSupplyModal = () => setIsSupplyModalOpen(false);
  const [isWithdrawSupplyModalOpen, setIsWithdrawSupplyModalOpen] =
    useState(false);
  const openWithdrawSupplyModal = () => setIsWithdrawSupplyModalOpen(true);
  const closeWithdrawSupplyModal = () => setIsWithdrawSupplyModalOpen(false);

  const borrowData: BorrowData = {
    borrowed: [
      { asset: "USDC", amount: 5, apy: "4.2%", chain: "Base" },
      // { asset: "CCIP-BnM", amount: 1, apy: "5.0%", chain: "Avax" },
      { asset: "CCIP-BnM", amount: 0.002, apy: "5.0%", chain: "Base" },
    ],
    collateral: [
      { asset: "CCIP-BnM", amount: 2.5, chain: "Avax" },
      { asset: "CCIP-BnM", amount: 0.002, chain: "Optimism" },
    ],
    tokens: [
      { asset: "CCIP-BnM", chains: ["Base", "Optmism", "Avax"] },
      { asset: "USDC", chains: ["Base", "Optmism", "Avax"] },
      { asset: "GHO", chains: ["Base", "Avax"] },
    ],
  };

  const renderBorrowSection = () => (
    <section>
      <div className="bg-secondary text-black rounded-xl p-4 shadow-lg mb-6">
        <BorrowModal isOpen={isBorrowModalOpen} onClose={closeBorrowModal} />
        <WithdrawModal
          isOpen={isWithdrawModalOpen}
          onClose={closeWithdrawModal}
        />
        <DepositModal isOpen={isDepositModalOpen} onClose={closeDepositModal} />

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
                <tr key={index} className="border-b border-gray-700">
                  <td className="py-2 px-4 ">{token.asset}</td>
                  <td className="py-2 px-4 ">{token.amount}</td>
                  <td className="py-2 px-4 ">{token.apy}</td>
                  <td className="py-2 px-4">
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
                    />
                  </td>
                  <td className="py-2 px-4 ">
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
                chains={[baseSepolia, optimismSepolia, avalancheFuji]}
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
                <th className="py-2 px-4 border-b border-gray-700">Chain</th>
                <th className="py-2 px-4 border-b border-gray-700">Action</th>
              </tr>
            </thead>
            <tbody>
              {borrowData.collateral.map((token, index) => (
                <tr key={index} className="border-b border-gray-700">
                  <td className="py-2 px-4 ">{token.asset}</td>
                  <td className="py-2 px-4 ">{token.amount}</td>
                  <td className="py-2 px-4 ">
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
                    />
                  </td>
                  <td className="py-2 px-4 ">
                    <button
                      className="bg-accent text-white px-4 py-1 rounded"
                      onClick={() => openWithdrawModal()}
                    >
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
              <th className="py-2 px-4 border-b border-gray-700">Chains</th>
              <th className="py-2 px-4 border-b border-gray-700">Action</th>
              <th className="py-2 px-4 border-b border-gray-700"></th>
            </tr>
          </thead>
          <tbody>
            {borrowData.tokens.map((token, index) => (
              <tr key={index} className="border-b border-gray-700">
                <td className="py-2 px-4 ">{token.asset}</td>
                <td className="py-2 px-4 flex ">
                  {token.chains.map((i) => (
                    <Image
                      src={i == "Avax" ? Avax : i == "Base" ? Base : Optimism}
                      alt="Chain"
                      className="w-[30px] h-[30px] md:w-[30px] md:h-[30px]"
                    />
                  ))}
                </td>
                <td className="py-2 px-4 ">
                  <button
                    className="bg-accent text-white px-4 py-1 rounded"
                    onClick={() => openDepositModal()}
                  >
                    Deposit Collateral
                  </button>
                </td>
                <td className="py-2 px-4 ">
                  <button
                    className="bg-accent text-white px-4 py-1 rounded"
                    onClick={() => openBorrowModal()}
                  >
                    Borrow Token
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );

  return (
    <div>
      <div className="flex space-x-1 my-2">
        <button
          className={`px-4 py-2 text-2xl rounded w-1/2 ${
            selectedOption === "borrow"
              ? "bg-white text-accent"
              : "bg-gray-200 text-gray-900"
          }`}
          onClick={() => setSelectedOption("borrow")}
        >
          Borrow
        </button>
        <button
          className={`px-4 py-2 text-2xl rounded w-1/2 ${
            selectedOption === "lend"
              ? "bg-white text-accent"
              : "bg-gray-200 text-gray-900"
          }`}
          onClick={() => setSelectedOption("lend")}
        >
          Lend
        </button>
      </div>
      {selectedOption === "borrow" ? (
        renderBorrowSection()
      ) : (
        <Lend
          isSupplyModalOpen={isSupplyModalOpen}
          openSupplyModal={openSupplyModal}
          closeSupplyModal={closeSupplyModal}
          isWithdrawSupplyModalOpen={isWithdrawSupplyModalOpen}
          openWithdrawSupplyModal={openWithdrawSupplyModal}
          closeWithdrawSupplyModal={closeWithdrawSupplyModal}
        />
      )}
    </div>
  );
};

export default LendBorrow;
