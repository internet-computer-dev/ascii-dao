<script>
    import { parameters, neurons } from '../store'
    import { fade } from 'svelte/transition';
    import { useCanister } from "@connect2ic/svelte"

    const [ dao ] = useCanister("dao");
    let checked = false;
    let newTokenThreshold = 1;
    let newVotingThreshold = 100;
    let neuronToVote = "";

    function nanoToDate(ns) {
        return new Date(ns / 1000000);
    }

    const updateParameters = async () => {
        let getParameters = await $dao.getParameters();
        let update = $parameters;
        update = getParameters;
        update.updated = true;
        parameters.set(update);
        console.log($parameters);
    }

    let inAction = false;
    const createProposal = async () => {
        inAction = true;
        const result = await $dao.modifyParameters(newTokenThreshold * 100000000, newVotingThreshold * 100000000, checked);
        if (result.ok) { updateParameters(); window.alert("proposal created") }
        else if (result.err) { window.alert(result.err) };
        inAction = false;
    }

    const voteOnParameters = async (stance) => {
        inAction = true;
        stance = stance == "yay" ? {Yay:null} : {Nay:null};
        const result = await $dao.voteOnParameters(neuronToVote, stance);
        if (result.ok) { updateParameters(); window.alert(result.ok) }
        else if (result.err) { window.alert(result.err) };
        inAction = false;
    }

    updateParameters()

</script>

<div class="flex flex-col w-full border-opacity-50">
<div class="divider" style="font-size: 3rem; padding: 3rem">voting</div>
<div class="flex w-full">
  <div class="card w-96 bg-base-300 shadow-xl" style="width: 100vw">
      <div class="card-body items-center text-center">
        {#if $parameters.updated == false}
        <p in:fade="{{ duration: 3500 }}">Loading . . .</p>
        {:else}
        <div class="flex flex-row gap-9">
          <div>
            <h2 class="font-bold text-xl">current patameters</h2>
            <p>token threshold: {Number($parameters.parameters.tokenThreshold) / 100000000}MB</p>
            <p>voting threshold: {Number($parameters.parameters.votingThreshold) / 100000000}MB</p>
            <p>quadratic voting: {$parameters.parameters.quadraticVoting}</p>
          </div>
          <br>
          {#if Number($parameters.proposedParameters.expiration) > Date.now() * 1000000}
          <div>
            <h2 class="font-bold text-xl">proposed patameters</h2>
            <p>token threshold: {Number($parameters.proposedParameters.tokenThreshold) / 100000000}MB</p>
            <p>voting threshold: {Number($parameters.proposedParameters.votingThreshold) / 100000000}MB</p>
            <p>quadratic voting: {$parameters.proposedParameters.quadraticVoting}</p>
            <div class="divider"></div>
            <p>expires: {nanoToDate(Number($parameters.proposedParameters.expiration))}</p>
            <p>proposer: {($parameters.proposedParameters.proposer)}</p>
            <p>number of voters: {$parameters.proposedParameters.voters.length}</p>
            <p>vote tally: {Number($parameters.proposedParameters.voteTally) / 100000000}</p><br>
            <div>
                <progress class="progress w-60 progress-error" style="transform: rotate(180deg); color: firebrick;" value="{Number($parameters.proposedParameters.voteTally) / 100000000 < 0 ? Math.abs(Number($parameters.proposedParameters.voteTally) / 100000000) : 0}" max="{Number($parameters.proposedParameters.votingThreshold) / 100000000}"></progress>
                <progress class="progress w-60 progress-success" value="{Number($parameters.proposedParameters.voteTally) / 100000000 > 0 ? Number($parameters.proposedParameters.voteTally) / 100000000 : 0}" max="{Number($parameters.proposedParameters.votingThreshold) / 100000000}"></progress>
            </div><br>
            <div class="divider"></div>
            <p class="mt-4">
            <select class="select select-primary w-full max-w-xs" bind:value={neuronToVote}>
                {#if $neurons.neurons != null}
                {#if $neurons.neurons.length == 0}
                    <option disabled selected>user has no neurons</option>
                {:else}
                    <option disabled selected>Neuron to vote with</option>
                    {#each $neurons.neurons as n}
                    <option>{n.name}</option> 
                    {/each}
                {/if}
                {:else}
                    <li>loading . . .</li>
                {/if}
            </select>
            </p>
            {#if !inAction}
            <button on:click={() => voteOnParameters("nay")} class="btn btn-primary">vote against</button>
            <button on:click={() => voteOnParameters("yay")} class="btn btn-primary mt-4">vote for</button>
            {:else}
            <button class="btn btn-primary btn-disabled">vote against</button>
            <button class="btn btn-primary btn-disabled mt-4">vote for</button>
            {/if}  
          </div>
          {:else}
          <div>
            <h2 class="font-bold text-xl">no active proposal</h2>
            <div>
            <label>qudratic voting</label>
            {#if checked}
            <input type="radio" name="radio-1" class="radio" style="transform: translate(0,9px)" checked on:click={() => {checked = !checked}} />
            {:else}
            <input type="radio" name="radio-1" class="radio" style="transform: translate(0,9px)" on:click={() => {checked = !checked}} />
            {/if}
            </div>
            <p style="margin-top: 0.8em">new token threshold (1~100)</p>
            <input type="number" class="input input-outline" min="1" max="100" bind:value={newTokenThreshold} style="width: 8em; height: 2em; margin-bottom: 10px; border: 1px dotted gray">
            <p style="margin-top: 0.5em">new token threshold (100~1000)</p>
            <input type="number" class="input input-outline" min="100" max="1000" bind:value={newVotingThreshold} style="width: 8em; height: 2em; margin-bottom: 10px; border: 1px dotted gray">
            {#if !inAction}
            <button class="connect-button h-9 ml-10" on:click={createProposal}>create proposal</button>
            {:else}
            <button class="connect-button h-9 ml-10 btn-disabled">create proposal</button>
            {/if}
          </div>  
          {/if}
        </div>
        {/if}
      </div>
   </div>       
</div>
</div>