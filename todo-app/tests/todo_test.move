module my_addr::TodoTest {

    #[test_only]
    use my_addr::Todo::{create_list, create_task, complete_task};

    #[test_only]
    use std::signer;

    #[test_only]
    use aptos_framework::account;

    #[test_only]
    use std::string::utf8;

    #[test(account=@0x123)]
    public fun testing(account: &signer) {
        let addr = signer::address_of(account);
        account::create_account_for_test(addr);
        create_list(account);
        create_task(account, utf8(b"code todo contract"));
        complete_task(account, 1);
    }

}