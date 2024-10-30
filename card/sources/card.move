module 0xCAFE::card {
    use std::signer;
    use aptos_std::simple_map::{Self, SimpleMap};
    use std::vector;
    use std::string::String;

    struct State has key {
        total_cards_count: u64,
        cards_by_id: SimpleMap<u64, Card>
    }

    struct MyCard has key {
        cards: SimpleMap<address, vector<u64>>,
    }

    struct Card has store, drop {
        id: u64,
        owner: address,
        ipfs_hash: String,
    }

    fun init_module(creator: &signer){
        move_to(creator, State {
            total_cards_count: 0,
            cards_by_id: simple_map::new(),
        })
    }

    entry fun add_card(user: &signer, ipfs_hash: String) acquires State, MyCard {
        let user_addr = signer::address_of(user);
        let state = borrow_global_mut<State>(@0xCAFE);
        let counter = state.total_cards_count + 1;
        let new_card = Card {
            id: counter,
            owner: user_addr,
            ipfs_hash,
        };
        if(!exists<MyCard>(user_addr)){
            let my_card = MyCard {
                cards: simple_map::new()
            };
            move_to(user, my_card);
        };
        let my_card = borrow_global_mut<MyCard>(user_addr);
        let user_card_idx = simple_map::borrow_mut(&mut my_card.cards, &user_addr);
        vector::push_back(user_card_idx, counter);
        simple_map::upsert(&mut state.cards_by_id, counter, new_card);
        state.total_cards_count = counter;
    }
}