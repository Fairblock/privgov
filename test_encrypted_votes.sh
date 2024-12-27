#!/bin/bash

echo "Submitting proposal"
privgovd tx gov submit-proposal draft_proposal.json --from fred --chain-id privgov --yes

sleep 10

PROPOSAL_ID=$(privgovd q gov proposals --output json | jq '.proposals | length')
PROPOSAL_INDEX=$((PROPOSAL_ID - 1))

sleep 10

PUBKEY=$(privgovd q gov proposals --output json | jq -r ".proposals[$PROPOSAL_INDEX].pubkey")
ID=$(privgovd q gov proposals --output json | jq -r ".proposals[$PROPOSAL_INDEX].identity")
echo "Proposal #$PROPOSAL_ID [$PROPOSAL_INDEX] Pubkey: $PUBKEY, Identity: $ID"

echo "Encrypting vote..."
ENCRYPTED_VOTE=$(fairyringd encrypt-vote yes $ID 1 $PUBKEY)
echo "Encrypted vote: $ENCRYPTED_VOTE"

echo "Submitting encrypted vote"
privgovd tx gov vote-encrypted $PROPOSAL_ID $ENCRYPTED_VOTE --chain-id privgov --from alice --yes

LAST_PROPOSAL=$(privgovd q gov proposals --output json | jq ".proposals[$PROPOSAL_INDEX]")
HAS_ENCRYPTED_VOTE=$(echo $LAST_PROPOSAL | jq '.has_encrypted_votes')
STATUS=$(echo $LAST_PROPOSAL | jq -r '.status')

sleep 20

echo "Proposal #$PROPOSAL_ID Status: $STATUS has encrypted vote ? $HAS_ENCRYPTED_VOTE"
echo $LAST_PROPOSAL | jq
