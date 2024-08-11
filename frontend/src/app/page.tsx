import Image from "next/image";
import { ConnectButton } from "thirdweb/react";
import thirdwebIcon from "@public/thirdweb.svg";
import { client } from "./client";
import Layout from "@/components/Layout";
import LendBorrow from "@/components/LendBorrow";
import Logo from "@public/Xchain logo.png";
import Head from "next/head";

export default function Home() {
  return (
    <main>
      <Head>
        <link rel="icon" href="/icon.png" />
        <link rel="icon" href="/icon.png" sizes="any" />
      </Head>
      <Layout>
        <LendBorrow />
      </Layout>
    </main>
  );
}
