dfx identity use degen
DGN=$(dfx identity get-principal)
# expect - #ok()
dfx canister call dao newUser '("degen")'

# expect - username has already been taken
dfx canister call dao newUser '("change")'
dfx identity use default
DFT=$(dfx identity get-principal)
# expect - username is already taken
dfx canister call dao newUser '("degen")'
# expect - only principals with a username can create art
dfx canister call dao newArt '("my art", "0-x-0-x-x-0-x\nx-0-x-x-0-x-0")'
# expect - user not found
dfx canister call dao getProfileData
# expect - user not found
dfx canister call dao getUsername
# expect - degen
dfx canister call dao getUsername "(opt \"$DGN\")"
# expect - user not found
dfx canister call dao getUsername "(opt \"$DFT\")"
# expect - user not found
dfx canister call dao getUsername
# expect - principal could not be located
dfx canister call dao getPrincipal '("someone")'
# expect - same principal as $DGN variable
dfx canister call dao getPrincipal '("degen")'
# expect - user not found
dfx canister call dao setPfp '("random")'
# expect - only principals with a username can submit proposals
dfx canister call dao submitProposal '(variant {Add}, "degen", "degenerate", opt "good art!")'
# expect - #ok()
dfx canister call dao newUser '("default")'
# expect - artwork has been added
dfx canister call dao newArt '("my art", "0-x-0-x-x-0-x\nx-0-x-x-0-x-0")'

dfx identity use degen
# expect - artwork has been added
dfx canister call dao newArt '("degenerate", "d-e-g-e-n-0-x\n0-d-e-g-e-n")'
# expect - record { art = "d-e-g-e-n-0-x\n0-d-e-g-e-n"; title = "degenerate" };
dfx canister call dao getArt "(opt \"degenerate\", opt \"$DGN\")"
# expect - user not found
dfx canister call dao getArt "(opt \"degenerate\", opt \"$DFT\")"
# expect - artwork not found
dfx canister call dao setPfp '("random")'
# expect - PFP set to degenerate
dfx canister call dao setPfp '("degenerate")'
# expect - artwork has been added
dfx canister call dao newArt '("improved art", "oooooooo\nxxxxxxxxx\noooooooo")'
# expect - PFP set to improved art
dfx canister call dao setPfp '("improved art")'
# expect -
#  pfp = opt "improved art";
#       username = "degen";
#       artworks = opt vec {
#         record { art = "d-e-g-e-n-0-x\n0-d-e-g-e-n"; title = "degenerate" };
#         record {
#           art = "oooooooo\nxxxxxxxxx\noooooooo";
#           title = "improved art";
#         };
dfx canister call dao getProfileData
# expect - proposal created
dfx canister call dao submitProposal '(variant {Add}, "degen", "degenerate", opt "good art!")'
# expect - artwork already under proposal
dfx canister call dao submitProposal '(variant {Remove}, "degen", "degenerate", opt "good art!")'
# expect - artwork is not in dao gallery
dfx canister call dao submitProposal '(variant {Remove}, "degen", "improved art", opt "improved art!")'
# expect - to see the proposal there
dfx canister call dao getAllProposals
# expect - same as above
dfx canister call dao getAllProposals "(opt principal \"$DGN\")"

# Doesn't work locally because no route to MB canister...
dfx canister call dao vote '(record { art = "d-e-g-e-n-0-x\n0-d-e-g-e-n"; title = "degenerate"; artist = "degen"; }, variant {Yay})'