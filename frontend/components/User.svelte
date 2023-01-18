<script lang="ts">
  import { get } from 'svelte/store'
  import { storage } from '../store'

  import Loader from "./Loader.svelte"
  import { useCanister, useConnect } from "@connect2ic/svelte"

  let name
  let pfp =
`                    
                    
                    
                    
                    
                    
  PFP NOT SET         
                    
                    
                    
                    
                    
`

  const [dao, { loading }] = useCanister("dao")
  const { status, principal } = useConnect({});

  // const getUsername = async () => {
  //   const newUsername = await $dao.getUsername()
  //   username = newUsername
  // }

  // $: {
  //   if (!$loading && $dao) {
  //     getUsername()
  //   }
  // }

  const newUser = async () => {
    const nu = await $dao.newUser(name);
    console.log(nu);
    let update = get(storage);
    update.username = await $dao.getUsername([]);
    console.log("update.username", update.username)
    if (update.username.ok) {
      update.username = update.username.ok;
      console.log("update1", update)
      storage.set(update);
    }
  }

  const updatePfp = async () => {
    console.log("NYI");
  }

</script>

{#if $status == "initializing"}
  <Loader />
{/if}

<div class="example">
  {#if $storage.username == null || $storage.username.err == "anonymous"}
    <p>Loading . . .</p>
  {:else if $principal && $storage.username.err == "user not found"}
    <label style="font-weight: bold; font-size: 2em">create new user:</label>
    <input type="text" placeholder="username" class="input input-bordered w-full max-w-xs mt-6 mb-6" bind:value={name}>
    <button class="connect-button" on:click={newUser}>+</button>
  {:else if $principal && $storage.username}
    <p style="font-size: 2.5em;">{$storage.username}</p>
    <p style="font-size: 1em;">Token Balance: {0}MB</p>
    <pre style="border: 1px dotted gray; margin: 1.5em 0"></pre>
    <div class="mockup-code m-3">
      <pre style="color:gray"><br><code style="color:white">{pfp}</code></pre>
    </div>
    <button class="connect-button" on:click={updatePfp}>Update PFP</button>
  {/if}
</div>
