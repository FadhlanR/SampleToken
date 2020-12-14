const Web3 = require('web3');
const SampleToken = artifacts.require('SampleToken');
const SimpleToken = artifacts.require('SimpleToken');

contract('StakingWallet', (accounts) => {
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

        //migration
        const balanceAccount1 = '100000000000000000000';
        const balanceAccount2 = '50000000000000000000';
        await oldContract.transfer(accounts[1], balanceAccount1, {from: accounts[0]});
        await sampleToken.transfer(accounts[2], balanceAccount2, {from: accounts[1]});
        
        //Set wallet bonus
        await sampleToken.setWalletBonus(accounts[3]);
        await sampleToken.transfer(accounts[3], '100000000000000000000', {from: accounts[0]})
    });

    it('start staking', async () => {
        const staking = await sampleToken.staking(accounts[1], '100000000000000000000', '18000000000000000000', '180');
        const totalStaking = await sampleToken.countStakingBalance(accounts[1]);
        const stakingInfo = await sampleToken.stakingBalanceInfo(accounts[1], '0');
        const dayToSecond = new web3.utils.BN('86400');
        assert.equal(totalStaking, '1', 'invalid total staking');
        assert.equal(stakingInfo.amount, '100000000000000000000', 'invalid amount staking');
        assert.equal(stakingInfo.bonusAmount, '18000000000000000000', 'invalid bonus amount staking');
        assert.equal(stakingInfo.endDate.sub(stakingInfo.startDate).div(dayToSecond), '180', 'invalid duration staking');
        assert.equal(stakingInfo.totalBonusReleased, '0', 'invalid bonus released');
    });

    it('start staking 2', async () => {
        const staking = await sampleToken.staking(accounts[1], '100000000000000000000', '18000000000000000000', '180');
        const totalStaking = await sampleToken.countStakingBalance(accounts[1]);
        const stakingInfo = await sampleToken.stakingBalanceInfo(accounts[1], '0');
        const dayToSecond = new web3.utils.BN('86400');
        assert.equal(totalStaking, '1', 'invalid total staking');
        assert.equal(stakingInfo.amount, '100000000000000000000', 'invalid amount staking');
        assert.equal(stakingInfo.bonusAmount, '18000000000000000000', 'invalid bonus amount staking');
        assert.equal(stakingInfo.endDate.sub(stakingInfo.startDate).div(dayToSecond), '180', 'invalid duration staking');
        assert.equal(stakingInfo.totalBonusReleased, '0', 'invalid bonus released');
    });

    it('calculate daily bonus 1 day', async () => {
        var dateReleased = new Date(); 
        dateReleased.setDate(dateReleased.getDate() + 1)
        
        const actualBonusDaily = await sampleToken.calculateDailyBonus(accounts[1], '0', String(Math.floor(dateReleased / 1000)));
        const expectedBonusDaily = new web3.utils.BN('100000000000000000');
        assert.equal(actualBonusDaily.toString(), expectedBonusDaily.toString(), 'Invalid daily bonus calculation');
    });

    it('calculate daily bonus 15 day', async () => {
        var dateReleased = new Date(); 
        dateReleased.setDate(dateReleased.getDate() + 15)
        
        const actualBonusDaily = await sampleToken.calculateDailyBonus(accounts[1], '0', String(Math.floor(dateReleased / 1000)));
        const expectedBonusDaily = new web3.utils.BN('1500000000000000000');
        assert.equal(actualBonusDaily.toString(), expectedBonusDaily.toString(), 'Invalid daily bonus calculation');
    });

})
