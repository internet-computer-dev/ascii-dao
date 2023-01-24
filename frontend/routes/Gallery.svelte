<script>
    import { proposal } from '../store'
    import { useCanister } from "@connect2ic/svelte"

    const [ dao ] = useCanister("dao");

    let refreshing = false;
    const getProposals = async () => {
        refreshing = true;
        let gallery = await $dao.getDaoGallery();
        if (gallery.ok) {
            let update = $proposal;
            console.log(gallery.ok[0])
            update.daoGallery = gallery.ok;
            proposal.set(update);
            console.log($proposal)
        }
        refreshing = false;
    };

    $ : {
        if ($proposal.daoGallery == null && !refreshing) {
            getProposals()
        }
    }
</script>

<div style="margin: 2em; width: 80%">
    <h1 style="font-size: 3em">DAO Gallery</h1>
</div>

{#if $proposal.daoGallery != null && $proposal.daoGallery[0]}
<div class="grid grid-flow-col auto-cols-max bg-base-300 rounded-box p-5">
{#each $proposal.daoGallery as art}
    <div class="card bg-base-100 shadow-xl" style="width: 27rem">
        <figure class="px-10 pt-10">
            <div class="mockup-code m-3 mb-0">
                <pre style="color:gray; height: 23.5em">{art.title}<br><code style="color:antiquewhite">{art.art}</code></pre>
            </div>
        </figure>
        <div class="card-body items-center text-center">
            <h1 class="card-title">artist: {art.artist}</h1>
        </div>
    </div>
{/each}
</div>
{/if}