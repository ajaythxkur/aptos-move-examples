module my_addr::Voting {
    use std::signer;    
    use std::vector;
    use std::simple_map::{Self, SimpleMap};

    struct CandidateList has key {
        candidate_list: SimpleMap<address, u64>, // address corresponding to no. of votes
        c_list: vector<address>, // for looping while declaring winner
        winner: address,
    }

    struct VotingList has key {
        voters: SimpleMap<address, u64>
    }

    // NOT OWNER
    const ENOT_OWNER: u64 = 0;
    // ALREADY INITIALIZED
    const EALREADY_INITALIZED: u64 = 1;
    // NOT INITIALIZED
    const ENOT_INITIALIZED: u64 = 3;
    // WINNER ALREADY DECLARED
    const EWINNER_ALREADY_DECLARED: u64 = 4;
    // ALREADY VOTED
    const EALREADY_VOTED: u64 = 5;

    // ASSERTS
    public fun assert_is_owner(addr: address) {
        assert!(addr == @my_addr, ENOT_OWNER);
    }
    public fun assert_is_uninitialized(addr: address) {
        assert!(!exists<CandidateList>(addr), EALREADY_INITALIZED);
        assert!(!exists<VotingList>(addr), EALREADY_INITALIZED);
    }
    public fun assert_is_initialized(addr: address) {
        assert!(exists<CandidateList>(addr), ENOT_INITIALIZED);
        assert!(exists<VotingList>(addr), ENOT_INITIALIZED);
    }
    public fun assert_winner_not_declared(store_addr: address) acquires CandidateList {
        assert!(borrow_global<CandidateList>(store_addr).winner == @0x0, EWINNER_ALREADY_DECLARED);
    }
    public fun assert_not_voted(store_addr: address, voter_addr: address) acquires VotingList {
        assert!(!simple_map::contains_key(&borrow_global<VotingList>(store_addr).voters, &voter_addr), EALREADY_VOTED)
    }

    public entry fun initialize_with_candidate(account: &signer, c_addr: address) acquires CandidateList {
        let addr = signer::address_of(account);
        assert_is_owner(addr);
        assert_is_uninitialized(addr);
        move_to(account, CandidateList {
            candidate_list: simple_map::create(),
            c_list: vector::empty<address>(),
            winner: @0x0, // none
        });
        move_to(account, VotingList{
            voters: simple_map::create()
        });

        let c_store = borrow_global_mut<CandidateList>(addr);
        simple_map::add(&mut c_store.candidate_list, c_addr, 0);
        vector::push_back(&mut c_store.c_list, c_addr);
    }

    public entry fun add_candidate(account: &signer, c_addr: address) acquires CandidateList {
        let addr = signer::address_of(account);
        assert_is_owner(addr);
        assert_is_initialized(addr);
        let c_store = borrow_global_mut<CandidateList>(addr);
        simple_map::add(&mut c_store.candidate_list, c_addr, 0);
        vector::push_back(&mut c_store.c_list, c_addr);
    }

    public entry fun vote(account: &signer, c_addr: address, store_addr: address) acquires CandidateList, VotingList {
        assert_is_initialized(store_addr);
        let addr = signer::address_of(account);
        assert_winner_not_declared(store_addr); 
        assert_not_voted(store_addr, addr);

        let c_store = borrow_global_mut<CandidateList>(store_addr);
        let v_store = borrow_global_mut<VotingList>(store_addr);

        let votes = simple_map::borrow_mut(&mut c_store.candidate_list, &c_addr);
        *votes = *votes + 1;
        simple_map::add(&mut v_store.voters, addr, 1);
    }

    public entry fun declare_winner(account: &signer) acquires CandidateList {
        let addr = signer::address_of(account);
        assert_is_owner(addr);
        assert_is_initialized(addr);
        assert_winner_not_declared(addr);

        let c_store = borrow_global_mut<CandidateList>(addr);

        let i = 0;
        let winner: address = @0x0;
        let max_votes: u64 = 0;
        while(i < vector::length(&c_store.c_list)){
            let candidate = *vector::borrow(&c_store.c_list, (i as u64));
            let votes = simple_map::borrow(&c_store.candidate_list, &candidate);
            if(*votes > max_votes){
                max_votes = *votes;
                winner = candidate;
            };
            i = i + 1;
        };
        c_store.winner = winner;
    }
    
} 