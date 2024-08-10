"use client";

import React, { useState } from "react";
import Image from "next/image";

import Avax from "@public/avax.png";
import Base from "@public/base.png";
import Optimism from "@public/optimism.png";
import SupplyModal from "./modals/SupplyModal";
import WithdrawModal from "./modals/WithdrawModal";

type LendData = {
  lent: { asset: string; amount: number; apy: string; chain: string }[];
  tokens: { asset: string; apy: string; chains: string[] }[];
};

interface ModalProps {
  isSupplyModalOpen: boolean;
  openSupplyModal: () => void;
  closeSupplyModal: () => void;
  isWithdrawSupplyModalOpen: boolean;
  openWithdrawSupplyModal: () => void;
  closeWithdrawSupplyModal: () => void;
}

const Lend: React.FC<ModalProps> = ({
  isSupplyModalOpen,
  openSupplyModal,
  closeSupplyModal,
  isWithdrawSupplyModalOpen,
  openWithdrawSupplyModal,
  closeWithdrawSupplyModal,
}) => {
  const lendData: LendData = {
    lent: [{ asset: "USDC", amount: 10, apy: "2.1%", chain: "Base" }],
    tokens: [
      { asset: "CCIP-BnM", apy: "2.5", chains: ["Base", "Optmism", "Avax"] },
      { asset: "USDC", apy: "2.1", chains: ["Base", "Optmism", "Avax"] },
      { asset: "GHO", apy: "2.5", chains: ["Base", "Avax"] },
    ],
  };

  return (
    <div>
      <section>
        <div className="bg-secondary text-black rounded-xl p-4 shadow-lg mb-6">
          <h2 className="text-xl font-bold mb-2 ml-4">Lent Tokens</h2>
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
              {lendData.lent.map((token, index) => (
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
                        token.chain === "Avax"
                          ? Avax
                          : token.chain === "Base"
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
                    <button
                      onClick={openWithdrawSupplyModal}
                      className="bg-accent text-white px-4 py-1 rounded"
                    >
                      Withdraw
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="bg-secondary  text-black rounded-xl p-4 shadow-lg">
          <h2 className="text-xl font-bold mb-2 ml-4">Tokens</h2>
          <table className="w-full text-left">
            <thead>
              <tr>
                <th className="py-2 px-4 border-b border-gray-700">Assets</th>
                <th className="py-2 px-4 border-b border-gray-700">Chains</th>
                <th className="py-2 px-4 border-b border-gray-700">APY</th>
                <th className="py-2 px-4 border-b border-gray-700">Actions</th>
              </tr>
            </thead>
            <tbody>
              {lendData.tokens.map((token, index) => (
                <tr key={index}>
                  <td className="py-2 px-4 border-b border-gray-700">
                    {token.asset}
                  </td>
                  <td className="py-2 flex px-4 border-b border-gray-700">
                    {token.chains.map((i) => (
                      <Image
                        src={i == "Avax" ? Avax : i == "Base" ? Base : Optimism}
                        alt="Chain"
                        className="w-[30px] h-[30px] md:w-[30px] md:h-[30px]"
                      />
                    ))}
                  </td>
                  <td className="py-2 px-4 border-b border-gray-700">
                    {token.apy}
                  </td>
                  <td className="py-2 px-4 border-b border-gray-700">
                    <button
                      onClick={openSupplyModal}
                      className="bg-accent text-white px-4 py-1 rounded"
                    >
                      Supply
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <SupplyModal isOpen={isSupplyModalOpen} onClose={closeSupplyModal} />
        <WithdrawModal
          isOpen={isWithdrawSupplyModalOpen}
          onClose={closeWithdrawSupplyModal}
        />
      </section>
    </div>
  );
};

export default Lend;
