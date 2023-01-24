<script>
    import { neurons } from '../store'

    import Loader from "../components/Loader.svelte"
    import Create from "../components/Create.svelte"
    import NotConnected from "../components/NotConnected.svelte"
    import Proposal from "../components/NeuronProposal.svelte"

    import { Principal } from "@dfinity/principal"
    import { useConnect, useCanister } from "@connect2ic/svelte"

    import neuron from "../assets/neuron.gif";
    import Neur from '../components/Neur.svelte';

    const [ dao ] = useCanister("dao");
    const { status, isConnected, principal } = useConnect({});

    let tab = "create";
    function updateTab (t) {tab=t};
    let neuronsCopy;

    let gettingNeurondata = false;
    const getNeuronData = async () => {
        while (await $dao.whoami() == "2vxsx-fae") {
            await new Promise(resolve => setTimeout(resolve, 1000));
        }
        gettingNeurondata = true;
        if ($principal != null) {
            let getNeurons = await $dao.getAllNeurons([Principal.fromText($principal)]);
            console.log(getNeurons);
            if (getNeurons.ok) {
                let update = $neurons;
                update.neurons = getNeurons.ok;
                console.log("getNeurons.ok", getNeurons.ok)
                neurons.set(update);
            }
        }
        neuronsCopy = $neurons.neurons;
        gettingNeurondata = false;
    };

    $ : {
        if ($neurons.neurons == null){
            if (($neurons.neurons == null) && !gettingNeurondata) {
                getNeuronData()
            };
        };
    }

</script>


{#if $status == "initializing"}
  <Loader />
{/if}

{#if !$isConnected}
    <NotConnected page={"neurons"}/>
{:else}

<!-- preload image to optimize loading -->
<img style="height: 100%; display: none" alt="neuron" src={neuron} />

<div class="navbar bg-base-300 rounded-box">
    <div class="text-lg font-bold" style="font-size: 3em; margin: 0.7em; margin-right: 0em">neurons</div>
    <div class="flex-1 px-2 lg:flex-none">
       <pre style="font-size: 6.5px; line-height: 6.5px; font-family: consolas; text-align: left; letter-spacing: -1px; margin: 1em 0em">        ⠀⠀⠀⠀⠀⠀⠀⣀⣤⣤⣴⣶⣦⣤⣶⠶⠶⢶⣶⣤⣄⠀⠀⠀⠀⠀⠀⠀
        ⠀⠀⠀⠀⣠⣴⢟⣫⣿⣄⠀⠈⢳⣄⠈⠛⠳⣿⡁⠈⠙⣻⣆⠀⠀⠀⠀⠀
        ⠀⠀⣴⠟⣩⡀⢹⣍⠉⠙⢧⡀⣸⠟⠻⣦⠀⠛⠛⠓⠀⠉⠛⠳⣦⠀⠀⠀
        ⠀⣼⡏⠀⢿⣅⠀⠙⣷⣤⣤⠻⣿⠀⠈⢃⣤⡶⠶⢦⣄⣀⣾⠀⠹⣷⠀⠀
        ⠀⣽⣧⣄⣀⣿⠀⠠⡟⠈⠀⢀⣹⣷⣶⣿⡁⠀⠀⠀⠹⡯⠀⠀⠀⣿⡄⠀
        ⢰⣿⠀⢹⡏⠁⠀⣠⣤⣤⣴⡏⠁⠀⢀⡈⠁⠀⠀⣷⠀⠴⢶⣶⣞⠙⣿⠀
        ⠀⢿⣆⠘⠃⢠⣾⠋⠀⢀⠈⠙⠀⠀⠈⣷⣤⣤⣼⣏⣀⣠⣤⣄⡙⠁⣿⡇
        ⠀⠀⠙⠷⢶⣾⣇⠀⠀⣹⡷⢦⣤⣶⠾⠻⣿⠁⠀⠈⠿⠉⠀⠈⠷⢀⣿⠁
        ⠀⠀⠀⠀⠀⠈⢻⣦⣀⣙⢀⣀⣿⣇⣀⠀⢙⣀⣤⣴⣾⠟⠶⣤⣴⠾⠃⠀
        ⠀⠀⠀⠀⠀⠀⠀⠈⠙⠛⠛⠛⠉⠉⠻⣿⡉⠻⣷⣌⡙⢻⣶⠟⠁⠀⠀⠀
        ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠻⠷⠾⠿⠛⠁⠀⠀⠀⠀⠀</pre>
    </div>
    <div class="flex justify-end flex-1 px-2">
      <div class="flex items-stretch">
        <a class="btn btn-ghost rounded-btn card-title" on:click={() => {updateTab("create")}}>create</a>
        <a class="btn btn-ghost rounded-btn card-title" on:click={() => {updateTab("proposal")}}>proposals</a>
        <div class="dropdown dropdown-end">
          <label tabindex="0" class="btn btn-ghost rounded-btn card-title">my neurons</label>
          <ul tabindex="0" class="menu dropdown-content p-2 shadow bg-base-100 rounded-box w-52 mt-4">
            {#if $neurons.neurons != null}
                {#if $neurons.neurons.length == 0}
                    <li>user has no neurons</li>
                {:else}
                {#each $neurons.neurons as n}
                    <li><a on:click={() => {updateTab("my-" + n.name);}}>{n.name}</a></li> 
                {/each}
                {/if}
            {:else}
                <li>loading</li>
            {/if}
          </ul>
        </div>
      </div>
    </div>
  </div>
  {#if tab == "create"}
    <Create />
  {:else if tab == "proposal"}
    <Proposal />
  {:else}
    <Neur name={tab.slice(3)} neuron={neuron}/>
  {/if}
{/if}