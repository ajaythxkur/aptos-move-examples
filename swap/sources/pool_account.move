// This is the account where liquidity pools will be stored
module addrx::pool_account {
    use std::signer;
    use aptos_framework::account::{Self, SignerCapability};

    struct AccountCapability has key {
        signer_cap: SignerCapability,
    }
    const ENOT_ADMIN: u64 = 0;
    const EACCOUNT_NOT_INITIALIZED: u64 = 1;

    const ACCOUNT_SEED: vector<u8> = b"POOL_ACCOUNT_SEED";

    // Admin initializes pool account
    public fun initialize_pool_account(
        creator: &signer,
    ) {
        let addr = signer::address_of(creator);
        assert!(addr == @admin, ENOT_ADMIN);
        let (_acc, signer_cap) = account::create_resource_account(creator, ACCOUNT_SEED);
        move_to(creator, AccountCapability {
            signer_cap,
        });
    }

    public fun retrieve_signer_cap(
        account: &signer,
    ): SignerCapability acquires AccountCapability {
        assert!(signer::address_of(account) == @admin, ENOT_ADMIN);
        assert!(exists<AccountCapability>(signer::address_of(account)), EACCOUNT_NOT_INITIALIZED);
        let AccountCapability { signer_cap } = move_from<AccountCapability>(signer::address_of(account));
        signer_cap
    }
}