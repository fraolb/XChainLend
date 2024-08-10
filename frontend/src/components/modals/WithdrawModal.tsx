import { FC, useState, useEffect } from "react";
//import { createPublicClient, http } from "viem";
import {
  useActiveWalletChain,
  useSwitchActiveWalletChain,
  useActiveAccount,
} from "thirdweb/react";
//import { mainnet, goerli, sepolia } from "viem/chains";
import {
  createPublicClient,
  createWalletClient,
  http,
  parseAbiItem,
  custom,
  encodeFunctionData,
} from "viem";
import {
  mainnet,
  baseSepolia as base,
  avalancheFuji as avax,
  optimismSepolia as opt,
} from "viem/chains";

import {
  sepolia,
  baseSepolia,
  avalancheFuji,
  optimismSepolia,
} from "thirdweb/chains";
//import { sendTransaction, getContract, prepareContractCall } from "thirdweb";

interface SupplyModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const WithdrawModal: FC<SupplyModalProps> = ({ isOpen, onClose }) => {
  const activeChain = useActiveWalletChain();
  const switchChain = useSwitchActiveWalletChain();
  const [selectedChain, setSelectedChain] = useState(baseSepolia);
  const [amount, setAmount] = useState<string>("");
  const [activeNetwork, setActiveNetwork] = useState();

  // For public calls (e.g., reading data)
  const publicClient = createPublicClient({
    chain: mainnet, // or another chain like Sepolia, etc.
    transport: http(),
  });

  const contractAddress = "0xc28325EcEDa11d7C769A39e9C4076f79a2157252";
  const abi = [
    // the ABI for your contract
    {
      inputs: [
        {
          internalType: "address",
          name: "lender",
          type: "address",
        },
        {
          internalType: "address",
          name: "tokenAddress",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "amount",
          type: "uint256",
        },
        {
          internalType: "uint256", // or "string" depending on how the chain parameter is defined in your contract
          name: "chain",
          type: "uint256",
        },
      ],
      name: "lendTokenFromDifferentChain",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function",
    },
  ];

  const handleSupply = async () => {
    const lenderAddress = "0xc28325EcEDa11d7C769A39e9C4076f79a2157252";
    const tokenAddress = "0xc28325EcEDa11d7C769A39e9C4076f79a2157252";
    const amount = 1;
    const chainId = 1;

    if (typeof window !== "undefined" && window.ethereum) {
      const provider = window.ethereum;
      // Use the provider (MetaMask, etc.)
      const network =
        selectedChain == baseSepolia
          ? base
          : selectedChain == optimismSepolia
          ? opt
          : avax;
      const walletClient = createWalletClient({
        chain: network,
        transport: custom(window.ethereum!),
      });
      const [account] = await walletClient.getAddresses();

      const functionData = encodeFunctionData({
        abi,
        functionName: "lendTokenFromDifferentChain",
        args: [lenderAddress, tokenAddress, amount, chainId],
      });

      try {
        const tx = await walletClient.sendTransaction({
          account: account,
          to: contractAddress,
          data: functionData,
          value: 0n,
        });
        console.log("Transaction sent:", tx);
      } catch (error) {
        console.error("Transaction failed:", error);
      }
    } else {
      console.error("Ethereum provider not found");
    }
  };

  useEffect(() => {
    // const active = useActiveWalletChain();
    // setActiveNetwork(active);
    setSelectedChain(baseSepolia);
  }, []);
  console.log("active network from modal is ", activeChain);
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center text-black">
      <div className="bg-white z-20 p-6 rounded-lg w-96">
        <div className="flex justify-end">
          <button
            className="text-white text-red-500 rounded-lg text-2xl"
            onClick={() => onClose()}
          >
            x
          </button>
        </div>
        <h2 className="text-xl font-bold mb-4 text-accent">Withdraw Token</h2>

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
          className="bg-accent text-white w-full py-2 rounded"
        >
          Confirm Withdraw
        </button>
      </div>
    </div>
  );
};

export default WithdrawModal;
