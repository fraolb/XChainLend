import { FC, useState } from "react";
import { createPublicClient, http } from "viem";
//import { mainnet, goerli, sepolia } from "viem/chains";
import {
  sepolia,
  baseSepolia,
  avalancheFuji,
  optimismSepolia,
} from "thirdweb/chains";
import { sendTransaction, getContract, prepareContractCall } from "thirdweb";

interface SupplyModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const SupplyModal: FC<SupplyModalProps> = ({ isOpen, onClose }) => {
  const [selectedChain, setSelectedChain] = useState(baseSepolia);
  const [amount, setAmount] = useState<string>("");

  const handleNetworkChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const selectedChainId = parseInt(e.target.value, 10);
    const chain =
      selectedChainId === baseSepolia.id
        ? baseSepolia
        : selectedChainId === optimismSepolia.id
        ? optimismSepolia
        : avalancheFuji;
    setSelectedChain(chain);
  };

  const handleSupply = async () => {
    // try {
    //   const tx = await client.sendTransaction({
    //     to: "0xYourContractAddress", // Replace with your contract address
    //     value: amount ? BigInt(parseFloat(amount) * 10 ** 18) : BigInt(0),
    //   });
    //   console.log("Transaction sent:", tx);
    //   onClose();
    // } catch (error) {
    //   console.error("Transaction failed:", error);
    // }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center">
      <div className="bg-white p-6 rounded-lg w-96">
        <h2 className="text-xl font-bold mb-4">Supply Tokens</h2>

        <label className="block mb-2">Select Network</label>
        <select
          className="w-full mb-4 p-2 border border-gray-300 rounded"
          onChange={handleNetworkChange}
          value={selectedChain.id}
        >
          <option value={baseSepolia.id}>Base Sepolia</option>
          <option value={optimismSepolia.id}>Optimism</option>
          <option value={avalancheFuji.id}>Avalanche Fuji</option>
        </select>

        <label className="block mb-2">Amount</label>
        <input
          type="number"
          placeholder="Enter amount"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          className="w-full mb-4 p-2 border border-gray-300 rounded"
        />

        <button
          onClick={handleSupply}
          className="bg-blue-500 text-white w-full py-2 rounded"
        >
          Confirm Supply
        </button>
      </div>
    </div>
  );
};

export default SupplyModal;
