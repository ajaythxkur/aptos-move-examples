module my_addr::Storage {
    use std::signer;

    struct Storage<T: store> has key {
        val: T
    }

    // ERROR STORE EXIST
    const ESTORE_EXISTS: u64 = 0;
    // ERROR STORE DOESNT EXIST
    const ESTORE_DOESNT_EXIST: u64 = 1;

    fun store<T: store>(account: &signer, val: T) {
        let addr = signer::address_of(account);
        assert!(!exists<Storage<T>>(addr), ESTORE_EXISTS);
        let storage = Storage { 
            val
        };
        move_to(account, storage);
    }

    fun get_store<T: store>(account: &signer): T acquires Storage {
        let addr = signer::address_of(account);
        assert!(exists<Storage<T>>(addr), ESTORE_DOESNT_EXIST);
        let Storage { val } = move_from<Storage<T>>(addr); // Storage has no copy ability so move_from
        val
    }

    #[test(account= @my_addr)]
    public fun testing(account: &signer) acquires Storage {
        let num: u64 = 7;
        let num_a: u128 = 9;
        store(account, num);
        store(account, num_a);
        assert!(num == get_store<u64>(account), 0);
        assert!(num_a == get_store<u128>(account), 0);
    }
}