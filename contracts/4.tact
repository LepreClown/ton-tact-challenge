import "@stdlib/deploy";

/*
  TASK 4 - NFT locker
  Implement a smart contract that will lock NFT for a period of time specified by the owner.
  Smart conrtact should contain logic to process following messages and getters: 

  Messages: 
  * OwnershipAssigned
   - Recives nft + time (in a forwardPayload message as uint32) for which this nft will be locked + address of the sender of the nft (prevOwner).
   - If the smart contract already holds an nft then return the incoming nft back to the sender
  * NftWithdrawal
   - Request withdrawal of the locked nft
   - If sender is not the owner (that came from OwnershipAssigned as prevOwner address) then throw "Invalid sender" 
   - If time has not passed then send message back to the sender with the comment "NFT is still locked" according to the TON's "message with text comment" standard 
   - Otherwise (all good) send the locked nft back to the owner with all the remaining TON balance
   Note that the order of checks is important
   (in case: "sender is not the owner" and "time has not passed" at the same time, "Invalid sender" error takes priority)

  Getters:
  * time
   - get how much lock time is left
  * nft
   - get the address of the locked nft 
  * owner
   - get the owner of the locked nft (that came from OwnershipAssigned as prevOwner)
*/

message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining;
}
message(0x5fcc3d14) Transfer {
    queryId: Int as uint64;
    newOwner: Address;
    responseDestination: Address;
    customPayload: Cell?;
    forwardAmount: Int as coins;
    forwardPayload: Slice as remaining;
}
message NftWithdrawal {
    queryId: Int as uint64;
    nftAddress: Address;
}

contract Task4 with Deployable {
    seed: Int as uint128;
    timeLockNtf: Int as uint32;
    unlockTime: Int as uint32;
    previousOwner: Address;
    nft: Address?;
    init(seed: Int){
        self.seed = seed;
        self.previousOwner = sender();
        self.timeLockNtf = 0;
        self.unlockTime = 0;
    }

    receive(msg: OwnershipAssigned){
        if (self.nft == null) {
            self.timeLockNtf = msg.forwardPayload.loadUint(32);
            self.unlockTime = self.timeLockNtf + now();
            self.previousOwner = msg.prevOwner;
            self.nft = sender();
        } else {
            send(SendParameters{to: self.previousOwner,
                    value: 0,
                    body: Transfer{queryId: msg.queryId,
                        newOwner: msg.prevOwner,
                        responseDestination: myAddress(),
                        customPayload: beginCell().asCell(),
                        forwardAmount: 0,
                        forwardPayload: msg.forwardPayload
                    }.toCell(),
                    mode: SendRemainingBalance + SendIgnoreErrors
                }
            );
        }
    }

    receive(msg: NftWithdrawal){
        require(self.previousOwner == sender(), "Invalid sender");
        require(now() >= self.unlockTime, "NFT is still locked");
        send(SendParameters{to: sender(),
                value: 0,
                body: Transfer{queryId: msg.queryId,
                    newOwner: self.previousOwner,
                    responseDestination: myAddress(),
                    customPayload: beginCell().asCell(),
                    forwardAmount: 0,
                    forwardPayload: beginCell().asSlice()
                }.toCell(),
                mode: SendRemainingBalance + SendIgnoreErrors
            }
        );
    }

    get fun time(): Int {
        return self.unlockTime - now();
    }

    get fun nft(): Address? {
        return self.nft;
    }

    get fun owner(): Address? {
        return self.previousOwner;
    }
}