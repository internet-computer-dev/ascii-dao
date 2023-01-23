import { writable } from "svelte/store";

export const storage = writable({
    principal: null,
    username: null,
    artworks: [],
    loggedIn: false,
    pfp: "\n\n\n\n\n\ \ \ \ \ \ \ \ ~ PFP not set ~\n\n\n\n\n\n\n\n\n",
    tokenBalance: 0,
});

export const proposal = writable({
    active: null,
    daoGallery: null
});