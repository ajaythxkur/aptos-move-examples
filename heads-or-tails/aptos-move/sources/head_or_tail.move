// Todo: add min apt for flip + claim based on objects + tests
module addrx::heads_or_tails {
    use std::signer::address_of;
    use aptos_framework::object;
    use aptos_framework::randomness;
    use aptos_framework::event;

    struct AccountCapability has key {
        extend_ref: object::ExtendRef,
    }

    #[event]
    struct FlipEvent has drop, store {
        addr: address,
        side: u64,
        randomness_side: u64,
    }

    //Errors
    const EINVALID_SIDE: u64 = 0;
    //Constants
    const APP_SEED: vector<u8> = b"APP_SEED";
    const MIN_APT: u64 = 10000000; // 0.1 APT

    fun init_module(module_signer: &signer) {
        let constructor_ref = &object::create_named_object(module_signer, APP_SEED);
        let app_signer = &object::generate_signer(constructor_ref);
        move_to(app_signer, AccountCapability {
            extend_ref: object::generate_extend_ref(constructor_ref),
        });
    }

    fun get_app_signer_addr(): address {
        object::create_object_address(&@addrx, APP_SEED)
    }

    fun get_app_signer(): signer acquires AccountCapability {
        let obj_addr = get_app_signer_addr();
        object::generate_signer_for_extending(&borrow_global<AccountCapability>(obj_addr).extend_ref)
    }

    #[randomness]
    entry fun flip_coin(account: &signer, side: u64) {
        // 0 Heads, 1 Tails 
        assert!(side == 0 || side == 1, EINVALID_SIDE);
        let randomness_side = randomness::u64_range(0, 1);
        event::emit<FlipEvent>(
            FlipEvent {
                addr: address_of(account),
                side,
                randomness_side
            }
        );
    }
    

}