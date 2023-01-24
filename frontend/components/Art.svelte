<script>
  import { storage } from '../store'
  import { useCanister, useConnect } from "@connect2ic/svelte"

  const { principal } = useConnect({});

  const [ dao ] = useCanister("dao")

  let checked;
  let title = '';
  let artwork = '';
  let expandText = '🠋 create a new ascii artwork 🠋';

  $ : {if (!checked) {
    expandText = "🠋 create a new ascii artwork 🠋"
  } else {expandText = "🠉 create a new ascii artwork 🠉"}}
  
  function toggle () {
    if (expandText == "🠋 create a new ascii artwork 🠋") {
      expandText = "🠉 create a new ascii artwork 🠉"
    } else {expandText = "🠋 create a new ascii artwork 🠋"}
  }

  const newArt = async () => {
    const result = await $dao.newArt(title, artwork);
    if (result.ok) {
      let art = await $dao.getArt([], []);
      console.log(art);
      if (art.ok) {
        let update = $storage;
        update.artworks = art.ok[0];
        storage.set(update);
        document.getElementById('title').value = ''
        document.getElementById('artwork').value = ''
      }
    } else if (result.err) { window.alert(result.err) }
  }

</script>

<div>
  {#if $principal}

  <div class="collapse">
    <input type="checkbox" on:click={toggle}/> 
    <div class="collapse-title text-xl font-medium">
      {expandText}
    </div>
    <div class="collapse-content"> 
      <label style="font-size: 1.18em">Title</label><br>
      <input style="margin-bottom: 1.6em; border: 1px dotted gray" id="title" bind:value={title}><br>
      <label style="font-size: 1.18em">Artwork</label><br>
      <textarea id="artwork" placeholder="maximum dimensions: 15x30" style="font-family: consolas; margin-bottom: 1em; border: 1px dotted gray; width: 25em" cols="30" rows="15" charswidth="23" bind:value={artwork}></textarea>
      <button class="connect-button" on:click={newArt}>+</button>
      <br>
    </div>
  </div>

  <div class="divider"></div>

  <!-- <h1 style="font-size: 1.5em; padding-left: 0.5em; font-family: impact; font-weight: 1;">my art gallery</h1> -->
  {#if $storage.artworks[0]}
    <kbd class="kbd kbd-lg" style="font-size: 1.2em; margin-left: 1em; font-weight: 600">--my art gallery--</kbd>
  {/if}

  <div class="grid grid-cols-3 gap-4">
  {#each $storage.artworks as art}
    <div class="mockup-code m-3 mr-7">
      <pre style="color:gray; height: 23.5em; overflow: hidden">{art.title}<br><code style="color:antiquewhite">{art.art}</code></pre>
    </div>
  {/each}
  </div>


    
  {/if}

</div>