/* eslint-disable jsx-a11y/alt-text */
import { MenuIcon } from "lucide-react";
import Image from "next/image";

import { Button } from "./button";

const Header = () => {
    return <header className="flex flex-center justify-between bg-background px-5 py6">
       <Image src="/logo.svg" alt="Aparatus" width={91} height={24}/>
       <Button variant={"outline"} size={"icon"}>
       <MenuIcon/>
        </Button>
    </header>
}

export default Header;