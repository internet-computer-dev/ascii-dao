import B "../../.vessel/stablebuffer/v0.2.0/src/StableBuffer";
import RBT "../../.vessel/stablerbtree/v0.6.0/src/StableRBTree";
import P "mo:base/Principal";
import Tx "mo:base/Text";
import A "mo:base/Array";
import R "mo:base/Result";
import T "./types";
import Principal "mo:base/Principal";

actor {

    // .______   .______        ______    _______  __   __       _______      _______.
    // |   _  \  |   _  \      /  __  \  |   ____||  | |  |     |   ____|    /       |
    // |  |_)  | |  |_)  |    |  |  |  | |  |__   |  | |  |     |  |__      |   (----`
    // |   ___/  |      /     |  |  |  | |   __|  |  | |  |     |   __|      \   \    
    // |  |      |  |\  \----.|  `--'  | |  |     |  | |  `----.|  |____ .----)   |   
    // | _|      | _| `._____| \______/  |__|     |__| |_______||_______||_______/    

    // rbtree of user profiles
    var profiles = RBT.init<Text, T.Profile>();

    // create a new user
    public shared ({caller}) func newUser( username: Text ) : async R.Result<Text, Text> {

        // check to see if username has already been set
        let inUse : Bool = switch (RBT.get(profiles, Tx.compare, P.toText(caller))) {
            case (null) false;
            case (_) true;
        };
        if(inUse) { return #err("username has already been set") };

        // check to see if username is already taken
        for ((k,v) in RBT.iter(profiles, #fwd)) {
            if(v.username == username) {return #err("username is already taken")}
        };

        // add profile to profiles
        profiles := RBT.put(profiles, Tx.compare, P.toText(caller), {username = username; artworks = null; pfp = null});

        return #ok(P.toText(caller) # " username set to: " # username);
    };

    // add a new ascii artwork
    public shared ({caller}) func newArt( title: Text, art: Text ) : async R.Result<Text, Text> {

        // update profile with new artwork
        profiles := (RBT.update<Text, T.Profile>(profiles, Tx.compare, P.toText(caller), func (update : ?T.Profile) : T.Profile {
            switch (update) {
                case ( null ) { return {username = ""; artworks = null; pfp = null} };
                case ( ?val ) { return {username = val.username; pfp = val.pfp ; artworks = ?(
                    switch(val.artworks) {
                        case (null) { [{title = title; art = art}] };
                        case (?artworks) { A.append<T.Artwork>(artworks, [{title = title; art = art}]) };
        })}};};})).1;

        return #ok("artwork has been added")
    };

    // get all user profile data
    public shared ({caller}) func getProfileData() : async R.Result<T.Profile, Text> {
        
        if (P.isAnonymous(caller)) { return #err("anonymous") };

        switch (RBT.get(profiles, Tx.compare, P.toText(caller))) {
            case ( null ) { return #err("user not found") };
            case ( ?user ) { return #ok(user) };
        };

    };

    // get username from principal. if null, gets caller username
    public shared ({caller}) func getUsername( principal : ?Text ) : async R.Result<Text, Text> {
        
        if (P.isAnonymous(caller)) { return #err("anonymous") };

        switch(principal) {
            case (null) {
                switch (RBT.get(profiles, Tx.compare, P.toText(caller))) {
                    case ( null ) { return #err("user not found") };
                    case ( ?user ) { return #ok(user.username) };
                };
            };
            case (?p) {
                switch (RBT.get(profiles, Tx.compare, p)) {
                    case ( null ) { return #err("user not found") };
                    case ( ?user ) { return #ok(user.username) };
                };
            };
        };

    };

    // get principal from username
    public shared func getPrincipal( username : Text ) : async R.Result<Text, Text> {
        
        for ((k,v) in RBT.iter(profiles, #fwd)) {
            if (v.username == username) { return #ok(k); };
        };

        return #err("principal could not be located");

    };

    // get single artwork or all my artworks if null. specify principal or leave null if caller
    public shared ({caller}) func getArt( title: ?Text, principal: ?Text ) : async R.Result<?[T.Artwork], Text> {

        // get art of principal entered or caller
        var theArt : ?[T.Artwork] = null;
        switch(principal) {
            case (null) {
                theArt := switch (RBT.get(profiles, Tx.compare, P.toText(caller))) {
                    case ( null ) { return #err("user not found") };
                    case ( ?user ) user.artworks
                };
            };
            case (?p) {
                theArt := switch (RBT.get(profiles, Tx.compare, p)) {
                    case ( null ) { return #err("user not found") };
                    case ( ?user ) user.artworks
                };
            };
        };

        // unwrap values
        var unwrappedTitle : Text = "";
        var unwrappedArt : [T.Artwork] = [];
        switch(title) {
            case (null) { return #ok(theArt)};
            case (?t) { unwrappedTitle := t;};
        };
        switch(theArt) {
            case (null) { return #err("user has no artworks")};
            case (?a) { unwrappedArt := a;};
        };

        // validate title exists
        let foundTitle : T.Artwork = switch (A.find<T.Artwork>(unwrappedArt, func x = x.title == unwrappedTitle)) {
            case ( null ) { return #err("title not found") };
            case ( ?found ) found
        };

        return #ok(?[foundTitle]);
        
    };

    // set pfp
    public shared ({caller}) func setPfp( title : Text ) : async R.Result<Text, Text> {

        // validate user
        let user : T.Profile = switch (RBT.get(profiles, Tx.compare, P.toText(caller))) {
            case ( null ) { return #err("user not found") };
            case ( ?found ) found
        };

        // unwrap art
        let unwrappedArt : [T.Artwork] = switch(user.artworks) {
            case ( null ) { return #err("no artworks found") };
            case ( ?found ) found
        };

        // validate title exists
        let pfpTitle : ?Text = switch (A.find<T.Artwork>(unwrappedArt, func x = x.title == title)) {
            case ( null ) { return #err("artwork not found") };
            case ( ?found ) ?found.title
        };
        
        // update profile with new artwork
        profiles := (RBT.update<Text, T.Profile>(profiles, Tx.compare, P.toText(caller), func (update : ?T.Profile) : T.Profile {
            switch (update) {
                case ( null ) { return {username = ""; artworks = null; pfp = null} };
                case ( ?val ) { return {username = val.username; artworks = val.artworks; pfp = pfpTitle;
        }};};})).1;

        return(#ok("PFP set to " # title))
    };


    // NYI remove artwork, remove user, change username etc.

    
    // .______   .______        ______   .______     ______        _______.     ___       __           _______.
    // |   _  \  |   _  \      /  __  \  |   _  \   /  __  \      /       |    /   \     |  |         /       |
    // |  |_)  | |  |_)  |    |  |  |  | |  |_)  | |  |  |  |    |   (----`   /  ^  \    |  |        |   (----`
    // |   ___/  |      /     |  |  |  | |   ___/  |  |  |  |     \   \      /  /_\  \   |  |         \   \    
    // |  |      |  |\  \----.|  `--'  | |  |      |  `--'  | .----)   |    /  _____  \  |  `----..----)   |   
    // | _|      | _| `._____| \______/  | _|       \______/  |_______/    /__/     \__\ |_______||_______/    

    // buffer of proposals and gallery artworks
    let proposals = B.init<T.Proposal>();
    let archivedProposals = B.init<T.Proposal>();
    let daoGallery = B.init<T.GalleryArtwork>();

    // submit a proposal
    public shared ({caller}) func submitProposal( action : T.Action, artist : Text, title : Text, note : ?Text ) : async R.Result<Text, Text> {

        let principal : Text = switch(await getPrincipal(artist)){
            case (#err(_)) { return #err("artist not found")};
            case (#ok(p)) { p }
        };

        let art : ?[T.Artwork] = switch(await getArt(?title, ?principal)){
            case (#err(_)) { return #err("artwork not found")};
            case (#ok(a)) { a }
        };

        let unwrappedArt : T.Artwork = switch (art) {
            case (null) { return #err("art is empty")};
            case (?val) { val[0] }
        };

        // check to see proposal does not already exist
        for (proposal in B.vals(proposals)) {
            if (proposal.artwork == {artist = artist; title = title; art = unwrappedArt.art;}) { 
                return #err("artwork already under proposal") 
            };
        };

        // check to see if artwork is or isnt already in the gallery
        switch (action) {
            case (#Add) {
                for (i in B.vals(daoGallery)) {
                    if (i == { artist = artist; title = title; art = unwrappedArt.art; }) {
                        return #err("artwork already in dao gallery")
                }}};
            case (#Remove) {
                var match = false;
                for (i in B.vals(daoGallery)) { // how do you break a for loop?
                    if (i == { artist = artist; title = title; art = unwrappedArt.art; }) {
                        match := true;
                    }
                };
                if (match == false) { return #err("artwork is not in dao gallery") };
            };
        };

        // create the proposal
        B.add<T.Proposal>(proposals, {action = action; proposer = caller; note = note; artwork = {artist = artist; title = title; art = unwrappedArt.art;}});

        return(#ok("proposal created"))
    };

    // get proposal on specific artwork
    public shared ({caller}) func getProposal ( artwork : T.GalleryArtwork ) : async R.Result<T.Proposal, Text> {
        for (proposal in B.vals(proposals)) {
            if (proposal.artwork == artwork) {
                return #ok(proposal)
            };
        };
        return #err("no proposal found")
    };

    // get all proposals. if principal specified, gets all proposals of only that principal
    public shared ({caller}) func getAllProposal ( proposer : ?Principal ) : async R.Result<[T.Proposal], Text> {
        switch (proposer) {
            case (null) { // get all proposals
                return #ok(B.toArray(proposals));
            };
            case (?p) {
                let userProposals = B.init<T.Proposal>();
                for (proposal in B.vals(proposals)) {
                    if (proposal.proposer == p) {
                        B.add(userProposals, proposal);
                    };
                };
                return #ok(B.toArray(userProposals));
            };
        };
    };

    // vote


    // modify_parameters
    // quadratic_voting
    // createNeuron
    // dissolveNeuron 




    // WHO AM I?????

    //⠀⠀⠀⠀⠀⠀⠠⢀⠀⠀⣠⣴⡶⣖⣶⣰⣶⣶⣶⣦⣄⡀⠠⠄⠀⠀⠀⠀⠀
    //⠀⠀⠀⠀⠀⠀⡀⠀⣴⣾⣿⣿⣽⣻⢶⣻⣿⣿⣿⣿⣿⣿⣄⠂⠀⠀⠀⠀⠀
    //⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⡭⣟⣿⣿⣿⣿⣿⣿⣿⣿⣇⠀⠀⠀⠀⠀
    //⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⢧⣛⣿⣿⣿⠿⠿⣿⣿⣿⣿⠀⠀⠀⠀⠀
    //⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣛⡞⡬⢿⣿⣿⣹⣿⣿⣿⣷⣲⡆⠀⠀⠀⠀
    //⠀⠀⠀⠀⠀⢸⣿⣿⣻⢿⡽⣚⢧⡛⣜⡹⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀
    //⠀⠀⠀⠀⠀⢸⣛⠶⣙⢮⠳⣍⠶⡑⢎⡵⣻⣿⡿⣿⣿⣿⣿⢯⠁⠀⠀⠀⠀
    //⠀⠀⠀⠀⠀⠈⣎⠳⣉⢎⠱⡈⢆⡑⢪⢔⣻⣯⣿⣿⣑⣶⣿⡋⠀⠀⠀⠀⠀
    //⠀⠀⠀⠀⠀⠀⢱⣙⠲⣌⠡⠐⠀⠌⢂⠎⡼⣳⣿⣭⣙⣥⡿⠁⠀⠀⠀⠀⠀
    //⠀⠀⠀⠀⠀⢀⠀⣎⠷⣜⢢⠀⢂⠀⠀⠈⠰⢡⠻⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀
    //⠀⠀⠀⠀⠀⠀⢀⢸⣻⣝⢮⢆⡱⢂⡄⢀⠀⠐⠌⠙⠛⠃⠀⠀⠀⠀⠀⠀⠀
    //⠀⠀⠀⠀⠀⠀⢠⣼⢣⡟⡞⣦⢱⢫⡜⠂⠀⢰⢠⠀⠀⠀⠀⡄⠀⠀⠀⠀⠀
    //⠀⠀⠀⠀⠀⠐⠂⣸⣯⣿⣽⣎⡷⣎⠵⡊⣴⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    //⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣯⣗⣽⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    //⠀⠀⠀⠀⠀⠀⠄⢛⠛⠋⢛⠙⠛⠿⠿⠿⠿⠛⠉⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀
    //⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

    public shared ({caller}) func whoami() : async Text {
        return P.toText(caller);
    };
};
