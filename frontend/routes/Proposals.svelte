<script>
    import { proposal, parameters } from '../store'
    import { useCanister, useConnect } from "@connect2ic/svelte"

    import NotConnected from "../components/NotConnected.svelte"

    const [ dao ] = useCanister("dao")
    const { isConnected } = useConnect({});

    let artist = "";
    let title = "";
    let note = "";
    let action = "";

    let processing = false
    let submitting = false

    const vote = async (artist, title, art, stance) => {
        processing = true
        let callstance = stance == "yay" ? {Yay:null} : {Nay:null};
        const result = await $dao.vote( { artist: artist, title: title, art: art}, callstance );
        console.log("vote result: ", result)
        if (result.ok) {
            let proposals = await $dao.getAllProposals([]);
            console.log(proposals);
            if (proposals.ok) {
                let update = $proposal;
                update.active = proposals.ok;
                proposal.set(update);
            }
        } else if (result.err) { window.alert(result.err) }
        processing = false;
        let gallery = await $dao.getDaoGallery();
        if (gallery.ok) {
            let update = $proposal;
            console.log(gallery.ok[0])
            update.daoGallery = gallery.ok;
            proposal.set(update);
        }
    };

    const submitProposal = async () => {
        submitting = true
        let callAction = action == "add" ? {Add:null} : {Remove:null};
        let callNote = note == "" ? [] : [note];
        const result = await $dao.submitProposal( callAction, artist, title, callNote );
        if (result.ok) {
            let proposals = await $dao.getAllProposals([]);
            console.log(proposals);
            if (proposals.ok) {
                let update = $proposal;
                update.active = proposals.ok;
                proposal.set(update);
                document.getElementById('artist').value = ''
                document.getElementById('title').value = ''
                document.getElementById('note').value = ''
            }
        } else if (result.err) { window.alert(result.err) }
        submitting = false
    }

    let refreshing = false;
    const getProposals = async () => {
        refreshing = true;
        let proposals = await $dao.getAllProposals([]);
        if (proposals.ok) {
            let update = $proposal;
            console.log(proposals.ok[0])
            update.active = proposals.ok;
            proposal.set(update);
            console.log($proposal)
        }
        refreshing = false;
    };

    const updateParameters = async () => {
        let getParameters = await $dao.getParameters();
        let update = $parameters;
        update = getParameters;
        update.updated = true;
        parameters.set(update);
        console.log($parameters);
    }

    $ : {
        if ($proposal.active == null && !refreshing) {
            getProposals()
            updateParameters()
        }
    }

</script>

{#if !$isConnected}
    <NotConnected page={"proposals"}/>
{:else}

<div style="margin: 2em; width: 80%">
    <h1 style="font-size: 3em">Proposals</h1>
</div>

<!-- needs to log in -->
<div class="flex flex-col w-full border-opacity-50" style="min-width: 1500px">
    <div class="p-6 bg-base-300 rounded-box" style="min-width: 1800px">
        <label style="font-weight: bold">new gallery proposal</label>
        <select class="select select-bordered w-full max-w-xs" bind:value={action}>
            <option disabled selected>action</option>
            <option>add</option>
            <option>remove</option>
        </select>
        <input type="text" id="artist" placeholder="artist" class="input input-bordered input-success w-full max-w-xs" bind:value={artist}/>
        <input type="text" id="title" placeholder="art title" class="input input-bordered input-success w-full max-w-xs" bind:value={title} />
        <input type="text" id="note" placeholder="note" class="input input-bordered input-success w-full max-w-xs" bind:value={note}/>
        {#if !submitting}
        <button class="btn btn-outline btn-success" on:click={submitProposal}>submit</button>
        {:else}
        <button class="btn btn-outline btn-success btn-disabled">submit</button>
        {/if}
    </div>
    <div class="divider" style="font-size: 1.5em; margin: 1em;">ACTIVE PROPOSALS</div>
    <div class="grid grid-cols-4 auto-rows-max bg-base-300 rounded-box p-5 gap-10" style="min-width: 1800px">
        {#if $proposal.active != null && $proposal.active[0]}
        {#each $proposal.active as p}
            <div class="card bg-base-100 shadow-xl" style="width: 27rem">
                <figure class="px-10 pt-10">
                    <div class="mockup-code m-3 mb-0">
                        <pre style="color:gray; height: 23.5em; overflow:hidden">{p.artwork.title}<br><code style="color:antiquewhite">{p.artwork.art}</code></pre>
                    </div>
                </figure>
                <div class="card-body items-center text-center">
                    <h1 class="card-title">creator: {p.artwork.artist}</h1>
                    <div>
                    proposal: {p.action.Add === null ? "add to gallery" : "remove from gallery"}<br>
                    <!-- principal: {p.proposer}<br> -->
                    note: {p.note.length == 0 ? "none" : p.note[0]}<br>
                    number of voters: {p.voters.length}<br>
                    votes needed to pass: {Number($parameters.parameters.votingThreshold) / 100000000}MB<br>
                    tokens needed to vote: {Number($parameters.parameters.tokenThreshold) / 100000000}MB<br>
                    vote tally: {Number(p.voteTally) / 100000000}<br>
                        <div>
                            <progress class="progress w-20 progress-error" style="transform: rotate(180deg); color: firebrick;" value="{Number(p.voteTally) / 100000000 < 0 ? Math.abs(Number(p.voteTally) / 100000000) : 0}" max="{Number($parameters.parameters.votingThreshold) / 100000000}"></progress>
                            <progress class="progress w-20 progress-success" value="{Number(p.voteTally) / 100000000 > 0 ? Number(p.voteTally) / 100000000 : 0}" max="{Number($parameters.parameters.votingThreshold) / 100000000}"></progress>
                        </div><br>
                    <b style="font-size: 1.3em">vote:</b>
                    </div>
                    <div>
                        {#if !processing}
                        <button on:click={() => vote(p.artwork.artist, p.artwork.title, p.artwork.art, "nay")} class="btn btn-primary">nay</button>
                        <button on:click={() => vote(p.artwork.artist, p.artwork.title, p.artwork.art, "yay")} class="btn btn-primary">yay</button>
                        {:else}
                        <button class="btn btn-primary btn-disabled">nay</button>
                        <button class="btn btn-primary btn-disabled">yay</button>
                        {/if}              
                    </div>
                </div>
            </div>
        {/each}
        {:else if $proposal.active == null}
        <div class="flex flex-center" style="grid-column: 1 / -1">
            <progress class="progress w-50"></progress>
        </div>
        {:else}
        <p>no proposals found</p>
        {/if}
    </div>
</div>

{/if}