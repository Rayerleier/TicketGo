import type { Metadata } from "next";
import { inter } from "@/app/components/fonts";
import "./globals.css";
import { Providers } from "./providers";

import Image from "next/image";
import Link from "next/link";

import { headers } from "next/headers";
import { cookieToInitialState } from "wagmi";
import { config } from "@/config";
import Web3ModalProvider from "@/context";

export const metadata: Metadata = {
  title: "Ticket Go 2024",
  description:
    "Join us for the Pori Jazz Festival from July 12-20, 2024 in Pori, Finland.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const initialState = cookieToInitialState(config, headers().get("cookie"));
  return (
    <html lang="en" className="dark">
      <body className={inter.className}>
        <Providers>
          <Web3ModalProvider initialState={initialState}>
            <header className="fixed z-10 shadow-md w-full bg-gradient-to-r from-pink-500 via-purple-500 to-indigo-500 text-white opacity-90">
              <div className="container mx-auto flex justify-between items-center py-4">
                <Link href="/">
                  <Image
                    src="/TicketGo.svg"
                    alt="logo"
                    height={60}
                    width={186}
                  />
                </Link>

                <nav className="space-x-8 font-bold">
                  <Link href="/concerts" className="hover:text-orange-500">
                    CONCERTS
                  </Link>
                  <Link href="#" className="hover:text-orange-500">
                    ARTISTS
                  </Link>
                  <Link href="#" className="hover:text-orange-500">
                    INFO
                  </Link>
                  <Link href="#" className="hover:text-orange-500">
                    NEWS
                  </Link>
                </nav>

                <div className="space-x-4">
                  <w3m-button />
                </div>
              </div>
            </header>

            <main className="min-h-screen bg-gradient-to-r from-pink-400 via-purple-400 to-indigo-400">
              {children}
            </main>

            <footer className="bg-gradient-to-r from-pink-500 via-purple-500 to-indigo-500 text-white py-6">
              <div className="container mx-auto text-center">
                <p>&copy; 2024 Ticket Go. All rights reserved.</p>
              </div>
            </footer>
          </Web3ModalProvider>
        </Providers>
      </body>
    </html>
  );
}
