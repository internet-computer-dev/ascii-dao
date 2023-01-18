<script lang="ts">
  import Loader from "./Loader.svelte"
  import { useCanister, useConnect } from "@connect2ic/svelte"

  const { status, principal } = useConnect({});

  let username
  const [dao, { loading }] = useCanister("dao")

  const getUser = async () => {
    const newArtname = await $dao.getUser()
    username = newArtname
  }

  // $: {
  //   if (!$loading && $dao) {
  //     getUser()
  //   }
  // }

  const newArt = async () => {
    const nu = await $dao.newArt(title, artwork);
    console.log(nu);
  }

  const getArt = async () => {
    let aw = await ($dao.getArt());
    console.log(aw);
    if (aw.ok) {
      artworks = aw.ok[0];
    }
  }

  let title = '';
  let artwork = ''
	let artworks = [];

</script>

<div>
  {#if $principal}

  <div class="collapse">
    <input type="checkbox" /> 
    <div class="collapse-title text-xl font-medium">
      🠋 create a new ascii artwork 🠋
    </div>
    <div class="collapse-content"> 
      <label>Title</label><br>
      <input bind:value={title}><br>
      <label>Artwork</label><br>
      <textarea style="font-family: consolas; margin: 2em 0" cols="40" rows="10" charswidth="23" bind:value={artwork}></textarea>
      <button class="connect-button" on:click={newArt}>+</button>
      <br>
    </div>
  </div>

  <div class="divider"></div>

  <button class="connect-button" on:click={getArt}>refresh my beautiful art</button>

  <div class="grid grid-cols-3 gap-4">
  {#each artworks as art}
    <div class="mockup-code m-3">
      <pre style="color:gray">{art.title}<br><code style="color:white">{art.art}</code></pre>
    </div>
  {/each}
  </div>


    
  {/if}

</div>
