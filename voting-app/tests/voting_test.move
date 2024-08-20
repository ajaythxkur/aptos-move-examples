module my_addr::VotingTest {

    #[test_only]
    use my_addr::Voting::{initialize_with_candidate, add_candidate, vote, declare_winner};

    #[test_only]
    use std::signer;

    #[test(owner=@my_addr, candidate_a=@0x100, candidate_b=@0xCAFE, voter=@0x768)]
    public fun testing(owner: &signer, candidate_a: &signer, candidate_b: &signer, voter: &signer) {
        let owner_addr = signer::address_of(owner);
        let candidate_a_addr = signer::address_of(candidate_a);
        let candidate_b_addr = signer::address_of(candidate_b);
        let _voter_addr = signer::address_of(voter);

        initialize_with_candidate(owner, candidate_a_addr);
        add_candidate(owner, candidate_b_addr);

        vote(voter, candidate_b_addr, owner_addr);
        vote(owner, candidate_b_addr, owner_addr);

        declare_winner(owner);
        
    }
}