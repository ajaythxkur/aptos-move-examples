module my_addr::BasicCoin {
    use std::signer;

    struct Balance has key {
        coin: Coin
    }

    struct Coin has store { val: u64 }

    // BALANCE EXISTS
    const EBALANCE_EXISTS: u64 = 102;
    // BALANCE DOESNT EXIST
    const EBALANCE_DOESNT_EXIST: u64 = 101;
    // INSUFFICIENT BALANCE
    const EINSUFFICIENT_BALANCE: u64 = 0;
    // SAME ADDR
    const EADDR_SAME: u64 = 1;

    public fun mint(val: u64):Coin{
        let new_coin = Coin { val };
        new_coin
    }

    public fun burn(coin: Coin){
        let Coin{ val: _ } = coin;
    }

    public fun create_balance(account: &signer) {
        let addr = signer::address_of(account);
        assert!(!balance_exists(addr), EBALANCE_EXISTS);

        let zero_coin = Coin { val: 0 };
        move_to(account, Balance { coin: zero_coin });
    }

    public fun balance_exists(addr: address): bool {
        exists<Balance>(addr)
    }

    public fun balance(addr: address): u64 acquires Balance {
        borrow_global<Balance>(addr).coin.val
    }

    public fun deposit(acc_addr: address, coin: Coin) acquires Balance {
        assert!(balance_exists(acc_addr), EBALANCE_DOESNT_EXIST);
        let balance = balance(acc_addr);
        let balance_ref = &mut borrow_global_mut<Balance>(acc_addr).coin.val;
        let Coin { val } = coin;
        *balance_ref = balance + val;
    } 

    public fun withdraw(addr: address, value: u64): Coin acquires Balance {
        assert!(balance_exists(addr), EBALANCE_DOESNT_EXIST);
        let balance = balance(addr);
        assert!(balance >= value, EINSUFFICIENT_BALANCE);
        let balance_ref = &mut borrow_global_mut<Balance>(addr).coin.val;
        *balance_ref = balance - value;
        Coin { val: value }
    }

    public fun transfer(from: &signer, to: address, amount: u64) acquires Balance {
        let from_addr = signer::address_of(from);
        assert!(from_addr != to, EADDR_SAME);
        let check = withdraw(from_addr, amount);
        deposit(to, check);
    }

    #[test(alice=@0x123, bob=@0x100)]
    public fun testing(alice: &signer, bob: &signer) acquires Balance {
        let alice_addr = signer::address_of(alice);
        let bob_addr = signer::address_of(bob);
        create_balance(alice);
        create_balance(bob);
        assert!(balance(alice_addr) == 0, 0);
        assert!(balance(bob_addr) == 0, 0);
        let new_coin = Coin { val: 100 };
        deposit(alice_addr, new_coin);
        transfer(alice, bob_addr, 50);
        assert!(balance(alice_addr) == 50, 1);
        assert!(balance(bob_addr) == 50, 1);
    }
 }