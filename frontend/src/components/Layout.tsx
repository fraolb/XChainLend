"use client";
import { FC, ReactNode } from "react";
import { ConnectButton } from "thirdweb/react";
import { sepolia, baseSepolia, avalancheFuji } from "thirdweb/chains";
import { client } from "@/app/client";
import Link from "next/link";
import { createWallet } from "thirdweb/wallets";

interface LayoutProps {
  children: ReactNode;
}

const Layout: FC<LayoutProps> = ({ children }) => {
  return (
    <div className="bg-primary text-white min-h-screen w-full">
      <header className="p-4 bg-secondary shadow-lg border-b border-solid">
        <div className="container mx-auto flex justify-between items-center">
          <h1 className="text-xl font-bold">XChain Lend</h1>
          <div className="flex items-center space-x-4">
            <Link href="#" className="text-accent">
              Home
            </Link>
            <Link href="#" className="text-accent">
              Markets
            </Link>
            <Link href="#" className="text-accent">
              Governance
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
      <main className="container mx-auto p-4">{children}</main>
      <footer className="p-4 bg-secondary text-center">
        <p>© 2024 XChain Lend. All rights reserved.</p>
      </footer>
    </div>
  );
};

export default Layout;
