<script>
  import logo from "./assets/logo-dark.svg"
  // connect2ic
  import { createClient } from "@connect2ic/core"
  import { defaultProviders } from "@connect2ic/core/providers"
  import { ConnectButton, ConnectDialog, Connect2ICProvider } from "@connect2ic/svelte"
  import "@connect2ic/core/style.css"
  import * as dao from "../.dfx/local/canisters/dao"
  // router
  import { Router, Route, link } from "svelte-routing";
  import Profile from "./routes/Profile.svelte";
  import Proposals from "./routes/Proposals.svelte";
  import Neurons from "./routes/Neurons.svelte";

  export let url = "";

  const client = createClient({
    canisters: {
      dao,
    },
    providers: defaultProviders,
    globalProviderConfig: {
      dev: import.meta.env.DEV,
    },
  });

</script>

<Connect2ICProvider client={client}>
  <ConnectDialog />
  <Router url="{url}">
    <div class="navbar bg-base-100 h-5em">
      <div class="navbar-start">
        <div class="dropdown">
          <!-- svelte-ignore a11y-label-has-associated-control -->
          <label tabindex="-1" class="btn btn-ghost btn-circle">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h7" /></svg>
          </label>
          <ul tabindex="-2" class="menu menu-compact dropdown-content mt-3 p-2 shadow bg-base-100 rounded-box w-52">
            <li><a href="/" use:link class="font-bold">Profile</a></li>
            <li><a href="/proposals" use:link>Proposals</a></li>
            <li><a href="/neurons" use:link>Neurons</a></li>
            <li><a href="/proposals" use:link>DAO Gallery</a></li>
            <li><a href="/proposals" use:link>Private Gallery</a></li>
          </ul>
        </div>
      </div>
      <div class="navbar-center">
        <a class="btn btn-ghost normal-case text-xl font-bold text-gray-600 " style="font-family: consolas; font-size: 3em; font-color: grey" href="/" use:link>ASCII DAO</a>
      </div>
      <div class="navbar-end">
        <ConnectButton />
      </div>
    </div>

    <div>
      <Route path="/"><Profile /></Route>
      <Route path="/proposals"><Proposals /></Route>
      <Route path="/neurons"><Neurons /></Route>
    </div>
  </Router>
</Connect2ICProvider>

<footer style="position: relative; bottom: 0; width: 100vw; text-align: center; font-weight: bold;font-family: consolas">HOSTED 100% ON-CHAIN 
  <img style="height: 12px; display: initial" src={logo} alt="ic-logo">
  <p>A precursor to <a class="text-gray-500 hover:text-gray-800" href="https://twitter.com/internetdegens">Internet Degens</a></p>
</footer>


<style lang="postcss">
  @tailwind base;
  @tailwind components;
  @tailwind utilities;

* {
  font-family: consolas;
}
</style>