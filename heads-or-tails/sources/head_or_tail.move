module addrx::heads_or_tails {
    use std::signer::address_of;
    use aptos_framework::object;
    use aptos_framework::randomness;
    use aptos_framework::event;
    use aptos_framework::aptos_account;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::vector;
    use aptos_framework::coin;

    struct AccountCapability has key {
        extend_ref: object::ExtendRef,
    }

    #[event]
    struct FlipEvent has drop, store {
        addr: address,
        side: u64,
        randomness_side: u64,
        claim_object: address
    }

    #[event]
    struct ClaimEvent has drop, store {
        addr: address,
        amount: u64
    }

    #[resource_group_member(group=aptos_framework::object::ObjectGroup)]
    struct Reward has key {
        amount: u64,
        extend_ref: object::ExtendRef,
        delete_ref: object::DeleteRef,
    }

    struct UserReward has key {
        rewards: vector<address>
    }
    //Errors
    const EINVALID_SIDE: u64 = 0;
    const EOUT_OF_REWARD_BALANCE: u64 = 1;
    const ENO_REWARD_OBJECT: u64 = 2;
    const ENOT_AUTHORIZED: u64 = 3;
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

    entry fun fund_contract(account: &signer, amount: u64) {
        aptos_account::transfer_coins<AptosCoin>(account, get_app_signer_addr(), amount);
    }

    #[randomness]
    entry fun flip_coin(account: &signer, side: u64) acquires UserReward {
        // 0 Heads, 1 Tails 
        assert!(side == 0 || side == 1, EINVALID_SIDE);
        let ca_balance = coin::balance<AptosCoin>(get_app_signer_addr());
        assert!(ca_balance >= MIN_APT, EOUT_OF_REWARD_BALANCE);
        aptos_account::transfer_coins<AptosCoin>(account, get_app_signer_addr(), MIN_APT);
        let randomness_side = randomness::u64_range(0, 1);
        
        if(randomness_side == side) {
            let user_addr = address_of(account);
            let constructor_ref = &object::create_object(user_addr);
            let obj_signer = &object::generate_signer(constructor_ref);
            let extend_ref = object::generate_extend_ref(constructor_ref);
            let delete_ref = object::generate_delete_ref(constructor_ref);
            move_to(obj_signer, Reward { 
                amount: MIN_APT * 2,
                extend_ref,
                delete_ref,
            });
            if(exists<UserReward>(user_addr)) {
                let user_rewards = borrow_global_mut<UserReward>(user_addr);
                vector::push_back(&mut user_rewards.rewards, object::address_from_constructor_ref(constructor_ref));
            } else {
                let user_rewards = UserReward {
                    rewards: vector::singleton(
                        object::address_from_constructor_ref(constructor_ref),
                    )
                };
                move_to(account, user_rewards);
            };
            event::emit<FlipEvent>(
                FlipEvent {
                    addr: address_of(account),
                    side,
                    randomness_side,
                    claim_object: object::address_from_constructor_ref(constructor_ref),
                }
            );
        } else {
            event::emit<FlipEvent>(
                FlipEvent {
                    addr: address_of(account),
                    side,
                    randomness_side,
                    claim_object: @0x0
                }
            );
        }
    }

    entry fun claim_reward(account: &signer, object_address: address) acquires Reward, UserReward, AccountCapability {
        assert!(exists<Reward>(object_address), ENO_REWARD_OBJECT);
        let reward_obj = object::address_to_object<Reward>(object_address);
        assert!(object::is_owner(reward_obj, address_of(account)), ENOT_AUTHORIZED);
        let reward = borrow_global<Reward>(object_address);
        aptos_account::transfer_coins<AptosCoin>(&get_app_signer(), address_of(account), reward.amount);
        event::emit<ClaimEvent>(
            ClaimEvent {
                addr: address_of(account),
                amount: reward.amount
            }
        );
        let user_addr = address_of(account);
        if(exists<UserReward>(user_addr)){
            let user_reward = borrow_global_mut<UserReward>(user_addr);
            let (has_addr, index) = vector::index_of(&user_reward.rewards, &object_address);
            if(has_addr) {
                vector::remove(&mut user_reward.rewards, index);
            }
        }
    }

    #[view]
    public fun get_user_reward_addresses(addr: address): vector<address> acquires UserReward {
        if(exists<UserReward>(addr)){
            let user_rewards = borrow_global<UserReward>(addr);
            user_rewards.rewards
        } else {
            vector[]
        }
    }

    #[view] 
    public fun get_reward(object_address: address): u64 acquires Reward {
        assert!(exists<Reward>(object_address), ENO_REWARD_OBJECT);
        let reward = borrow_global<Reward>(object_address);
        reward.amount
    }

    #[view]
    public fun get_contract_balance(): u64 {
        coin::balance<AptosCoin>(get_app_signer_addr())
    }

    #[test_only]
    fun init_module_for_test(account: &signer) {
        init_module(account);
    }

    #[test_only]
    use aptos_framework::aptos_coin;

    #[test_only]
    use aptos_framework::account;

    #[test_only]
    use std::debug;

    #[test_only]
    fun get_last_flip_event_claim(): (address, u64) {
        let emitted_events = event::emitted_events<FlipEvent>();
        let last_emitted_event = vector::borrow(&emitted_events, vector::length(&emitted_events) - 1);
        (last_emitted_event.claim_object, last_emitted_event.randomness_side)
    }

    #[test(creator=@addrx,user=@0xCAFE,aptos_framework=@0x1)]
    fun test_flip_and_claim_on_win(creator: &signer, user: &signer, aptos_framework: &signer) acquires UserReward, Reward, AccountCapability {
        account::create_account_for_test(address_of(creator));
        account::create_account_for_test(address_of(user));
        randomness::initialize_for_testing(aptos_framework);
        init_module_for_test(creator);
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        coin::destroy_burn_cap<AptosCoin>(burn_cap);
        let ca_coins = coin::mint<AptosCoin>(MIN_APT, &mint_cap);
        let user_coins = coin::mint<AptosCoin>(MIN_APT, &mint_cap);
        coin::register<AptosCoin>(creator);
        coin::register<AptosCoin>(user);
        coin::deposit<AptosCoin>(address_of(creator), ca_coins);
        coin::deposit<AptosCoin>(address_of(user), user_coins);
        fund_contract(creator, MIN_APT);
        // Randomness always generating zero on test
        flip_coin(user, 0);
        coin::destroy_mint_cap(mint_cap);
        let (claim_object_address, randomness_side) = get_last_flip_event_claim();
        debug::print(&claim_object_address);
        debug::print(&randomness_side);
        claim_reward(user, claim_object_address);
        let user_balance = coin::balance<AptosCoin>(address_of(user));
        assert!(user_balance == MIN_APT * 2, 0);
        let ca_balance = get_contract_balance();
        assert!(ca_balance == 0, 1);
    }
}
