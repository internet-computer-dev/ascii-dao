<script>
    import neuron from "../assets/neuron.gif";
</script>

<h1 class="card-title width-100 mt-16 justify-center" style="font-size: 2em">Front-end NYI</h1>
<p class="card-title width-100 mt-16 justify-center"> But you can find the backend code in the github repo in the about section</p>

<!-- max 6? -->
<div style="padding: 3em">
    <div style="display: flex; background: black; width: 90vw; min-height: 100vh; border-radius: 9999px; align-items: center; justify-content: center;">
        <img style="height: 100%;" alt="neuron" src={neuron}>  
    </div>      
</div>

<!-- createNeuron( amount : Nat, dissolveDelay : Int, txReceipt : Nat, name : Text )
getAllNeurons ( owner : ?Principal )
dissolveNeuron( name : Text )
increaseDissolveDelay( name : Text, add : Int)
redeemNeuron ( name : Text )
modifyParameters ( tokenThreshold : Nat, votingThreshold : Nat, quadraticVoting : Bool )
voteOnParameters ( name : Text, stance : T.Stance )
getParameters () : async { parameters : T.Parameters; proposedParameters : T.Parameters } -->