module stake_addr::BasicCoin {
    use std::signer;

    struct Coin has store, drop {
        val: u64
    }

    struct Balance has key {
        coin: Coin
    }

    // BALANCE EXISTS
    const EBALANCE_EXISTS: u64 = 0;
    // BALANCE DOENST EXIST
    const EBALANCE_DOESNT_EXIST: u64 = 1;
    // INSUFFICIENT BALANCE
    const EINSUFFICIENT_BALANCE: u64 = 2;
    // EQUAL ADDRESS
    const EEQUAL_ADDR: u64 = 3;
    public fun new_coin(val: u64): Coin {
        return Coin {
            val
        }
    }
    public fun balance_exists(addr: address): bool {
        exists<Balance>(addr)
    }
    public fun publish_balance(account: &signer){
        let addr = signer::address_of(account);
        assert!(!balance_exists(addr), EBALANCE_EXISTS);
        let zero_coin = Coin { val: 0 };
        move_to(account, Balance { coin: zero_coin });
    }
    public fun mint(mint_addr: address, amount: u64) acquires Balance {
        deposit(mint_addr, Coin { val: amount });
    }

    public fun burn(burn_addr: address, amount: u64) acquires Balance {
        let Coin { val: _ } = withdraw(burn_addr, amount);
    }

    public fun balance_of(addr: address): u64 acquires Balance {
        borrow_global<Balance>(addr).coin.val
    }

    public fun deposit(addr: address, coin: Coin) acquires Balance {
        let balance = balance_of(addr);
        let balance_ref = &mut borrow_global_mut<Balance>(addr).coin.val;
        let Coin { val } = coin;
        *balance_ref = balance + val;
    }

    public fun withdraw(addr: address, amount: u64): Coin acquires Balance {
        let balance = balance_of(addr);
        assert!(balance >= amount, EINSUFFICIENT_BALANCE);
        let balance_ref = &mut borrow_global_mut<Balance>(addr).coin.val;
        *balance_ref = balance - amount;
        Coin { val: amount }
    }

    public fun transfer(from: &signer, to_addr: address, amount: u64) acquires Balance {
        let from_addr = signer::address_of(from);
        assert!(balance_exists(from_addr), EBALANCE_DOESNT_EXIST);
        assert!(from_addr != to_addr, EEQUAL_ADDR);
        let check = withdraw(from_addr, amount);
        deposit(to_addr, check);
    }
}

module stake_addr::Staking {
    use std::signer;

    struct StakedBalance has key {
        amount: u64
    }
    // INSUFFICIENT AMOUNT
    const EINSUFFICIENT_AMOUNT: u64 = 0;
    // ALREADY STAKED
    const EALREADY_STAKED: u64 = 1;
    // STAKE DOESNT EXIST
    const ESTAKE_DOESNT_EXIST: u64 = 2;
    // INVALID UNSTAKE AMOUNT
    const EINVALID_UNSTAKE_AMOUNT: u64 = 3;
    // INSUFFICIENT STAKE
    const EINSUFFICIENT_STAKE: u64 = 4;


    // CONST //
    const DEFAULT_APY: u64 = 1000; // 10 %

    public fun stake(account: &signer, amount: u64) {
        let addr = signer::address_of(account);
        let balance = stake_addr::BasicCoin::balance_of(addr);
        assert!(balance >= amount, EINSUFFICIENT_AMOUNT);
        assert!(!exists<StakedBalance>(addr), EALREADY_STAKED);
        stake_addr::BasicCoin::withdraw(addr, amount);
        move_to(account, StakedBalance{
            amount
        });
    }

    public fun unstake(account: &signer, amount: u64) acquires StakedBalance {
        let addr = signer::address_of(account);
        assert!(exists<StakedBalance>(addr), ESTAKE_DOESNT_EXIST);
        let staked_balance = borrow_global_mut<StakedBalance>(addr);
        assert!(staked_balance.amount >= amount, EINVALID_UNSTAKE_AMOUNT);
        let coin = stake_addr::BasicCoin::new_coin(amount);
        stake_addr::BasicCoin::deposit(addr, coin);
        staked_balance.amount = staked_balance.amount - amount;
    }

    public fun claim_rewards(account: &signer) acquires StakedBalance {
        let addr = signer::address_of(account);
        assert!(exists<StakedBalance>(addr), ESTAKE_DOESNT_EXIST);
        let staked_balance = borrow_global<StakedBalance>(addr);
        assert!(staked_balance.amount > 0,  EINSUFFICIENT_STAKE);
        let apy = DEFAULT_APY;
        let reward_amount = (staked_balance.amount * apy) / (10000);
        let coin = stake_addr::BasicCoin::new_coin(reward_amount);
        stake_addr::BasicCoin::deposit(addr, coin);
    }
    
    #[test(alice=@0x123, bob=@0x100)]
    public fun testing(alice: &signer, bob: &signer) acquires StakedBalance {
        let alice_addr = signer::address_of(alice);
        let bob_addr = signer::address_of(bob);
        stake_addr::BasicCoin::publish_balance(alice);
        let new_coin = stake_addr::BasicCoin::new_coin(100);
        stake_addr::BasicCoin::deposit(alice_addr, new_coin);
        let balance = stake_addr::BasicCoin::balance_of(alice_addr);
        assert!(balance == 100, 0);
        stake(alice, 50);
        let balance = stake_addr::BasicCoin::balance_of(alice_addr);
        assert!(balance == 50, 1);
        unstake(alice, 10);
        let balance = stake_addr::BasicCoin::balance_of(alice_addr);
        assert!(balance == 60, 1);
        claim_rewards(alice);
        let balance = stake_addr::BasicCoin::balance_of(alice_addr);
        assert!(balance == 64, 2);
        stake_addr::BasicCoin::publish_balance(bob);
        stake_addr::BasicCoin::transfer(alice, bob_addr, 14);
        let alice_balance = stake_addr::BasicCoin::balance_of(alice_addr);
        assert!(alice_balance == 50, 3);
         let bob_balance = stake_addr::BasicCoin::balance_of(bob_addr);
        assert!(bob_balance == 14, 4);
        
    }
}