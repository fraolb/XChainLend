import Image from "next/image";
import { ConnectButton } from "thirdweb/react";
import thirdwebIcon from "@public/thirdweb.svg";
import { client } from "./client";
import Layout from "@/components/Layout";
import LendBorrow from "@/components/LendBorrow";
import Logo from "@public/Xchain logo.png";

export default function Home() {
  return (
    <main>
      <Layout>
        <LendBorrow />
      </Layout>
    </main>
  );
}
