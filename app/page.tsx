import Image from "next/image";

import Header from "@/components/ui/header";
import banner from "@/public/banner.png";

export default function Home() {
  return (
    <div>
      <Header />
      <div className="px-4">
        <Image
          src={banner}
          alt="Agende com os melhores com a aparatus"
          sizes="100vw"
          className="h-auto w-full"
        />
      </div>
    </div>
  );
}
