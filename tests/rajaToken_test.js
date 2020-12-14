const Web3 = require('web3');
const SampleToken = artifacts.require('SampleToken');
const SimpleToken = artifacts.require('SimpleToken');

contract('SampleToken', (accounts) => {
    var sampleToken;
    var oldContract;

    before(async () => {
        sampleToken = await SampleToken.new();
        await sampleToken.__SampleToken_init('21000000000000000000000000', {from: accounts[0]});
        //Create old contract
        oldContract = await SimpleToken.new({from: accounts[0]});
        //set old contract
        await sampleToken.setOldContract(oldContract.address);
        await sampleToken.setFeeReceiver(accounts[3]);
    });

    it('Is owned by creator', (done) => {
        sampleToken.owner().then((returnedOwner) => {
            assert.equal(returnedOwner, accounts[0], 'Owner should be owner')
            done()
        })
    });

    it('Get owner balance', (done) => {
        sampleToken.balanceOf(accounts[0]).then((balance) => {
            assert.equal(balance, '21000000000000000000000000', 'Invalid owner balance')
            done()
        })
    });

    it('Get user balance before migration', async () => {
        //Set old balance
        const value = '100000000000000000000';
        await oldContract.transfer(accounts[1], value, {from: accounts[0]});
        //Get balance through sampleToken to oldContract
        const actualBalance = await sampleToken.balanceOf(accounts[1]);
        assert.equal(actualBalance, value, 'Invalid user balance');
    });

    it('Transfer before migration', async () => {
        const value = '100000000000000000000';
        await sampleToken.transfer(accounts[2], value, {from: accounts[1]});
        const actualBalance = await sampleToken.balanceOf(accounts[2]);
        assert.equal(actualBalance, value, 'Invalid user balance');
    });


    it('transfer after migration', async () => {
        const receiverInitBalance = await sampleToken.balanceOf(accounts[1]);
        const senderInitBalance = await sampleToken.balanceOf(accounts[2]);
        const value = web3.utils.toWei('10', 'ether');
        await sampleToken.transfer(accounts[1], value, {from: accounts[2]});
        const receiverFinalBalance = await sampleToken.balanceOf(accounts[1]);
        const senderFinalBalance = await sampleToken.balanceOf(accounts[2]);
        assert.equal(receiverFinalBalance.toString(), new web3.utils.BN(value).add(receiverInitBalance).toString(), 
            'Receiver invalid balance after transfer');
        assert.equal(senderFinalBalance.toString(), senderInitBalance.sub(new web3.utils.BN(value)).toString(), 
            'Sender invalid balance after transfer');
    });

    it('sample transfer without fee', async () => {
        const receiverInitBalance = await sampleToken.balanceOf(accounts[2]);
        const senderInitBalance = await sampleToken.balanceOf(accounts[1]);
        const value = web3.utils.toWei('1', 'ether');
        const fee = web3.utils.toWei('1', 'ether');
        await sampleToken.sampleTransfer(accounts[1], accounts[2], value, '0', {from: accounts[0]});
        const receiverFinalBalance = await sampleToken.balanceOf(accounts[2]);
        const senderFinalBalance = await sampleToken.balanceOf(accounts[1]);
        assert.equal(receiverFinalBalance.toString(), new web3.utils.BN(value).add(receiverInitBalance).toString(), 
            'Receiver invalid balance after sample transfer without fee');
        assert.equal(senderFinalBalance.toString(), senderInitBalance.sub(new web3.utils.BN(value)).toString(), 
            'Sender invalid balance after sample transfer without fee');
    });

    it('sample transfer with fee', async () => {
        const receiverInitBalance = await sampleToken.balanceOf(accounts[2]);
        const senderInitBalance = await sampleToken.balanceOf(accounts[1]);
        const value = web3.utils.toWei('1', 'ether');
        const fee = web3.utils.toWei('1', 'gwei');
        await sampleToken.setFee(5, 1000, {from: accounts[0]});
        await sampleToken.sampleTransfer(accounts[1], accounts[2], value, fee, {from: accounts[0]});
        const receiverFinalBalance = await sampleToken.balanceOf(accounts[2]);
        const senderFinalBalance = await sampleToken.balanceOf(accounts[1]);
        const expectedSenderBalance = senderInitBalance.sub(new web3.utils.BN(value)).sub(new web3.utils.BN(fee));
        assert.equal(receiverFinalBalance.toString(), new web3.utils.BN(value).add(receiverInitBalance).toString(), 
            'Receiver invalid balance after sample transfer with fee');
        assert.equal(senderFinalBalance.toString(), expectedSenderBalance.toString(), 
            'Sender invalid balance after sample transfer with fee');
    });
})
