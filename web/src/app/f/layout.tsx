export default function Layout({ children }: LayoutProps<"/f">) {
  return <div className="flex flex-1 flex-col bg-papel text-tinta">{children}</div>;
}
