```
     ___           _______.  ______  __   __      _______       ___       ______   
    /   \         /       | /      ||  | |  |    |       \     /   \     /  __  \  
   /  ^  \       |   (----`|  ,----'|  | |  |    |  .--.  |   /  ^  \   |  |  |  | 
  /  /_\  \       \   \    |  |     |  | |  |    |  |  |  |  /  /_\  \  |  |  |  | 
 /  _____  \  .----)   |   |  `----.|  | |  |    |  '--'  | /  _____  \ |  `--'  | 
/__/     \__\ |_______/     \______||__| |__|    |_______/ /__/     \__\ \______/  
                                                                                   
```

This repo was created in less than a week for the Motoko Bootcamp 2023 core project.

The ASCII DAO allows an ICP principal to create a on-chain profile that can store ASCII art to their username. It also gives the ability to set one of the artworks as a PFP.

Users can create proposals to add or remove an artwork to the public DAO gallery. Members of the ASCII DAO (anyone who meets the MB token threshold) can then vote to accept or reject the proposal. Once the voting threshold is met, the proposal will be passed.

Users can also create neurons by staking a minimum of 50MB tokens to the DAO and specifying the dissolve delay. Neurons, like user profiles, must have unique identifier names. After creating a neuron, it is possible to start dissolving it or to increase the dissolve delay. If the neuron has finished dissolving, the neuron can then be redeemed for the voting power which is calculated based on `number of MB tokens staked to neuron * dissolve delay bonus * age bonus`

Neurons with a dissolve delay of over 6 months can participate in voting to modify the token threshold and voting threshold parameters as well as vote to enable quadratic voting. Requirements for the core project can be found [here](https://github.com/motoko-bootcamp/motokobootcamp-2023/blob/main/core_project/PROJECT.MD)

Play around with the on-chain deployment at:

https://gtnjc-eaaaa-aaaai-qhmva-cai.raw.ic0.app/