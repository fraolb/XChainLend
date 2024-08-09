"use client";

import { useState } from "react";

type BorrowData = {
  borrowed: { asset: string; amount: number; apy: string }[];
  collateral: { asset: string; amount: number; apy: string }[];
  tokens: { asset: string }[];
};

type LendData = {
  lent: { asset: string; amount: number; apy: string }[];
  tokens: { asset: string }[];
};

const LendBorrow = () => {
  const [selectedOption, setSelectedOption] = useState<"borrow" | "lend">(
    "borrow"
  );

  const borrowData: BorrowData = {
    borrowed: [
      { asset: "ETH", amount: 1.5, apy: "3.5%" },
      { asset: "DAI", amount: 500, apy: "4.2%" },
    ],
    collateral: [
      { asset: "ETH", amount: 1.5, apy: "3.5%" },
      { asset: "DAI", amount: 500, apy: "4.2%" },
    ],
    tokens: [{ asset: "USDT" }, { asset: "WBTC" }],
  };

  const lendData: LendData = {
    lent: [{ asset: "USDC", amount: 1000, apy: "2.1%" }],
    tokens: [{ asset: "AAVE" }, { asset: "LINK" }],
  };

  const renderBorrowSection = () => (
    <section>
      <div className="bg-secondary text-black rounded-xl p-4 shadow-lg mb-6">
        <h2 className="text-xl font-bold mb-2">Borrowed Tokens</h2>
        <table className="w-full text-left">
          <thead>
            <tr>
              <th className="py-2 px-4 border-b border-gray-700">Assets</th>
              <th className="py-2 px-4 border-b border-gray-700">Amount</th>
              <th className="py-2 px-4 border-b border-gray-700">APY</th>
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
                  <button className="bg-accent text-white px-4 py-1 rounded">
                    Pay Back
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <div className="bg-secondary text-black rounded-xl p-4 shadow-lg mb-6">
        <h2 className="text-xl font-bold mb-2">Collateral Tokens</h2>
        <table className="w-full text-left">
          <thead>
            <tr>
              <th className="py-2 px-4 border-b border-gray-700">Assets</th>
              <th className="py-2 px-4 border-b border-gray-700">Amount</th>
              <th className="py-2 px-4 border-b border-gray-700">APY</th>
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
                  <button className="bg-accent text-white px-4 py-1 rounded">
                    Redeem
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <div className="bg-secondary text-black rounded-xl p-4 shadow-lg">
        <h2 className="text-xl font-bold mb-2">Tokens</h2>
        <table className="w-full text-left">
          <thead>
            <tr>
              <th className="py-2 px-4 border-b border-gray-700">Assets</th>
            </tr>
          </thead>
          <tbody>
            {borrowData.tokens.map((token, index) => (
              <tr key={index}>
                <td className="py-2 px-4 border-b border-gray-700">
                  {token.asset}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );

  const renderLendSection = () => (
    <section>
      <div className="bg-secondary text-black rounded-xl p-4 shadow-lg mb-6">
        <h2 className="text-xl font-bold mb-2">Lent Tokens</h2>
        <table className="w-full text-left">
          <thead>
            <tr>
              <th className="py-2 px-4 border-b border-gray-700">Assets</th>
              <th className="py-2 px-4 border-b border-gray-700">Amount</th>
              <th className="py-2 px-4 border-b border-gray-700">APY</th>
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
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <div className="bg-secondary  text-black rounded-xl p-4 shadow-lg">
        <h2 className="text-xl font-bold mb-2">Tokens</h2>
        <table className="w-full text-left">
          <thead>
            <tr>
              <th className="py-2 px-4 border-b border-gray-700">Assets</th>
            </tr>
          </thead>
          <tbody>
            {lendData.tokens.map((token, index) => (
              <tr key={index}>
                <td className="py-2 px-4 border-b border-gray-700">
                  {token.asset}
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
      <div className="flex space-x-2 my-2">
        <button
          className={`px-4 py-2 text-2xl rounded w-1/2 ${
            selectedOption === "borrow"
              ? "bg-white text-accent"
              : "bg-secondary text-gray-400"
          }`}
          onClick={() => setSelectedOption("borrow")}
        >
          Borrow
        </button>
        <button
          className={`px-4 py-2 text-2xl rounded w-1/2 ${
            selectedOption === "lend"
              ? "bg-white text-accent"
              : "bg-secondary text-gray-400"
          }`}
          onClick={() => setSelectedOption("lend")}
        >
          Lend
        </button>
      </div>
      {selectedOption === "borrow"
        ? renderBorrowSection()
        : renderLendSection()}
    </div>
  );
};

export default LendBorrow;
