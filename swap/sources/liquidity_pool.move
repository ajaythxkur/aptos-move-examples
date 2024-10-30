module addrx::liquidity_pool {
    use std::signer::address_of;
    use addrx::pool_token;
    use aptos_framework::aptos_account;

    struct LiquidityPool<phantom X, phantom Y> has key {
        coins_x: u64,
        coins_y: u64,
        // represents the initial lp token share
        share: u64,
    }

    const ENOT_ADMIN: u64 = 0;
    const EPOOL_EXISTS: u64 = 1;

    public fun create_pool<X: drop, Y: drop>(
        creator: &signer,
        requestor: &signer,
        coins_x: u64,
        coins_y: u64,
        share: u64,
    ) {
        let addr = address_of(creator);
        assert!(addr == @addrx, ENOT_ADMIN);
        assert!(!exists<LiquidityPool<X,Y>>(addr), EPOOL_EXISTS);
        move_to(creator, LiquidityPool<X,Y>{
            coins_x,
            coins_y,
        });
        aptos_account::transfer<X>(requestor, addr, coins_x);
        aptos_account::transfer<Y>(requestor, addr, coins_y);
        pool_token::initialize<X,Y>(creator);
        pool_token::mint<X,Y>(requestor, share);
    }

}