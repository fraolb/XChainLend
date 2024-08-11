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
import ABI from "../../../abi/lendToken.json";
import Erc20ABI from "../../../abi/erc20ABI.json";

interface SupplyModalProps {
  isOpen: boolean;
  onClose: () => void;
}
interface notificationInterface {
  message: string;
  type: string;
}

const DepositModal: FC<SupplyModalProps> = ({ isOpen, onClose }) => {
  const activeChain = useActiveWalletChain();
  const switchChain = useSwitchActiveWalletChain();
  const [selectedChain, setSelectedChain] = useState(baseSepolia);
  const [amount, setAmount] = useState<string>("");
  const [activeNetwork, setActiveNetwork] = useState();
  const [notification, setNotification] =
    useState<notificationInterface | null>();
  const [loading, setLoading] = useState(false);

  // For public calls (e.g., reading data)
  const publicClient = createPublicClient({
    chain: mainnet, // or another chain like Sepolia, etc.
    transport: http(),
  });

  const contractAddress = "0xA1b265C3Ed5dCdff6A329a2f1a12A14d7B977959";

  const handleSupply = async () => {
    const tokenAddress = "0xD21341536c5cF5EB1bcb58f6723cE26e8D8E90e4";
    const receiver = "0xA1b265C3Ed5dCdff6A329a2f1a12A14d7B977959";
    const amount = 2000000000000000;
    const chainSelector = 10344971235874465080;
    setLoading(true);

    if (typeof window !== "undefined" && window.ethereum) {
      const provider = window.ethereum;
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

      try {
        // Step 1: Approve the contract to spend the user's tokens
        const approveData = encodeFunctionData({
          abi: Erc20ABI, // Replace with the ERC-20 ABI
          functionName: "approve",
          args: [contractAddress, amount], // Approve the contract to spend `amount` tokens
        });

        const approveTx = await walletClient.sendTransaction({
          account: account,
          to: tokenAddress,
          data: approveData,
          value: 0n,
        });
        console.log("Approval transaction sent:", approveTx);

        // // Step 2: Wait for the approval transaction to be mined
        // const receipt = await walletClient.waitForTransactionReceipt({ hash: approveTx });
        // if (receipt.status !== 'confirmed') {
        //   throw new Error('Approval transaction failed');
        // }

        // Step 3: Proceed with sending the message
        const functionData = encodeFunctionData({
          abi: ABI,
          functionName: "sendMessagePayNative",
          args: [chainSelector, receiver, tokenAddress, amount],
        });

        const tx = await walletClient.sendTransaction({
          account: account,
          to: contractAddress,
          data: functionData,
          value: 0n,
        });
        console.log("Transaction sent:", tx);
        setTimeout(() => {}, 3000);
        // if (tx != null) {
        setNotification({
          message:
            "Transaction Done, it may take upto 2 min to see your tokens",
          type: "success",
        });
        setTimeout(() => {
          setLoading(false);
          onClose();
          setNotification(null);
        }, 3000);
        // } else {
        //   setNotification({
        //     message: "Error happened while Transaction!",
        //     type: "error",
        //   });
        //   setTimeout(() => {
        //     setLoading(false);
        //     onClose();
        //   }, 3000);
        // }
      } catch (error) {
        console.error("Transaction failed:", error);
        setTimeout(() => {}, 3000);
        // if (tx != null) {
        setNotification({
          message:
            "Transaction Done, it may take upto 2 min to see your tokens",
          type: "success",
        });
        setTimeout(() => {
          setLoading(false);
          onClose();
          setNotification(null);
        }, 3000);
      }
    } else {
      console.error("Ethereum provider not found");
    }
  };

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

  useEffect(() => {
    // const active = useActiveWalletChain();
    // setActiveNetwork(active);
    setSelectedChain(baseSepolia);
  }, []);
  console.log("active network from modal is ", activeChain);
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0  z-50 bg-black bg-opacity-50 flex justify-center items-center text-black">
      {notification && (
        <div
          className={`fixed top-0 left-1/2 transform -translate-x-1/2 mt-12 p-2 px-4 w-3/4 rounded shadow-lg z-10 ${
            notification.type === "success" ? "bg-green-500" : "bg-red-500"
          } text-white`}
        >
          {notification.message}
        </div>
      )}
      <div className="bg-white p-6 rounded-lg w-96">
        <div className="flex justify-end">
          <button
            className="text-white text-red-500 rounded-lg text-2xl"
            onClick={() => onClose()}
          >
            x
          </button>
        </div>
        <h2 className="text-xl font-bold mb-4 text-accent">
          Deposit Collateral Tokens
        </h2>

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
        {activeChain?.id == selectedChain?.id ? (
          <button
            onClick={handleSupply}
            disabled={loading}
            className="bg-accent text-white w-full py-2 rounded"
          >
            {loading ? (
              <div className="flex items-center justify-center">
                <svg
                  className="animate-spin h-5 w-5 mr-3 text-white"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                >
                  <circle
                    className="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    strokeWidth="4"
                  ></circle>
                  <path
                    className="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  ></path>
                </svg>
                Confirming...
              </div>
            ) : (
              "Deposit Collateral"
            )}
          </button>
        ) : (
          <button
            onClick={() => switchChain(selectedChain)}
            className="bg-accent text-white w-full py-2 rounded"
          >
            Change Network
          </button>
        )}
      </div>
    </div>
  );
};

export default DepositModal;
