<script lang="ts">
  import { get } from 'svelte/store'
  import { storage } from '../store'

  import { useConnect, useCanister } from "@connect2ic/svelte"
  import "@connect2ic/core/style.css"

  import Loader from "../components/Loader.svelte"
  import User from "../components/User.svelte"
  import Art from "../components/Art.svelte"

  const [dao, {loading}] = useCanister("dao")
  
  const { status, isConnected, principal } = useConnect({});

  export const setData = async () => {
    let update = get(storage);
    update.username = await $dao.getUsername([]);
    console.log("update.username", update.username)
    if (update.username.ok) {
      update.username = update.username.ok;
      console.log("update1", update)
      storage.set(update);
    }
    setPrincipal();
  }

  const setPrincipal = async () => {
    console.log("setPrincipal")
    let update = get(storage);
    update.principal = $principal.toString();
    console.log("update2", update)
    storage.set(update);
  }

  // set data
  $ : {
    if ($dao && !$loading && ($principal != get(storage).principal)) {
      setData();
    }
  }

</script>

<h1>storage: {JSON.stringify($storage)}</h1>

{#if $status == "initializing"}
  <Loader />
{/if}

{#if !$isConnected}
    <pre style="text-align: center; margin: 5em 1em 1em 1em">
           ,#%%%%%%%%%%%(                             /(((((((((((#.            
      #%%%%%%%%%%%%%%%%%%%%*                   *(((((((((((((((((####(        
 ./%%%%%%%%%%%%%%%%%%%%%%%%%%%%,           ,((((((((((((((((((##########*     
#&%%&&@@@@@@@#(((//#%%%%%%%%%%%%%/.     .*((((((((((((((*****/#########%%%(,  
#&&@@@@@@@%*          ./%%%%%%%%%%%%#* ,(((((((((((((*           ,####%%%%%%%/ 
&&@@@@@@@(.                ,#%%%%%%%%%%%#(((((((((/.                ./%%%%&&&&% 
@@@@@@@@@*                    /%%%%%%%%%%%#(((((,                     ,&&&&&&@@@
@@@@@@&&.                       .%%%%%%%%%%%#(                        ,&&&@@@@@@
@@@@&&&&,                      .(((#%%%%%%%%%%%%,                     ,&@@@@@@@@
@&&&&&&%%,                   *(((((((#%%%%%%%%%%%%(                  /@@@@@@@@&%
#&&&%%%%%%/.              ,((((((((((((/%%%%%%%%%%%%%,             ,%@@@@@@@&&% 
*#%%%%%####(,,       ./((((((((((((/.   *#%%%%%%%%%%%%%(**    .//&@@@@@@@&&%(  
 .(%############(((((((((((((((((,        ./%%%%%%%%%%%%%%%%&&&&&&&&&&%%%%/.   
    ,#########((((((((((((((((/.              .(%%%%%%%%%%%%%%%%%%%%%%%%,      
      . /##(((((((((((((((#,                      ,%%%%%%%%%%%%%%%%%/          
    </pre>
    <h2 class="font-mono" style="width: 100%; text-align: center; margin: 4em 0; left: 0">please connect your wallet (in the upper right) to view your profile</h2>
{:else}
    <div class="flex justify-center">
      <div class="flex justify-center w-1/3 p-10">
          <User />
      </div>
      <div class="divider divider-horizontal"></div>
      <div class="flex justify-center w-2/3 p-10">
        <Art />
      </div>
    </div>
{/if}