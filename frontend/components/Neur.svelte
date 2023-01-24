<script>
    import { neurons } from '../store'
    import { useConnect, useCanister } from "@connect2ic/svelte"
    import { Principal } from "@dfinity/principal"

    const [ dao ] = useCanister("dao");
    const { principal } = useConnect({});

	export let name;
    export let neuron;
    let toAdd = 0;
    let inAction = false;

    let neuronData;

    let redeemable = false 
    $ : {
        if (Number((neuronData.dissolveStartTime[0] ? neuronData.dissolveStartTime[0] : BigInt(0))) + Number(neuronData.dissolveDelay) > (Date.now() * 1000000)) {redeemable = false} else {redeemable = true }
    }

    $: {
        if(name) { $neurons.neurons.forEach(e => {
            if (e.name == name) {
                neuronData = e;
        }})}
    }
    

    function nanoToDate(ns) {
        return new Date(ns / 1000000);
    }

    function secondsToString(seconds) {
        seconds = seconds / 1000000000;
        var numyears = Math.floor(seconds / 31536000);
        var numdays = Math.floor((seconds % 31536000) / 86400); 
        var numhours = Math.floor(((seconds % 31536000) % 86400) / 3600);
        var numminutes = Math.floor((((seconds % 31536000) % 86400) % 3600) / 60);
        var numseconds = (((seconds % 31536000) % 86400) % 3600) % 60;
        return numyears + " years " +  numdays + " days " + numhours + " hours " + numminutes + " minutes " + Math.floor(numseconds) + " seconds";
    }

    const updateNeurons = async () => {
        let getNeurons = await $dao.getAllNeurons([Principal.fromText($principal)]);
        console.log(getNeurons);
        if (getNeurons.ok) {
            let update = $neurons;
            update.neurons = getNeurons.ok;
            console.log("getNeurons.ok", getNeurons.ok)
            neurons.set(update);
        }
    }

    const dissolveNeuron = async () => {
        inAction = true;
        const result = await $dao.dissolveNeuron(name);
        if (result.ok) { updateNeurons(); window.alert(result.ok) }
        else if (result.err) { window.alert(result.err) };
        inAction = false;
    }

    const increaseDissolveDelay = async () => {
        inAction = true;
        const result = await $dao.increaseDissolveDelay(name, toAdd * 86400000000000);
        if (result.ok) { updateNeurons(); window.alert("dissolve delay increased!") }
        else if (result.err) { window.alert(result.err) };
        inAction = false;
    }

    const redeemNeuron = async () => {
        inAction = true;
        const result = await $dao.redeemNeuron(name);
        if (result.ok) { updateNeurons(); window.alert(result.ok) }
        else if (result.err) { window.alert(result.err) };
        inAction = false;
    }
</script>

<div style="display: flex; align-items: center; flex-direction: column;">
<div style="padding: 3em">
  <div style="display: flex; background: black; width: 90vw; min-width: 1200px; min-height: 60vh; border-radius: 9999px; align-items: center; justify-content: center; flex-direction:column;">
      <!-- <div style="color:antiquewhite; font-size:4em;">{name}</div><br><br> -->
      <img style="height: 100%;" alt="neuron" src={neuron} />  
  </div>      
</div>

<div class="card bg-primary text-primary-content mb-9" style="width: 50vw; min-width: 800px">
    <div class="card-body">
        <h2 class="card-title" style="font-size: 2.5em; color:antiquewhite">{name}</h2>
        <div><div style="color:green">owner: </div>{neuronData.owner}</div>
        <div><div style="color:green">amount: </div>{Number(neuronData.amount) / 100000000}MB</div>
        <div><div style="color:green">creation time: </div> {nanoToDate(Number(neuronData.creationTime))}</div>
        <div><div style="color:green">dissolve start time: </div> {(neuronData.dissolveStartTime[0] ? neuronData.dissolveStartTime[0] : 0) == undefined ? "has not started dissolving" : nanoToDate(Number(neuronData.dissolveStartTime))}</div>
        <div><div style="color:green">dissolve delay: </div>{secondsToString(Number(neuronData.dissolveDelay))}</div>
        <div><div style="color:green">state: </div>{neuronData.state.Locked === null ? "locked" : neuronData.state.Dissolving === null ? "dissolving" : "dissolved"}</div>
        <div><div style="color:green">time until fully disolved: </div>{BigInt((neuronData.dissolveStartTime[0] ? neuronData.dissolveStartTime[0] : BigInt(0) ) + neuronData.dissolveDelay) - BigInt(Date.now() * 1000000) > BigInt(0) ? secondsToString(Number(BigInt((neuronData.dissolveStartTime[0] ? neuronData.dissolveStartTime[0] : 0) + neuronData.dissolveDelay) - BigInt(Date.now() * 1000000))) : "none"}</div>
        <br>
        {#if !inAction}
            <div>
                <button class="btn btn-outline btn-success" on:click={dissolveNeuron}>start dissolving</button>
                <button class="btn btn-outline btn-success" on:click={increaseDissolveDelay}>increase dissolve delay (days)</button>
                <input type="number" class="input input-outline input-success" min="0" bind:value={toAdd} style="background-color: black; width: 8em">
                {#if redeemable && neuronData.state.Dissolving === null}
                <button class="btn btn-outline btn-success" on:click={redeemNeuron}>redeem neuron</button>
                {:else}
                <button class="btn btn-outline btn-error btn-disabled" style="color:firebrick">not redeemable</button>
                {/if}
            </div>
        {:else}
            <div>
                <button class="btn btn-outline btn-success btn-disabled">start dissolving</button>
                <button class="btn btn-outline btn-success btn-disabled">increase dissolve delay (days)</button>
                <input type="number" class="input input-outline input-success" min="0" bind:value={toAdd} style="background-color: black; width: 8em">
                {#if redeemable && neuronData.state.Dissolving === null}
                <button class="btn btn-outline btn-success btn-disabled">redeem neuron</button>
                {:else}
                <button class="btn btn-outline btn-error btn-disabled" style="color:firebrick">not redeemable</button>
                {/if}
            </div>
        {/if}
        <div class="card-actions justify-end">
            (⊙_◎) neurotic!
        </div>
    </div>
</div>
</div>