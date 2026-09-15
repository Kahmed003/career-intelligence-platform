import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: { default: "Career OS", template: "%s | Career OS" },
  description: "Career planning, applications, relationships, projects, and analytics.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
