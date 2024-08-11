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
import LendProtocolABI from "../../../abi/lendProtocol.json";
import TokenTransferABI from "../../../abi/TokenTransfer.json";

interface SupplyModalProps {
  isOpen: boolean;
  onClose: () => void;
}
interface notificationInterface {
  message: string;
  type: string;
}

const WithdrawModal: FC<SupplyModalProps> = ({ isOpen, onClose }) => {
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

  const lendContractAddress = "0x958512C9540e72573854A77D36fb3fA600eC9d05";

  const handleWithdraw = async () => {
    if (typeof window !== "undefined" && window.ethereum) {
      setLoading(true);
      const provider = window.ethereum;
      // Use the provider (MetaMask, etc.)

      const walletClient = createWalletClient({
        chain: base,
        transport: custom(window.ethereum!),
      });
      const [account] = await walletClient.getAddresses();

      const text = { user: account, task: "withdraw" };

      const functionData = encodeFunctionData({
        abi: TokenTransferABI,
        functionName: "sendMessagePayNative",
        args: [
          5224473277236331295,
          account,
          JSON.stringify(text),
          "0x88a2d74f47a237a62e7a51cdda67270ce381555e",
          1000000000000000,
        ],
      });

      try {
        const tx = await walletClient.sendTransaction({
          account: account,
          to: lendContractAddress,
          data: functionData,
          value: 0n,
        });
        console.log("Transaction sent:", tx);
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
      setTimeout(() => {}, 3000);
      // if (tx != null) {
      setNotification({
        message: "Transaction Done, it may take upto 2 min to see your tokens",
        type: "success",
      });
      setTimeout(() => {
        setLoading(false);
        onClose();
        setNotification(null);
      }, 3000);
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
    <div className="fixed inset-0 z-50 bg-black bg-opacity-50 flex justify-center items-center text-black">
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
          onClick={handleWithdraw}
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
            "Confirm Withdraw"
          )}
        </button>
      </div>
    </div>
  );
};

export default WithdrawModal;
