script {
    use my_addr::Collection as coll;
    use std::signer;
    use std::debug;

    fun main_resource(account: &signer) {
        let addr = signer::address_of(account);
        coll::start_collection(account);
        coll::destory(account);
        let exists_at = coll::exists_at(addr);
        debug::print(&exists_at);
        coll::add_item(account);
        coll::add_item(account);
        coll::add_item(account);
        let size = coll::size(account);
        debug::print(&size);
    }
}