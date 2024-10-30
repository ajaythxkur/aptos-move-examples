module addrx::pool_token {
    use std::signer::address_of;
    use aptos_framework::coin;
    use std::string;
    use aptos_framework::aptos_account;

    struct LP<phantom X, phantom Y> has key {}

    struct CoinCapabilities<phantom X, phantom Y> has key {
        mint_cap: coin::MintCapability<LP<X,Y>>,
        burn_cap: coin::BurnCapability<LP<X,Y>>,
        freeze_cap: coin::FreezeCapability<LP<X,Y>>,
    }

    const ENOT_ADMIN: u64 = 0;
    const ECOIN_DOESNT_EXIST: u64 = 1;

    fun initialize<X, Y>(creator: &signer) {
        assert!(address_of(creator) == @addrx, ENOT_ADMIN);
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<LP<X,Y>>(
            creator,
            string::utf8(b"LP Token"),
            string::utf8(b"LP"),
            6, 
            true,
        );
        move_to(creator, CoinCapabilities<X,Y> {mint_cap, burn_cap, freeze_cap});
    }

    fun mint<X,Y>(creator: &signer, to: address, amount: u64) acquires CoinCapabilities {
        let addr = address_of(creator);
        assert!(addr == @addrx, ENOT_ADMIN);
        assert!(exists<LP<X,Y>>(addr), ECOIN_DOESNT_EXIST);
        let mint_cap = &borrow_global<CoinCapabilities<X,Y>>(addr).mint_cap;
        let coins = coin::mint<LP<X,Y>>(amount, mint_cap);
        if(!coin::is_account_registered<LP<X,Y>>(addr)){
            coin::register<LP<X,Y>>(creator);
        }
        coin::deposit<LP<X,Y>>(addr, coins);
        aptos_account::transfer_coins<LP<X,Y>>(creator, to, amount);
    }
}