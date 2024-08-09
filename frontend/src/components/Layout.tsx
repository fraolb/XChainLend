import { FC, ReactNode } from "react";
import { ConnectButton } from "thirdweb/react";
import { client } from "@/app/client";
import Link from "next/link";

interface LayoutProps {
  children: ReactNode;
}

const Layout: FC<LayoutProps> = ({ children }) => {
  return (
    <div className="bg-primary text-white min-h-screen w-full">
      <header className="p-4 bg-secondary shadow-lg border border-bottom-solid">
        <div className="container mx-auto flex justify-between items-center">
          <h1 className="text-xl font-bold">XChain Lend</h1>
          <div className="flex">
            <Link href="#" className="ml-3 text-accent">
              Home
            </Link>
            <Link href="#" className="ml-3 text-accent">
              Markets
            </Link>
            <Link href="#" className="ml-3 text-accent">
              Governance
            </Link>
            <div className="ml-3 text-accent">
              <ConnectButton
                client={client}
                appMetadata={{
                  name: "Example App",
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
