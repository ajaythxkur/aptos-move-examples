module game_host::flip_or_nothing {
    use std::signer;
    use aptos_framework::resource_account;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::account;
    use aptos_framework::randomness;
    use aptos_framework::event;
    use aptos_std::ed25519;

    struct GameData has key {
        signer_cap: SignerCapability,
    }

    #[event]
    struct BetEvent has store, drop {
        is_win: bool,
    }

    const ESIDE_INVALID: u64 = 0;

    fun init_module(resource_signer: &signer) {
        let resource_signer_cap = resource_account::retrieve_resource_account_cap(resource_signer, @game_host);
        move_to(resource_signer, GameData {
            signer_cap: resource_signer_cap,
        });
    }

    public entry fun add_fund<CoinType>(creator: &signer, amount: u64) {

    }

    #[randomness]
    public entry fun bet<CoinType>(player: &signer, side: u64, amount: u64) acquires GameData {
        assert!(side == 0 || side == 1, ESIDE_INVALID);
        let num = aptos_framework::randomness::u64_range(0, 1);
        if(side == num) {

            event::emit<BetEvent>(
                BetEvent {
                    is_win: true,
                }
            );
        } else {
            event::emit<BetEvent>(
                BetEvent {
                    is_win: false,
                }
            );
        }
    }   
}