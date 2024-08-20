module my_addr::MultiSender {
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::aptos_account;
    use std::vector;
    use std::signer;

    // NOT ENOUGH COINS
    const ENOT_ENOUGH_COINS: u64 = 0;

    public entry fun ms_trans(from: &signer, to: vector<address>, amount: u64){
        let size: u64 = vector::length(&to);
        let from_balance = coin::balance<AptosCoin>(signer::address_of(from));
        assert!(amount * size <= from_balance, ENOT_ENOUGH_COINS);
        
        let i = 0;  
        while(i < size){
            let to_addr = *vector::borrow(&to, (i as u64));
            aptos_account::transfer(from, to_addr, amount);
            i = i + 1;
        };
    }
    
    // TODO: Write tests
}