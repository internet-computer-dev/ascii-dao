<script>

  export let notLoading = false;
  async function wait() {
    await new Promise(resolve => setTimeout(resolve, 8800));
    notLoading = true;
  }
  wait();
  
</script>

{#if notLoading == false}
<div class="lds-facebook"><div></div><div></div><div></div></div>
{:else}
<div class="lds-facebook">Try logging into your wallet and reloading</div>
{/if}

<style>
.lds-facebook {
  position: absolute;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100vw;
  height: 100vh;
  background: rgb(255,255,255);
  background: radial-gradient(circle, rgba(255,255,255,1) 0%, rgba(240,240,240,1) 99%);
  top: 0;
  right: 0;
}
.lds-facebook div {
  position: relative;
  width: 20px;
  background: black;
  align-self: center;
  animation: lds-facebook 1.2s cubic-bezier(0, 0.5, 0.5, 1) infinite;
}
.lds-facebook div:nth-child(1) {
  left: -1em;
  animation-delay: -0.24s;
}
.lds-facebook div:nth-child(2) {
  left: 0;
  animation-delay: -0.12s;
}
.lds-facebook div:nth-child(3) {
  left: 1em;
  animation-delay: 0;
}
@keyframes lds-facebook {
  0% {
    top: 8px;
    height: 64px;
  }
  50%, 100% {
    top: 24px;
    height: 32px;
  }
}
</style>