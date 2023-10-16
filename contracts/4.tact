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
    // адрес контракта на который был передан NFT
    newOwner: Address;
    // адрес на который были переведены избыточные средства
    responseDestination: Address;
    customPayload: Cell?;
    // количество ton  (обычно устанавливается равным 0,01 TON)
    forwardAmount: Int as coins;
    // из ownershipAssigned
    forwardPayload: Slice as remaining;
}
message NftWithdrawal {
    queryId: Int as uint64;
    nftAddress: Address;
}

contract Task4 with Deployable {
    seed: Int as uint128;
    lockTime: Int as uint32;
    lockedNft: Address?;
    owner: Address;
    init(seed: Int){
        self.seed = seed;
        self.lockTime = 0;
        self.owner = sender();
    }

    receive(msg: OwnershipAssigned){
        if (self.lockedNft == null) {
            self.owner = msg.prevOwner;
            self.lockTime = msg.forwardPayload.loadUint(32) + now();
            self.lockedNft = sender();
        } else {
            send(SendParameters{to: sender(),
                    value: 0,
                    bounce: false,
                    body: Transfer{queryId: msg.queryId,
                        newOwner: msg.prevOwner,
                        responseDestination: msg.prevOwner,
                        customPayload: emptyCell(),
                        forwardAmount: 0,
                        forwardPayload: emptySlice()
                    }.toCell(),
                    mode: SendRemainingValue + SendIgnoreErrors
                }
            );
        }
    }

    receive(msg: NftWithdrawal){
        // test#2
        require(self.owner == sender(), "Invalid sender");
        require(self.owner == sender() && now() >= self.lockTime, "Invalid sender");
        require(now() >= self.lockTime, "NFT is still locked");
        // require(msg.nftAddress == self.lockedNft, "Invalid NFT address");
        // require(msg.queryId == 0, "Invalid query ID");

        send(SendParameters{to: self.owner,
                value: 0,
                bounce: false,
                body: Transfer{queryId: msg.queryId,
                    newOwner: self.owner,
                    responseDestination: msg.nftAddress,
                    customPayload: emptyCell(),
                    forwardAmount: 0,
                    forwardPayload: emptySlice()
                }.toCell(),
                mode: SendRemainingBalance + SendIgnoreErrors
            }
        );
    }

    get fun time(): Int {
        // test#1
        return self.lockTime - now();
    }

    get fun nft(): Address? {
        return self.lockedNft;
    }

    get fun owner(): Address? {
        return self.owner;
    }
}