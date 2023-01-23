<script>
  import logo from "./assets/logo-dark.svg"
  // connect2ic
  import { createClient } from "@connect2ic/core"
  import { defaultProviders } from "@connect2ic/core/providers"
  import { ConnectButton, ConnectDialog, Connect2ICProvider } from "@connect2ic/svelte"
  import "@connect2ic/core/style.css"
  import * as dao from "../.dfx/local/canisters/dao"
  import { faucetIDL } from "./assets/mbfaucet.did.js";
  import { tokensIDL } from "./assets/mbtokens.did.js";
  // router
  import { Router, Route, link } from "svelte-routing";
  import Profile from "./routes/Profile.svelte";
  import Gallery from "./routes/Gallery.svelte";
  import Proposals from "./routes/Proposals.svelte";
  import Neurons from "./routes/Neurons.svelte";
  import About from "./routes/About.svelte";

  export let url = "";

  // global canisters
  const client = createClient({
    canisters: {
      ["faucet"]: {
        canisterId: "dg2ce-tqaaa-aaaah-abz6q-cai",
        idlFactory: faucetIDL,
      },
      ["tokens"]: {
        canisterId: "db3eq-6iaaa-aaaah-abz6a-cai",
        idlFactory: tokensIDL,
      },
      ["dao"]: { // for calling ic canister
        canisterId: "gtnjc-eaaaa-aaaai-qhmva-cai",
        idlFactory: dao.idlFactory,
      },
      // dao, // for calling local canister instance
    },
    providers: defaultProviders,
    globalProviderConfig: {
      dev: import.meta.env.DEV,
      host: "https://ic0.app",
    },
  });
</script>

<div class="flex-column">
<Connect2ICProvider client={client}>
  <ConnectDialog />
  <Router url="{url}">
    <!-- gloabl header -->
    <div class="navbar" style="background-color:black">
      <div class="navbar-start">
        <div class="dropdown">
          <!-- svelte-ignore a11y-label-has-associated-control -->
          <label tabindex="-1" class="btn btn-ghost btn-circle base-100">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="white" viewBox="0 0 24 24" stroke="white"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h7" /></svg>
          </label>
          <ul tabindex="-2" class="menu menu-compact dropdown-content mt-3 p-2 shadow bg-base-100 rounded-box w-52">
            <li><a href="/" use:link >Profile</a></li>
            <li><a href="/gallery" use:link>DAO Gallery</a></li>
            <li><a href="/proposals" use:link>Proposals</a></li>
            <li><a href="/neurons" use:link>Neurons</a></li>
            <li><a href="/about" use:link>About</a></li>
          </ul>
        </div>
      </div>
      <div class="navbar-center">
        <a class="btn btn-ghost normal-case text-xl font-bold text-gray-600 " style="font-family: consolas; font-size: 3em; font-color: grey" href="/" use:link>
          <pre style="font-size: 10.5px; line-height: 8px; font-family: consolas; text-align: left; font-weight: 900; letter-spacing: -1px; margin: 0; padding: 0 0 3px 0; border: 0; transform: translate(0, -6px); color: antiquewhite">
     ___           _______.  ______  __   __      _______       ___       ______   
    /   \         /       | /      ||  | |  |    |       \     /   \     /  __  \  
   /  ^  \       |   (----`|  ,----'|  | |  |    |  .--.  |   /  ^  \   |  |  |  | 
  /  /_\  \       \   \    |  |     |  | |  |    |  |  |  |  /  /_\  \  |  |  |  | 
 /  _____  \  .----)   |   |  `----.|  | |  |    |  '--'  | /  _____  \ |  `--'  | 
/__/     \__\ |_______/     \______||__| |__|    |_______/ /__/     \__\ \______/  
          </pre></a>
      </div>
      <div class="navbar-end">
        <ConnectButton />
      </div>
    </div>

    <!-- routes -->
    <div style="min-height: 84vh">
      <Route path="/"><Profile /></Route>
      <Route path="/gallery"><Gallery /></Route>
      <Route path="/proposals"><Proposals /></Route>
      <Route path="/neurons"><Neurons /></Route>
      <Route path="/about"><About /></Route>
    </div>

  </Router>
</Connect2ICProvider>

<!-- global footer -->
<footer style="width: 100vw; text-align: center; font-weight: bold; font-family: consolas; align-self: flex-end">HOSTED 100% ON-CHAIN 
  <img style="height: 12px; display: initial" src={logo} alt="ic-logo">
  <p>A precursor to <a class="text-gray-500 hover:text-gray-800" href="https://twitter.com/internetdegens">Internet Degens</a></p>
</footer>
</div>

<style lang="postcss">
  @tailwind base;
  @tailwind components;
  @tailwind utilities;

* {
  font-family: consolas;
}
</style>