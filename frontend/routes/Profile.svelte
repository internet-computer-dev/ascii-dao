<script>
  import { get } from 'svelte/store'
  import { storage } from '../store'
  import { Principal } from "@dfinity/principal";

  import { useConnect, useCanister } from "@connect2ic/svelte"
  import "@connect2ic/core/style.css"

  import Loader from "../components/Loader.svelte"
  import NotConnected from "../components/NotConnected.svelte"
  import User from "../components/User.svelte"
  import Art from "../components/Art.svelte"

  const [dao, {loading}] = useCanister("dao");
  const [faucet] = useCanister("faucet");
  
  const { status, isConnected, principal } = useConnect({
    onDisconnect: () => {
      let newUserData = {
          principal: null,
          username: null,
          artworks: [],
          loggedIn: false,
          pfp: "\n\n\n\n\n\ \ \ \ \ \ \ \ ~ PFP not set ~\n\n\n\n\n\n\n\n\n",
          tokenBalance: 0,
      }
      storage.set(newUserData);
    }
  });

  let updateInProgress = false;

  const refreshUserData = async () => {
    updateInProgress = true;
    let update = get(storage);
    let profileData = await $dao.getProfileData();

    if (profileData.err) {
      update.username = profileData;
      update.loggedIn = false;
    }
    if (profileData.ok) {
      update.username = profileData.ok.username;
      update.loggedIn = true;
      if (profileData.ok.artworks[0] != undefined) {
        update.artworks = profileData.ok.artworks[0];
      };
      if (profileData.ok.pfp[0] != undefined) {
        (profileData.ok.artworks[0]).forEach((artwork) => {
          if (artwork.title == profileData.ok.pfp[0]) {
            update.pfp = artwork.art;
          }
        });
      }
    }
    if ($principal !== undefined) {
      update.principal = $principal.toString();
    }
    storage.set(update);
    if ($principal != null) {
      let tb = await $faucet.checkAccountBalance({owner: Principal.fromText($principal), subaccount: [] });
      update.tokenBalance = tb.accountBalance;
      update.TBupdated = true;
      storage.set(update);
    };
    updateInProgress = false;
  };

  // update data again if connect2ic tries to use anonymous identity 🙄
  $ : {
    if (($dao && !$loading && ($principal !== get(storage).principal) || $storage.username?.err == 'anonymous') && !updateInProgress && $status != "idle") {
      refreshUserData();
    }
  };

  $ : {
    console.log("storage update ", $storage)
  }

  $ : {
    console.log("status", $status)
  }

  console.log("status", $status)

</script>
{#if $status == "initializing"}
  <Loader />
{/if}

{#if !$isConnected}
    <NotConnected page={"profile"}/>
{:else}
    <div class="flex justify-center">
      <div class="flex justify-center w-2/5 p-10" style="height: 80vh">
        <User />
      </div>
      <div class="flex justify-center w-3/5 p-10" style="border-left: 1px dotted gray; transform: translate(0, 1%)">
        {#if $storage.loggedIn}
          <Art />
        {:else}
          <p></p>
        {/if}
      </div>
    </div>
{/if}