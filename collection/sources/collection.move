module my_addr::Collection {
    use std::signer;
    use std::vector;

    struct Item has store, drop {}

    struct Collection has key {
        items: vector<Item>
    }

    public fun start_collection(account: &signer){
        move_to<Collection>(account, Collection{
            items: vector::empty()
        });
    }

    public fun add_item(account: &signer) acquires Collection {
        let addr = signer::address_of(account);
        let collection = borrow_global_mut<Collection>(addr);
        vector::push_back(&mut collection.items, Item{});
    }

    public fun size(account: &signer): u64 acquires Collection {
        let addr = signer::address_of(account);
        let collection = borrow_global<Collection>(addr); 
        vector::length(&collection.items)   
    }

    public fun destory(account: &signer) acquires Collection {
        let addr = signer::address_of(account);
        let collection = move_from<Collection>(addr);     
        let Collection { items: _ } = collection;
    }

    public fun exists_at(addr: address): bool {
        exists<Collection>(addr)
    }
}