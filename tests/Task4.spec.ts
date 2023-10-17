import { Blockchain, SandboxContract, TreasuryContract } from '@ton-community/sandbox';
import { beginCell, toNano } from 'ton-core';
import { Task4, OwnershipAssigned, NftWithdrawal } from '../wrappers/Task4';
import '@ton-community/test-utils';

describe('Task4', () => {
    let blockchain: Blockchain;
    let task4: SandboxContract<Task4>;
    let deployer: SandboxContract<TreasuryContract>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        task4 = blockchain.openContract(await Task4.fromInit(1n));
        deployer = await blockchain.treasury('deployer');
        const deployResult = await task4.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );
        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: task4.address,
            deploy: true,
            success: true,
        });
    });

    it('test', async () => {
        const message: OwnershipAssigned = {
            $$type: 'OwnershipAssigned',
            queryId: 1n,
            prevOwner: deployer.address,
            forwardPayload: beginCell().storeUint(20,32).asCell(),
        };

        await task4.send(
            deployer.getSender(),
            {
                value: toNano('0.1'),
            },
            message
        );

        const nft = await task4.getNft();
        const time =await  task4.getTime();
        const owner = await task4.getOwner();
        console.log(nft);
        console.log(time);
        console.log(owner);
    });
});
