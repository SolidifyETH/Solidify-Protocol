//Track Addresses (Fill in present addresses to user existing deplopyment)
const publicAddr: any = {
  hardhat:{
    openRepo: "",
    ruleRepo: "",
  },
  rinkeby:{
    openRepo: "0x7b0AA37bCf5D231C13C920E0e372027919510fF9", //D2.0 (UUPS)
    ruleRepo: "0xa14C272e1D6BE9c89933e2Ad8560e83F945Ee407", //D1.0
  },
  goerli:{
    openRepo: "0xD1a6789c8A47a931833369E9EAAD5c42BF819473", //D2.1 (UUPS)
    ruleRepo: "0xF8B45CB9c3A63bE93B63a382729C733cB988de69", //D1.0
  },
  mumbai:{
    openRepo: "0x647DBF306fE835E231dB1f9d711364806467E20a", //0.5.2
    ruleRepo: "0x196FA9eCFbf6cE2643E53dB477332aD68a80D20f", //0.5.2
  },
  optimism:{
    openRepo: "",
    ruleRepo: "",
  },
  optimism_kovan:{
    openRepo: "0xFF20BA5dcD0485e2587F1a75117c0fc80941B61C",
    ruleRepo: "0x98B28D02AF16600790aAE38d8F587eA99585BBb2",
  },
};

export default publicAddr;