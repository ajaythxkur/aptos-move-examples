module card_addr::FootballCard {
    use std::signer;

    struct FootballStar has key {
        name: vector<u8>,
        country: vector<u8>,
        position: u8,
        value: u64
    }

    // STAR ALREADY EXISTS
    const ESTAR_ALREADY_EXISTS: u64 = 0;
    // STAR DOESNT EXIST
    const ESTAR_DOESNT_EXIST: u64 = 1;

    public fun new_star(
        name: vector<u8>,
        country: vector<u8>,
        position: u8
    ): FootballStar {
        FootballStar {
            name,
            country,
            position,
            value: 0
        }
    }

    public fun mint(to: &signer, star: FootballStar) {
        let addr = signer::address_of(to);
        assert!(!card_exists(addr), ESTAR_ALREADY_EXISTS);
        move_to<FootballStar>(to, star);
    }

    public fun get(owner: &signer): (vector<u8>, u64) acquires FootballStar {
        let addr = signer::address_of(owner);
        assert!(card_exists(addr), ESTAR_DOESNT_EXIST);
        let star = borrow_global<FootballStar>(addr);
        (star.name, star.value)
    }

    public fun card_exists(addr: address): bool {
        exists<FootballStar>(addr)
    }

    public fun set_price(owner: &signer, price: u64) acquires FootballStar {
        let addr = signer::address_of(owner);
        assert!(card_exists(addr), ESTAR_DOESNT_EXIST);
        let star = borrow_global_mut<FootballStar>(addr);
        star.value = price;
    }

    public fun transfer(from: &signer, to: &signer) acquires FootballStar {
        let from_addr = signer::address_of(from);
        let to_addr = signer::address_of(to);
        assert!(card_exists(from_addr), ESTAR_DOESNT_EXIST);
        let star = move_from<FootballStar>(from_addr);
        move_to(to, star);
        assert!(card_exists(to_addr), 100);
    }

    #[test(alice=@card_addr, bob=@0x234)]
    public fun testing(alice: &signer, bob: &signer) acquires FootballStar {
        let alice_addr = signer::address_of(alice);
        let bob_addr = signer::address_of(bob);
        let star = new_star(b"ajay", b"India", 4);
        mint(alice, star);
        assert!(card_exists(alice_addr), 0);
        set_price(alice, 100);
        transfer(alice, bob);
        assert!(card_exists(bob_addr), 1);
        assert!(!card_exists(alice_addr), 3);
    }

}