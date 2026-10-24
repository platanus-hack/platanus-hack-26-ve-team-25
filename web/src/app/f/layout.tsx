import { atkinson } from "@/lib/fuentes";

export default function Layout({ children }: LayoutProps<"/f">) {
  return <div className={`${atkinson.className} flex flex-1 flex-col bg-papel text-tinta`}>{children}</div>;
}
