<script>
    import { neurons } from '../store'
    import { Principal } from "@dfinity/principal"
    import { useConnect, useCanister } from "@connect2ic/svelte"

    const [ dao ] = useCanister("dao");
    const [ tokens ] = useCanister("tokens");
    const { principal } = useConnect({});

    let nAmount = 50;
    let neuronName = "";
    let dissolveDelay = 0;

    let creating = false;
    const createNeuron = async () => {
        creating = true;
        const getNeuron = $dao.getNeurons(neuronName);
        if(getNeuron.err){
            window.alert("neuron name is already taken")
        } else {
        if (nAmount >= 50) {
            let transfer = await $tokens.icrc1_transfer(
                {to : { 
                    owner: Principal.fromText("gtnjc-eaaaa-aaaai-qhmva-cai"),
                    subaccount: [],
                }, 
                fee: [1000000],
                memo: [],
                from_subaccount: [],
                created_at_time: [],
                amount: nAmount * 100000000},
            )
            console.log("transfer", transfer)
            if (transfer.err) {
                const errorString = JSON.stringify(transfer.err, (key, value) =>
                    typeof value === "bigint" ? (Number(value) / 100000000).toString() : value
                );
                window.alert(errorString);
                
            } else if (transfer.ok) { 
                let txReceipt = Number(transfer.ok);
                const result = await $dao.createNeuron( nAmount * 100000000, (dissolveDelay * 86400000000000), txReceipt, neuronName);
                if (result.ok) {
                    let ns = await $dao.getAllNeurons([Principal.fromText($principal)]);
                    console.log(ns);
                    if (ns.ok) {
                        let update = $neurons;
                        update.neurons = ns.ok;
                        neurons.set(update);
                        window.alert("neuron " + neuronName + " has been created")
                        document.getElementById('neuronName').value = ''
                    }
                } else if (result.err) { window.alert(result.err) }
            }
        } else { window.alert("stake must be greater than 50!") }}
        creating = false;
    };
</script>

<div class="m-9" style="min-width: 1450px">
<label class="mt-9">neuron name</label>
<input type="text" id="neuronName" placeholder="choosea unique neuron name" class="input input-bordered input-success w-full max-w-xs mt-9" bind:value={neuronName}/>

<label class="mt-9">dissolve delay (in days)</label>
<input type="number" class="input input-bordered input-success mt-9" min="0" bind:value={dissolveDelay}>

<label class="mt-9">amount to stake (minimum: 50)</label>
<input type="number" class="input input-bordered input-success mt-9" min="50" bind:value={nAmount}>

{#if !creating}
    <button class="btn btn-outline btn-success mt-9" on:click={createNeuron}>create</button>
{:else}
    <button class="btn btn-outline btn-success btn-disabled mt-9">create</button><br>
    <progress class="progress w-100 p-3 mt-9"></progress>
{/if}
</div>