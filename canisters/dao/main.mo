import B "../../.vessel/stablebuffer/v0.2.0/src/StableBuffer";
import RBT "../../.vessel/stablerbtree/v0.6.0/src/StableRBTree";
import Time "mo:base/Time";
import Bool "mo:base/Bool";
import N64 "mo:base/Nat64";
import I64 "mo:base/Int64";
import D "mo:base/Debug";
import R "mo:base/Result";
import P "mo:base/Principal";
import Tx "mo:base/Text";
import I "mo:base/Iter";
import A "mo:base/Array";
import F "mo:base/Float";
import T "./types";
import ICRC1 "./icrc1";

actor class AsciiDao() = this {

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
        if (RBT.get(profiles, Tx.compare, P.toText(caller)) == null){return #err("only principals with a username can create art")};

        // validate artwork size is 30 x 15 or smaller
        var lineCount = 0;
        for (line in Tx.split(art, #text "\n")) {
            if (line.size() > 30) {return #err("art cannot be wider than 30 characters")};
            lineCount += 1;
        };
        if (lineCount > 15) {return #err("art cannot be taller than 15 characters")};

        // check for duplicate art title
        let profile = switch (RBT.get(profiles, Tx.compare, P.toText(caller))){
            case (null) { return #err("artist profile not found")};
            case (?val) {val};
        };
        let art_ : [T.Artwork] = switch (profile.artworks) {
            case (null) {[]};
            case (?val) {val};
        };
        switch (A.find<T.Artwork>(art_, func x = x.title == title)) {
            case (null) {};
            case (_) { return #err("artist already has artwork with title " # title)};
        };

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
        var uTitle : Text = "";
        var uArt : [T.Artwork] = [];
        switch(title) {
            case (null) { return #ok(theArt)};
            case (?t) { uTitle := t;};
        };
        switch(theArt) {
            case (null) { return #err("user has no artworks")};
            case (?a) { uArt := a;};
        };

        // validate title exists
        let foundTitle : T.Artwork = switch (A.find<T.Artwork>(uArt, func x = x.title == uTitle)) {
            case ( null ) { return #err("title not found") };
            case ( ?found ) found
        };

        return #ok(?[foundTitle]);
        
    };

    // set pfp
    public shared ({caller}) func setPfp( title : Text ) : async R.Result<Text, Text> {
        if (RBT.get(profiles, Tx.compare, P.toText(caller)) == null){return #err("user not found")};

        // validate user
        let user : T.Profile = switch (RBT.get(profiles, Tx.compare, P.toText(caller))) {
            case ( null ) { return #err("user not found") };
            case ( ?found ) found
        };

        // unwrap art
        let uArt : [T.Artwork] = switch(user.artworks) {
            case ( null ) { return #err("no artworks found") };
            case ( ?found ) found
        };

        // validate title exists
        let pfpTitle : ?Text = switch (A.find<T.Artwork>(uArt, func x = x.title == title)) {
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
    var proposals = B.init<T.Proposal>();
    let archivedProposals = B.init<T.Proposal>();
    var daoGallery = B.init<T.GalleryArtwork>();

    // submit a proposal
    public shared ({caller}) func submitProposal( action : T.Action, artist : Text, title : Text, note : ?Text ) : async R.Result<Text, Text> {

        if (RBT.get(profiles, Tx.compare, P.toText(caller)) == null){return #err("only principals with a username can submit proposals")};

        let principal : Text = switch(await getPrincipal(artist)){
            case (#err(_)) { return #err("artist not found")};
            case (#ok(p)) { p }
        };

        let art : ?[T.Artwork] = switch(await getArt(?title, ?principal)){
            case (#err(_)) { return #err("artwork not found")};
            case (#ok(a)) { a }
        };

        let uArt : T.Artwork = switch (art) {
            case (null) { return #err("art is empty")};
            case (?val) { val[0] }
        };

        // check to see proposal does not already exist
        for (proposal in B.vals(proposals)) {
            if (proposal.artwork == {artist = artist; title = title; art = uArt.art;}) { 
                return #err("artwork already under proposal") 
            };
        };

        // check to see if artwork is or isnt already in the gallery
        switch (action) {
            case (#Add) {
                for (i in B.vals(daoGallery)) {
                    if (i == { artist = artist; title = title; art = uArt.art; }) {
                        return #err("artwork already in dao gallery")
                }}};
            case (#Remove) {
                var match = false;
                for (i in B.vals(daoGallery)) { // how do you break a for loop?
                    if (i == { artist = artist; title = title; art = uArt.art; }) {
                        match := true;
                    }
                };
                if (match == false) { return #err("artwork is not in dao gallery") };
            };
        };

        // create the proposal
        B.add<T.Proposal>(proposals, {action = action; proposer = caller; voters = []; note = note; voteTally = 0; artwork = {artist = artist; title = title; art = uArt.art;}});

        return(#ok("proposal created"))
    };

    // get proposal on specific artwork
    public func getProposals ( artwork : T.GalleryArtwork ) : async R.Result<T.Proposal, Text> {
        for (proposal in B.vals(proposals)) {
            if (proposal.artwork == artwork) {
                return #ok(proposal)
            };
        };
        return #err("no proposal found")
    };

    // get all proposals. if principal specified, gets all proposals of only that principal
    public func getAllProposals ( proposer : ?Principal ) : async R.Result<[T.Proposal], Text> {
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

    // get all archived proposals. if principal specified, gets all archived proposals of only that principal
    public func getArchivedProposals ( proposer : ?Principal ) : async R.Result<[T.Proposal], Text> {
        switch (proposer) {
            case (null) { // get all proposals
                return #ok(B.toArray(archivedProposals));
            };
            case (?p) {
                let userArchivedProposals = B.init<T.Proposal>();
                for (proposal in B.vals(archivedProposals)) {
                    if (proposal.proposer == p) {
                        B.add(userArchivedProposals, proposal);
                    };
                };
                return #ok(B.toArray(userArchivedProposals));
            };
        };
    };

    // get all artworks in dao gallery
    public func getDaoGallery () : async R.Result<[T.GalleryArtwork], Text> {
        return #ok(B.toArray(daoGallery));
    };

    // vote on a proposal
    public shared ({caller}) func vote ( artwork : T.GalleryArtwork, stance : T.Stance ) : async R.Result<Text, Text> {
        if (RBT.get(profiles, Tx.compare, P.toText(caller)) == null){return #err("only principals with a username can vote")};
        
        // find index of proposal in buffer
        var index = 0;
        var proposalIndex : ?Nat = null;
        for (proposal in B.vals(proposals)) {
            if (proposal.artwork == artwork) {
                proposalIndex := ?index;
            };
            index += 1;
        };
        var uProposalIndex = 0;
        switch (proposalIndex) {
            case (null) {return #err("artwork proposal not found")};
            case (?val) { uProposalIndex := val };};

        // check to see if caller already voted
        var p : T.Proposal = B.get(proposals, uProposalIndex);
        var pCopy : T.Proposal = B.get(proposals, uProposalIndex);
        if ((A.find<Principal>(p.voters, func x = x == caller)) != null) {return #err("user has already voted on this proposal")};

        // check to see if caller has enough mb tokens
        let balance = await getMBBalance(caller);
        if (balance <= parameters.tokenThreshold) {return #err("not enough mb tokens to vote")};

        // update proposal voteTally and voters
        switch (stance) {
            case (#Yay) { 
                p := {action = p.action; proposer = p.proposer; voters = A.append(p.voters, [caller]); note = p.note; artwork = p.artwork; voteTally = (p.voteTally + balance)};
            }; 
            case (#Nay) {  
                p := {action = p.action; proposer = p.proposer; voters = A.append(p.voters, [caller]); note = p.note; artwork = p.artwork; voteTally = (p.voteTally - balance)};
            };  
        };

        // process proposal action
        if (p.voteTally >= parameters.votingThreshold) {
            // add/remove artwork from dao gallery
            switch (p.action) {
                case (#Add) {
                    B.add(daoGallery, p.artwork)};
                case (#Remove) {
                    var dgArray = B.toArray(daoGallery);
                    dgArray := A.filter<T.GalleryArtwork>(dgArray, func x = x != p.artwork);
                    daoGallery := B.fromArray(dgArray);
                };
            };
            // delete from proposals
            var pArray = B.toArray(proposals);
            pArray := A.filter<T.Proposal>(pArray, func x = x != pCopy);
            proposals := B.fromArray(pArray);
            // add to proposal archives
            B.add(archivedProposals, p);
            return #ok("vote placed and proposal passed");
        } else if (p.voteTally <= -parameters.votingThreshold) {
            // delete from proposals
            var pArray = B.toArray(proposals);
            pArray := A.filter<T.Proposal>(pArray, func x = x != pCopy);
            proposals := B.fromArray(pArray);
            // add to proposal archives
            B.add(archivedProposals, p);
            return #ok("vote placed and proposal rejected");
        } else {
            // update proposal
            B.put(proposals, uProposalIndex, p);
            return #ok("vote has been placed");
        };
    };

    // NYI like/dislike gallery art and sort by most liked
    
    // .__   __.  _______  __    __  .______        ______   .__   __.      _______.
    // |  \ |  | |   ____||  |  |  | |   _  \      /  __  \  |  \ |  |     /       |
    // |   \|  | |  |__   |  |  |  | |  |_)  |    |  |  |  | |   \|  |    |   (----`
    // |  . `  | |   __|  |  |  |  | |      /     |  |  |  | |  . `  |     \   \    
    // |  |\   | |  |____ |  `--'  | |  |\  \----.|  `--'  | |  |\   | .----)   |   
    // |__| \__| |_______| \______/  | _| `._____| \______/  |__| \__| |_______/                                                                           

    // rbtree of neurons
    var neurons = RBT.init<Text, T.Neuron>();
    var neuronsArchive = RBT.init<Text, T.Neuron>();

    // createNeuron - minimum 50 MB tokens
    public shared ({caller}) func createNeuron( amount : Nat, dissolveDelay : Int, txReceipt : Nat, name : Text ) : async R.Result<Text, Text> {
        if (amount < 50_010_000_00) {
            return #err("minimum amount to create a neuron is 50MB")
        };
        // check if tx was already used
        if (A.find<Nat>(usedTxs, func x = x == txReceipt) != null) {return #err("transaction receipt has already been used")};
        // check duplicate neuron name
        if ((RBT.get(neurons, Tx.compare, name)) != null) { return #err("neuron name is already taken") };
        if ((RBT.get(neuronsArchive, Tx.compare, name)) != null) { return #err("neuron name has already been used") };

        // get tx receipt
        let tx = switch(await mbCanister.get_transaction(txReceipt)){
            case (null) {return #err("transaction receipt not found")};
            case (?val) { val };
        };
        // validate tx
        if (tx.kind != "TRANSFER") {return #err("not a transfer")};
        let transferDetails = switch (tx.transfer) {
            case (null) {return #err("no transfer details")};
            case (?val) { val };
        };
        if (transferDetails.to.owner != P.fromActor(this)) {return #err("transaction receipt not sent to" # P.toText(P.fromActor(this)))};
        if (transferDetails.from.owner != caller) {return #err("transaction receipt not sent from caller principal: " # P.toText(caller))};
        if (transferDetails.amount != amount) {return #err("transaction receipt amount does not match provided amount")};

        // create neuron
        neurons := RBT.put(neurons, Tx.compare, name, {
            owner = caller;
            amount = amount;
            creationTime = Time.now();
            dissolveStartTime = null;
            dissolveDelay = dissolveDelay;
            state = #Locked;
        });

        // mark tx as used
        usedTxs := A.append<Nat>(usedTxs, [txReceipt]);

        return #ok("neuron \"" # name # "\" has been created");
    };

    // get neuron by name
    public func getNeurons ( name : Text ) : async R.Result<T.Neuron, Text> {        
        switch (RBT.get(neurons, Tx.compare, name)) {
            case (null) { return #err("neuron not found") };
            case (?val) { return #ok(val)};
        };
    };

    // get all neurons. if principal specified, gets all neurons of only that principal
    public func getAllNeurons ( owner : ?Principal ) : async R.Result<[T.Neuron], Text> {
        let allNeurons = B.initPresized<T.Neuron>(RBT.size(neurons));

        for ((k,v) in RBT.iter(neurons, #fwd)) {
            B.add(allNeurons, v);
        };

        switch (owner) {
            case (null) {return #ok(B.toArray(allNeurons))};
            case (?val) {
                var arr = B.toArray(allNeurons);
                arr := A.filter<T.Neuron>(arr, func x = x.owner == val);
                return #ok(arr)
            };
        };
    };

    // get all archived neurons. if principal specified, gets all neurons of only that principal
    public func getAllArchivedNeurons ( owner : ?Principal ) : async R.Result<[T.Neuron], Text> {
        let allArchivedNeurons = B.initPresized<T.Neuron>(RBT.size(neuronsArchive));

        for ((k,v) in RBT.iter(neuronsArchive, #fwd)) {
            B.add(allArchivedNeurons, v);
        };

        switch (owner) {
            case (null) {return #ok(B.toArray(allArchivedNeurons))};
            case (?val) {
                var arr = B.toArray(allArchivedNeurons);
                arr := A.filter<T.Neuron>(arr, func x = x.owner == val);
                return #ok(arr)
            };
        };
    };

    // starts dissolving neuron
    public shared ({caller}) func dissolveNeuron( name : Text ) : async R.Result<Text, Text> {
        // get neuron
        let n = switch (RBT.get(neurons, Tx.compare, name)) {
            case (null) { return #err("neuron not found") };
            case (?val) { val };
        };

        // make sure caller is owner
        if (n.owner != caller) {return #err("not your neuron!")};

        // make sure neuron is in locked state
        switch (n.state) {
            case (#Locked) {};
            case (#Dissolving) {return #err("neuron is already dissolving")};
            case (#Dissolved) {return #err("neuron is already dissolved")};
        };

        let newDissolveStartTime = ?Time.now();
        // update neuron state and dissolve start time
        neurons := (RBT.update<Text, T.Neuron>(neurons, Tx.compare, name, func (update : ?T.Neuron) : T.Neuron {
            switch (update) {
                case ( null ) { return {owner = P.fromText("aaaaa-aa"); amount = 0; creationTime = 0; dissolveStartTime = null; dissolveDelay = 0; state = #Locked;}};
                case ( ?val ) { return {
                    owner = val.owner;
                    amount = val.amount;
                    creationTime = val.creationTime;
                    dissolveStartTime = newDissolveStartTime;
                    dissolveDelay = val.dissolveDelay;
                    state = #Dissolving;
        };};};})).1;


        return #ok("neuron " # name # " has started dissolving");
    };

    // increase dissolve delay
    public shared ({caller}) func increaseDissolveDelay( name : Text, add : Int) : async R.Result<Int, Text> {
        // get neuron
        let n = switch (RBT.get(neurons, Tx.compare, name)) {
            case (null) { return #err("neuron not found") };
            case (?val) { val };
        };

        // make sure caller is owner
        if (n.owner != caller) {return #err("not your neuron!")};

        // make sure neuron is in Locked or Dissolving state
        switch (n.state) {
            case (#Locked or #Dissolving) {};
            case (#Dissolved) {return #err("neuron is already dissolved")};
        };

        let newDissolveDelay = n.dissolveDelay + add;
        // update neuron dissolveDelay
        neurons := (RBT.update<Text, T.Neuron>(neurons, Tx.compare, name, func (update : ?T.Neuron) : T.Neuron {
            switch (update) {
                case ( null ) { return {owner = P.fromText("aaaaa-aa"); amount = 0; creationTime = 0; dissolveStartTime = null; dissolveDelay = 0; state = #Locked;}};
                case ( ?val ) { return {
                    owner = val.owner;
                    amount = val.amount;
                    creationTime = val.creationTime;
                    dissolveStartTime = val.dissolveStartTime;
                    dissolveDelay = newDissolveDelay;
                    state = val.state;
        };};};})).1;

        return #ok(newDissolveDelay);
    };

    // redeemNeuron
    public shared ({caller}) func redeemNeuron ( name : Text ) : async R.Result<Text, Text> {
        // get neuron
        let n = switch (RBT.get(neurons, Tx.compare, name)) {
            case (null) { return #err("neuron not found") };
            case (?val) { val };
        };

        // make sure caller is owner
        if (n.owner != caller) {return #err("not your neuron!")};

        // assert neuron not locked
        if (n.state == #Locked) {return #err("neuron is still locked")};
        // check to see that proper time has passed
        let startTime = switch (n.dissolveStartTime) {case null return #err("no dissolve start time"); case (?val) val};
        if (Time.now() - startTime <= n.dissolveDelay) {
            return #err("neuron has not finished dissolving");
        };

        // get amount based on voting power
        let amount : Nat = await calculateVotingPower(n.amount, n.dissolveDelay, n.creationTime);
        // attempt to return MB tokens + interest
        let txResult = await mbCanister.icrc1_transfer({
            to = { owner = caller; subaccount = null };
            fee = ?1000000;
            memo = null;
            from_subaccount = null;
            created_at_time = ?N64.fromIntWrap(Time.now());
            amount = amount;
        });
        
        // handle tx error messages
        switch (txResult) {
            case (#ok(_)) {};
            case (#err(e)) {
                switch (e) {
                    case (#GenericError(g)) { return #err(g.message) };
                    case (#TemporarilyUnavailable(_)) { return #err("TemporarilyUnavailable") };
                    case (#BadBurn(_)) { return #err("BadBurn") };
                    case (#Duplicate(_)) { return #err("Duplicate") };
                    case (#BadFee(_)) { return #err("BadFee") };
                    case (#CreatedInFuture(_)) { return #err("CreatedInFuture") };
                    case (#TooOld(_)) { return #err("TooOld") };
                    case (#InsufficientFunds(_)) { return #err("you got FTXed! canister balance too low to redeem accured interest on neuron because the canister doesn't actually control the supply of MB tokens. congrats degen!") };
                };
            };
        };

        // delete neuron
        neurons := RBT.delete(neurons, Tx.compare, name);

        // update state to dissolved and archive neuron
        let updatedNeuron = {
            owner = n.owner;
            amount = n.amount;
            creationTime = n.creationTime;
            dissolveStartTime = n.dissolveStartTime;
            dissolveDelay = n.dissolveDelay;
            state = #Dissolved;
        };
        neuronsArchive := RBT.put(neuronsArchive, Tx.compare, name, updatedNeuron);

        return #ok("neuron has been redeemed 🎉");
    };

    // calculate voting power of neuron
    private func calculateVotingPower(amount : Nat, dissolveDelay : Int, creationTime: Int) : async Nat {
        var dissolveDelayBonus : Float = 1;
        if (dissolveDelay >= 252460800000000000) { //96 months
            dissolveDelayBonus := 2;
        } else if (dissolveDelay >= 15778800000000000) { //6 months
            let dMonths : Int = dissolveDelay / 2629800000000000;
            dissolveDelayBonus := F.fromInt(dMonths) * 0.01044444 + 0.99733333;
        };
        var creationTimeBonus = 1.25;
        let age : Int = Time.now() - creationTime;
        if (age < 126230400000000000) { //48 months
            let aMonths : Int = age / 2629800000000000;
            creationTimeBonus := F.fromInt(aMonths) * 0.00625 + 1;
        };
        // 🙀
        return amount * N64.toNat(I64.toNat64(F.toInt64(dissolveDelayBonus)))  * N64.toNat(I64.toNat64(F.toInt64(creationTimeBonus)));
    };

    // create a proposal to modify parameters. only 1 active proposal at a time
    public shared ({caller}) func modifyParameters ( tokenThreshold : Nat, votingThreshold : Nat, quadraticVoting : Bool ) : async R.Result<T.Parameters, Text> {
        // check for active proposal
        if (proposedParameters.expiration > Time.now()) { return #err("only 1 active proposal at a time")};

        // make sure proposer has a neuron with at least 6 months desolve delay
        let n : [T.Neuron] = switch(await getAllNeurons(?caller)) {
            case (#ok(val)) {val};
            case (#err(err)) {return #err(err)};
        };
        switch (A.find<T.Neuron>(n, func x = x.dissolveDelay >= 15778800000000000)) {
            case (null) { return #err("user does not have any neurons with 6 months+ dissolve delay")};
            case (_) {};
        };

        // check token threshold is between 1 and 100
        if (tokenThreshold < 1_000_000_00 or tokenThreshold > 100_000_000_00) { return #err("token threshold must be between 1 and 100 MB")};

        // check voting threshold is between 100 and 1000
        if (votingThreshold < 100_000_000_00 or votingThreshold > 1_000_000_000_00) { return #err("voting threshold must be between 100 and 1000 MB")};

        // add data to proposed parameters
        proposedParameters := {
            tokenThreshold  = tokenThreshold;
            votingThreshold = votingThreshold;
            quadraticVoting = false;
            expiration = Time.now() + 86_400_000_000_000;
            voters = [];
            voteTally = 0;
            proposer = caller;
        };

        return #ok(proposedParameters);
    };
    
    // vote on parameter updates from neuron
    public shared ({caller}) func voteOnParameters ( name : Text, stance : T.Stance ) : async R.Result<Text, Text> {
        // get neuron
        let n = switch (RBT.get(neurons, Tx.compare, name)) {
            case (null) { return #err("neuron not found") };
            case (?val) { val };
        };

        // make sure caller is owner
        if (n.owner != caller) {return #err("not your neuron!")};

        // verify proposal isnt expired
        if (proposedParameters.expiration < Time.now()) { return #err("proposal has already expired")};

        // neuron needs at least 6 months dissolve delay
        if (n.dissolveDelay < 15778800000000000) { return #err("neuron dissolve delay is less than 6 months") };

        // verify neuron has not already voted
        switch (A.find<Text>(proposedParameters.voters, func x = x == name)) {
            case (null) {};
            case (_) { return #err("neuron has already voted") };
        };

        // calculate vote weight based on whether quadratic voting is activated or not
        var votingPower = 0;
        switch (parameters.quadraticVoting) {
            case (true) {
                let qAmount : Nat = N64.toNat(I64.toNat64(F.toInt64(F.sqrt(F.fromInt64(I64.fromNat64(N64.fromNat(n.amount)))))));
                votingPower := await calculateVotingPower(qAmount, n.dissolveDelay, n.creationTime);
            };
            case (false) {
                votingPower := await calculateVotingPower(n.amount, n.dissolveDelay, n.creationTime);
            };
        };

        // update vote tally and voters array
        let newVotersArray = A.append<Text>(proposedParameters.voters, [name]);
        switch (stance) {
            case (#Yay) { proposedParameters := {
                quadraticVoting = proposedParameters.quadraticVoting;
                votingThreshold = proposedParameters.votingThreshold;
                tokenThreshold = proposedParameters.tokenThreshold;
                expiration = proposedParameters.expiration;
                voters = newVotersArray;
                voteTally = proposedParameters.voteTally + votingPower;
                proposer = proposedParameters.proposer;
            }};
            case (#Nay) {proposedParameters := {
                quadraticVoting = proposedParameters.quadraticVoting;
                votingThreshold = proposedParameters.votingThreshold;
                tokenThreshold = proposedParameters.tokenThreshold;
                expiration = proposedParameters.expiration;
                voters = newVotersArray;
                voteTally = proposedParameters.voteTally - votingPower;
                proposer = proposedParameters.proposer;
            }};
        };

        // if threshold passed in either direction, take action
        if (proposedParameters.voteTally >= parameters.votingThreshold) {
            // update parameters
            parameters := proposedParameters;
            // refresh proposed parameters
            proposedParameters := {
                tokenThreshold  =   1_000_000_00;
                votingThreshold = 100_000_000_00;
                quadraticVoting = false;
                expiration = 0;
                voters = [];
                voteTally = 0;
                proposer = P.fromText("aaaaa-aa");
            };
            return (#ok("proposal has passed and new parameters have been set"));    
        } else if (proposedParameters.voteTally <= -parameters.votingThreshold) {
            // refresh proposed parameters
            proposedParameters := {
                tokenThreshold  =   1_000_000_00;
                votingThreshold = 100_000_000_00;
                quadraticVoting = false;
                expiration = 0;
                voters = [];
                voteTally = 0;
                proposer = P.fromText("aaaaa-aa");
            };
            return (#ok("proposal has rejected"));
        };

        return #ok("neuron " # name # " has voted on parameter proposal");
    };

    // returns current parameters and proposed parameters
    public func getParameters () : async { parameters : T.Parameters; proposedParameters : T.Parameters } {
        {parameters = parameters; proposedParameters = proposedParameters}
    };

    // returns if quadratic voting is set to true or false
    public func quadraticVoting () : async Bool {
        parameters.quadraticVoting
    };
     
    // .___________.  ______    __  ___  _______ .__   __.      _______.
    // |           | /  __  \  |  |/  / |   ____||  \ |  |     /       |
    // `---|  |----`|  |  |  | |  '  /  |  |__   |   \|  |    |   (----`
    //     |  |     |  |  |  | |    <   |   __|  |  . `  |     \   \    
    //     |  |     |  `--'  | |  .  \  |  |____ |  |\   | .----)   |   
    //     |__|      \______/  |__|\__\ |_______||__| \__| |_______/    

    stable var parameters : T.Parameters = {
        tokenThreshold  =   1_000_000_00; // number of tokens needed to vote
        votingThreshold = 100_000_000_00; // number of votes needed to pass proposal
        quadraticVoting = false;
        expiration = 0;
        voters = [];
        voteTally = 0;
        proposer = P.fromText("aaaaa-aa");
    };
    stable var proposedParameters : T.Parameters = {
        tokenThreshold  =   1_000_000_00;
        votingThreshold = 100_000_000_00;
        quadraticVoting = false;
        expiration = 0;
        voters = [];
        voteTally = 0;
        proposer = P.fromText("aaaaa-aa");
    };
    
    // MB token canister actor
    stable let mbCanister = ICRC1.getMBCanister();
    // Tx receipts already used to create a neuron
    stable var usedTxs : [Nat] = [];


    public query func getThresholds() : async {tokenThreshold: Nat; votingThreshold: Nat} {
        {tokenThreshold = parameters.tokenThreshold; votingThreshold = parameters.votingThreshold}
    };

    func getMBBalance ( p : Principal ) : async Nat {
        return await mbCanister.icrc1_balance_of({owner=p; subaccount=null});
    };

    func meetsTokenThreshold ( p : Principal ) : async Bool {
        if ((await getMBBalance(p)) >= parameters.tokenThreshold) { return true};
        return false;
    };

    //   WHO AM I????? WHAT TIME IS IT?????
    //
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
        P.toText(caller)
    };

    public func timeNow () : async Int {
        Time.now()
    };
};
