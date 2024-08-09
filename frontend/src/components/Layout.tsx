"use client";
import { FC, ReactNode } from "react";
import { ConnectButton } from "thirdweb/react";
import { sepolia, baseSepolia, avalancheFuji } from "thirdweb/chains";
import { client } from "@/app/client";
import Link from "next/link";
import { createWallet } from "thirdweb/wallets";
import Logo from "@public/Xchain logo.png";
import Image from "next/image";

interface LayoutProps {
  children: ReactNode;
}

const Layout: FC<LayoutProps> = ({ children }) => {
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
              <ConnectButton
                client={client}
                wallets={[
                  createWallet("io.metamask"),
                  createWallet("com.coinbase.wallet"),
                  createWallet("me.rainbow"),
                ]}
                theme="light"
                chains={[sepolia, baseSepolia, avalancheFuji]}
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
