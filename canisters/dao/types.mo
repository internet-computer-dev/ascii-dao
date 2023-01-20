module {

    public type Profile = {
        username: Text;
        artworks: ?[Artwork];
        pfp: ?Text;
    };

    public type Artwork = {
        title: Text;
        art: Text;
    };

    public type GalleryArtwork = {
        artist: Text;
        title: Text;
        art: Text;
    };

    public type Proposal = {
        action: Action;
        proposer: Principal;
        voters: [Principal];
        note: ?Text;
        voteTally: Int;
        artwork: GalleryArtwork;
    };

    public type Action = {
        #Add;
        #Remove;
    };

    public type Stance = {
        #Yay;
        #Nay;
    };

    public type Neuron = {
        owner: Principal;
        amount: Nat;
        creationTime: Int;
        dissolveStartTime: ?Int;
        dissolveDelay: Int;
        state: State;
    };

    public type State = {
        #Locked;
        #Dissolving;
        #Dissolved;
    };

    public type Parameters = {
        quadraticVoting: Bool;
        votingThreshold: Nat;
        tokenThreshold: Nat;
        expiration: Int;
        voters: [Text];
        voteTally: Int;
        proposer: Principal;
    };

}