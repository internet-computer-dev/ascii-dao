import { writable } from "svelte/store";

export const storage = writable({
    principal: null,
    username: null,
    artworks: []
});