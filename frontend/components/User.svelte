<script>
  import { get } from 'svelte/store';
  import { storage } from '../store';
  import { fade } from 'svelte/transition';
  import { Principal } from "@dfinity/principal";

  import { useCanister, useConnect } from "@connect2ic/svelte";

  let name = "";
  let newPfp = "";
  let minting = false;

  const [ faucet ] = useCanister("faucet");
  const [ dao ] = useCanister("dao");
  const { principal } = useConnect({});

  const newUser = async () => {
    const result = await $dao.newUser(name);
    if (result.ok) {
      let newUserData = {
          principal: null,
          username: null,
          artworks: [],
          loggedIn: false,
          pfp: "\n\n\n\n\n\ \ \ \ \ \ \ \ ~ PFP not set ~\n\n\n\n\n\n\n\n\n",
          tokenBalance: 0,
      }
      storage.set(newUserData);
    } else if (result.err) { window.alert(result) }
  }

  const updatePfp = async () => {
    const result = await $dao.setPfp(newPfp);
    if (result.ok) {
      let update = get(storage);
      $storage.artworks.forEach((artwork) => {
        if (artwork.title == newPfp) {
          update.pfp = artwork.art;
        }
      });
      storage.set(update);
    } else if (result.err) { window.alert(result.err) }
  }

  // should show loading while mint
  const mint = async () => {
    minting = true;
      try {
        let txResult = await $faucet.mintNow({
          to : {"owner" : Principal.fromText($principal), "subaccount" : []},
          memo : [],
          created_at_time : [],
          amount : 10_000_000_00,
        });
        console.log("txResult",txResult);
        let tb = await $faucet.checkAccountBalance({owner: Principal.fromText($principal), subaccount: [] });
        let update = get(storage);
        update.tokenBalance = tb.accountBalance;
        storage.set(update);
      } catch { window.alert("could not mint!")}
    minting = false;
    };

</script>

<div class="example">
  {#if $storage.username == null || $storage.username.err == "anonymous"}
    <div in:fade="{{ duration: 7000 }}">Loading . . .</div>
  {:else if $principal && $storage.username.err == "user not found"}
    <label style="font-weight: bold; font-size: 2em">new user:</label>
    <input type="text" placeholder="enter username" class="input input-bordered w-full max-w-xs mt-6 mb-6" bind:value={name}>
    <button class="connect-button" on:click={newUser}>create</button>
  {:else if $principal && $storage.username}
    <p style="font-size: 2.5em;">{$storage.username}</p>
    <p style="font-size: 1.2em;">Token Balance: {BigInt($storage.tokenBalance) / BigInt(100000000)}MB</p>
    {#if !minting}
    <button class="btn-success btn-outline" on:click={mint}>mint 10 MB tokens</button>
    {:else}
    <button class="btn-success btn-outline btn-disabled">mint 10 MB tokens</button>
    {/if}
    <!-- <pre style="border: 1px dotted gray; margin: 1.5em 0"></pre> -->
    <div class="mockup-code m-3">
      <pre style="color:gray; height: 23.5em"><br><code style="color:antiquewhite">{$storage.pfp}</code></pre>
    </div>
    <input placeholder="enter artwork title" bind:value={newPfp} style="border: 1px dotted gray; border-radius: 10px; margin-bottom: 1em; height: 2em; padding: 5px;"><br>
    <button class="connect-button" style="height: 2.2em" on:click={updatePfp}>Update PFP</button>
  {/if}
</div>
