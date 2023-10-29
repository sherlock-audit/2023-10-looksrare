
# Looks Rare contest details

- Join [Sherlock Discord](https://discord.gg/MABEWyASkp)
- Submit findings using the issue page in your private contest repo (label issues as med or high)
- [Read for more details](https://docs.sherlock.xyz/audits/watsons)

# Q&A

### Q: On what chains are the smart contracts going to be deployed?
Mainnet
___

### Q: Which ERC20 tokens do you expect will interact with the smart contracts? 
LOOKS
LINK indirectly as we need to pay for VRF
WETH if ETH transfer fails
___

### Q: Which ERC721 tokens do you expect will interact with the smart contracts? 
The contract itself is an ERC-721A collection
___

### Q: Which ERC777 tokens do you expect will interact with the smart contracts? 
None
___

### Q: Are there any FEE-ON-TRANSFER tokens interacting with the smart contracts?

None
___

### Q: Are there any REBASING tokens interacting with the smart contracts?

None
___

### Q: Are the admins of the protocols your contracts integrate with (if any) TRUSTED or RESTRICTED?
TRUSTED
___

### Q: Is the admin/owner of the protocol/contracts TRUSTED or RESTRICTED?
TRUSTED
___

### Q: Are there any additional protocol roles? If yes, please explain in detail:
The only role is the owner and it can do 3 things

1. set/extend mint period
2. start the game after mint
3. withdraw funds from the contract if the game is bricked
___

### Q: Is the code/contract expected to comply with any EIPs? Are there specific assumptions around adhering to those EIPs that Watsons should be aware of?
None
___

### Q: Please list any known issues/acceptable risks that should not result in a valid finding.
Accepted Risks

maximumAmountMintedPerAddress can be bypassed.
Agents can still be minted by the contract owner even after the mint period ends, as long as it is  before the game begins. The maximumAmountMintedPerAddress restriction does not apply to this.
Theoretically, the contract owner can wait for 36 hours after the mint period ends, not start the game, and withdraw everything (ETH and LOOKS) from the contract.
In the case of extended periods of network congestion or any reason causing the randomness request not to be fulfilled, the contract owner is able to withdraw everything after approximately 36 hours.
VRF provided randomness is trusted
All active agent NFTs can be transferred at any point of time, so an active agent can be listed for sale on a marketplace and be bought even in the same block if it is in a transaction before the transaction that changes its state from active to another state. 
_mintERC2309 is called outside of contract creation, so the contract is non-compliant with the ERC721 standard.
___

### Q: Please provide links to previous audits (if any).
None
___

### Q: Are there any off-chain mechanisms or off-chain procedures for the protocol (keeper bots, input validation expectations, etc)?
We have a keeper bot that checks what the current block number is and calls startNewRound if needed
___

### Q: In case of external protocol integrations, are the risks of external contracts pausing or executing an emergency withdrawal acceptable? If not, Watsons will submit issues related to these situations that can harm your protocol's functionality.
Yes they are acceptable
___

### Q: Do you expect to use any of the following tokens with non-standard behaviour with the smart contracts?
No
___

### Q: Add links to relevant protocol resources
N/A
___


# Audit scope


[contracts-infiltration @ 90bd6af2da7b3df1c5fac6595128ab62cf989cca](https://github.com/LooksRare/contracts-infiltration/tree/90bd6af2da7b3df1c5fac6595128ab62cf989cca)
- [contracts-infiltration/contracts/Infiltration.sol](contracts-infiltration/contracts/Infiltration.sol)
- [contracts-infiltration/contracts/InfiltrationPeriphery.sol](contracts-infiltration/contracts/InfiltrationPeriphery.sol)

