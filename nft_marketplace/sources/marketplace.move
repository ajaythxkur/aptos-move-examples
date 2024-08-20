module my_addrx::marketplace {
    use std::signer;
    use aptos_framework::object;

    #[test_only]
    friend my_addrx::test_marketplace;

    struct MarketplaceSigner has key {
        extend_ref: object::ExtendRef,
    }

    const APP_OBJECT_SEED: vector<u8> = b"MARKETPLACE";

    fun init_module(deployer: &signer){
        let constructor_ref = object::create_named_object(deployer, APP_OBJECT_SEED);
        let app_signer = object::generate_signer(&constructor_ref);
        let extend_ref = object::generate_extend_ref(&constructor_ref);
        move_to(&app_signer, MarketplaceSigner {
            extend_ref,
        });
    }


}

module my_addrx::test_marketplace {

    #[test_only]
    use my_addrx::marketplace;

    #[test(admin=@0x123)]
    public fun test_init(admin: &signer){
        
    }
}

