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
        note: ?Text;
        artwork: GalleryArtwork;
    };

    public type Action = {
        #Add;
        #Remove;
    };

}