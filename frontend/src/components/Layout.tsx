"use client";
import { FC, ReactNode } from "react";
import { ConnectButton } from "thirdweb/react";
import {
  sepolia,
  baseSepolia,
  avalancheFuji,
  optimismSepolia,
} from "thirdweb/chains";
import { client } from "@/app/client";
import Link from "next/link";
import { createWallet } from "thirdweb/wallets";
import Logo from "@public/Xchain logo.png";
import Avax from "@public/avax.png";
import Base from "@public/base.png";
import Optimism from "@public/optimism.png";
import Image from "next/image";
import { useActiveWalletChain } from "thirdweb/react";

interface LayoutProps {
  children: ReactNode;
}

const Layout: FC<LayoutProps> = ({ children }) => {
  const activeChain = useActiveWalletChain();
  console.log("the active chain is ", activeChain);
  return (
    <div className="bg-primary min-h-screen w-full">
      <header className="p-4 bg-secondary shadow-lg border-b border-solid">
        <div className="container mx-auto flex justify-between items-center max-w-7xl">
          <Image
            src={Logo}
            alt="Logo"
            className="w-[140px] h-[60px] md:w-[140px] md:h-[60px]"
            style={{
              filter: "drop-shadow(0px 0px 24px #a726a9a8)",
            }}
          />
          <div className="flex items-center space-x-4">
            <Link href="#" className="text-accent text-xl">
              Markets
            </Link>
            <Link href="#" className="text-accent text-xl">
              Liquidators
            </Link>
            <div className="text-accent">
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
            <div className="text-accent">
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
        </div>
      </header>
      <main className="container mx-auto p-4 max-w-7xl">{children}</main>
      <footer className="p-4 bg-primary text-center text-accent max-w-7xl mx-auto">
        <p>© 2024 XChain Lend. All rights reserved.</p>
      </footer>
    </div>
  );
};

export default Layout;
