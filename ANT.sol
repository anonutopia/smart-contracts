pragma solidity ^0.4.21;



/**
 * @title Safe maths library for big numbers.
 */
library SafeMath {

    /**
     * @notice Sums two numbers.
     * @param a Number to add to.
     * @param b Number to add.
     * @return Returns the sum of two numbers.
     */
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }


    /**
     * @notice Subtracts two numbers.
     * @param a Number to subtract from.
     * @param b Number to subtract.
     * @return Returns the subtraction of two numbers.
     */
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }


    /**
     * @notice Multiplies two numbers.
     * @param a Number to multiply.
     * @param b Number to multiply by.
     * @return Returns the multiplication of two numbers.
     */
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }


    /**
     * @notice Divides two numbers.
     * @param a Number to divide.
     * @param b Number to divide by.
     * @return Returns the division of two numbers.
     */
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}



/**
 * @title ERC Token Standard #20 Interface.
 * @notice https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 */
contract ERC20Interface {

    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);


    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



/**
 * @title Contract function to receive approval and execute function in one call (borrowed from MiniMeToken).
 */
contract ApproveAndCallFallBack {

    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}



/**
 * @title Owned smart contract.
 */
contract Owned {

    /**
     * @notice Smart ccontract events.
     */
    event OwnershipTransferred(address indexed _from, address indexed _to);


    /**
     * @notice Address of the owner.
     */
    address public owner;


    /**
     * @notice Makes sure that only owner can call the function.
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    /**
     * @notice Transfers token ownership.
     * @param _newOwner Address of the new token owner.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }


    /**
     * @notice Smart contract contstructor.
     */
    function Owned() public {
        owner = msg.sender;
    }
}



/**
 * @title ERC20 token contract.
 */
contract ERC20 is ERC20Interface, Owned {

    /**
     * @notice Libraries for smart contract.
     */
    using SafeMath for uint;


    /**
     * @notice Currency symbol.
     */
    string public symbol;


    /**
     * @notice Currency name.
     */
    string public  name;


    /**
     * @notice Currency decimal places.
     */
    uint8 public decimals;


    /**
     * @notice Currency total supply.
     */
    uint public _totalSupply;


    /**
     * @notice Balances map.
     */
    mapping(address => uint) balances;


    /**
     * @notice Currency allowance.
     */
    mapping(address => mapping(address => uint)) allowed;


    /**
     * @notice Currency total supply.
     * @return Returns number of minted units.
     */
    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }


    /**
     * @notice Get the token balance for account `tokenOwner`.
     * @param tokenOwner Address you're looking the balance for.
     * @return Returns balance for the given address.
     */
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    /**
     * @notice Transfer the balance from token owner's account to `to` account.
     * @param to Address you're sending tokens to.
     * @param tokens Number of tokens you're sending.
     * @return A boolean that indicates if the operation was successful.
     */
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    /**
     * @notice Token owner can approve for `spender` to transferFrom(...) `tokens` from the token owner's account.
     * @param spender Address of the spender you're approving funds for.
     * @param tokens Number of tokens you're approving.
     * @return A boolean that indicates if the operation was successful.
     */
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    /**
     * @notice Transfer `tokens` from the `from` account to the `to` account.
     * @param from Address of the account you're sending funds from.
     * @param to Address of the account you're sending funds to.
     * @param tokens Number of tokens you're transfering.
     * @return A boolean that indicates if the operation was successful.
     */
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    /**
     * @notice Returns the amount of tokens approved by the owner that can be transferred to the spender's account.
     * @param tokenOwner Token owner's address.
     * @param spender Token spender's address.
     * @return Number of remaining tokens to spend.
     */
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    /**
     * @notice Token owner can approve for `spender` to transferFrom(...) `tokens` from the token owner's account. The `spender` contract function `receiveApproval(...)` is then executed
     * @param spender Token spender's address.
     * @param tokens Number of tokens you're approving for spending.
     * @param data Data being sent.
     * @return A boolean that indicates if the operation was successful.
     */
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    /**
     * @notice Don't accept ETH
     */
    function () public payable {
        revert();
    }


    /**
     * @notice Owner can transfer out any accidentally sent ERC20 tokens
     * @param tokenAddress Address of the token you're sending.
     * @param tokens Number of tokens you're sending.
     * @return A boolean that indicates if the operation was successful.
     */
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}



/**
 * @title For accessing crypto fiat contracts.
 */
contract Currency {
    function transferOwnership(address) public pure {}
    function acceptOwnership() public pure {}
    function decimals() public pure returns (uint8) {}
    function mint(address, uint256) public pure returns (bool) {}
    function destroy(address, uint256) public pure returns (bool) {}
}



/**
 * @title Payable smart contract - can receive ETH.
 */
contract Payable {

    /**
     * @notice Constructor which allows us to fund contract on creation.
     */
    function Payable() public payable {
    }
    

    /**
     * @notice `fallback` function called when eth is sent to Payable contract.
     */
    function () public payable {
    }
}



/**
 * @title Mintable ERC20 token contract.
 */
contract MintableToken is ERC20 {

    /**
     * @notice Smart ccontract events.
     */
    event Mint(address indexed to, uint256 amount);
    event Destroy(address indexed from, uint256 amount);


    /**
     * @notice Checks if caller has mint permissions.
     */
    modifier hasMintPermission() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @notice Function to mint tokens.
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) internal returns (bool) {
        _totalSupply = _totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;    
    }


    /**
     * @notice Function to destroy tokens.
     * @param _from The address that we will destroy tokens from.
     * @param _amount The amount of tokens to destroy.
     * @return A boolean that indicates if the operation was successful.
     */
    function destroy(address _from, uint256 _amount) internal returns (bool) {
        if (balances[_from] >= _amount) {
            _totalSupply = _totalSupply.sub(_amount);
            balances[_from] = balances[_from].sub(_amount);
            emit Destroy(_from, _amount);
            return true;
        } else {
            return false;
        }
    }
}



/**
 * @title Main Anote (ANT) smart contract.
 */
contract ANT is MintableToken, Payable {

    /**
     * @notice Libraries for smart contract.
     */
    using SafeMath for uint;
    using SafeMath for uint8;


    /**
     * @notice Telling us if Anote is in stabilization mode.
     */
    bool public switched = false;


        /**
     * @notice Step for increasing Anote buy price.
     */
    uint public priceStep = 10000 szabo;


    /**
     * @notice Anote buy price in EUR.
     */
    uint public priceBuy = priceStep;


    /**
     * @notice Anote sell price in EUR.
     */
    uint public priceSell = 0;


    /**
     * @notice Total deposits in EUR at any given time.
     */
    uint public totalDeposits = 0;


    /**
     * @notice Number of all Anote fundings.
     */
    uint public fundingsNumber = 0;


    /**
     * @notice This holds tier supply.
     */
    uint public tierSupplyHolder = 5000 ether;


    /**
     * @notice Tier counter variable.
     */
    uint public tierSupply = tierSupplyHolder;


    /**
     * @notice This percentage goes for crowdfunding.
     */
    uint public crowdfundingFactor = 20;


    /**
     * @notice This percentage goes to funding referral.
     */
    uint public referralFactor = 20;


    /**
     * @notice This percentage is being held in the contract.
     */
    uint public holdingFactor = 500;


    /**
     * @notice This percentage of Anote has to be backuped up in EUR.
     */
    uint public drainFactor = 500;


    /**
     * @notice Crypto fiat currencies.
     */
    address[] public currencies;


    /**
     * @notice Ant fund balance.
     */
    uint public antBalance;


    /**
     * @notice Crypto fiat fund balance.
     */
    uint public fiatBalance;


    /**
     * @notice Tier counter.
     */
    uint public tierCounter = 0;


    /**
     * @notice Is holding factor increasing or decreasing.
     */
    bool public increaseHoldingFactor = false;


    /**
     * @notice Crypto fiat prices.
     */
    mapping(address => uint) prices;


    /**
     * @notice ANT users.
     */
    address[] users;


    /**
     * @notice Variable used to make some functions state-changing.
     */
    bool changestate = false;


    // ------------------------------------------------------------------------
    // PUBLIC FUNCTIONS
    // ------------------------------------------------------------------------


    /**
     * @notice Creates ANT from ETH.
     * @param _referral Address of the referral user.
     * @return A boolean that indicates if the operation was successful.
     */
    function ethToAnt(address _referral) public payable returns (bool) {
        uint investment = _splitInvestment(msg.value, _referral);
        
        if (investment > 0) {
            totalDeposits = totalDeposits.add(investment);

            _mintAnt(investment);

            _updateSellPrice();

            return true;
        } else {
            return false;
        }
    }


    /**
     * @notice Creates crypto fiat from ETH.
     * @param _currency Address of the fiat currency contract.
     * @return A boolean that indicates if the operation was successful.
     */
    function ethToFiat(address _currency) public payable returns (bool) {
        fiatBalance = fiatBalance.add(msg.value);

        Currency c = Currency(_currency);
        uint8 decimals = c.decimals();
        uint amount = msg.value.mul(uint(10)**decimals).div(prices[_currency]);

        c.mint(msg.sender, amount);

        return true;
    }


    /**
     * @notice Exchanges ANT to ETH.
     * @param _tokenCount Number of ANT tokens to exchange for ETH.
     * @return A boolean that indicates if the operation was successful.
     */
    function antToEth(uint _tokenCount) public returns (bool) {
        if (destroy(msg.sender, _tokenCount)) {
            uint withdrawal = _tokenCount.mul(priceSell).div(1 ether).mul(getCurrencyPrice(getCurrencyAddress(0))).div(1 ether);
            msg.sender.transfer(withdrawal);
            return true;
        } else {
            return false;
        }
    }


    /**
     * @notice Creates crypto fiat from ANT.
     * @param _currency Contract address of crypto fiat to create.
     * @param _tokenCount Number of ANT tokens to exchange for crypto fiat.
     * @return A boolean that indicates if the operation was successful.
     */
    function antToFiat(address _currency, uint _tokenCount) public returns (bool) {
        if (destroy(msg.sender, _tokenCount)) {
            Currency c = Currency(_currency);
            uint8 decimals = c.decimals();
            uint withdrawal = _tokenCount.mul(priceSell).div(1 ether).mul(getCurrencyPrice(getCurrencyAddress(0))).div(1 ether);
            uint amount = withdrawal.mul(uint(10)**decimals).div(getCurrencyPrice(_currency));

            uint ethWithdrawal = _tokenCount.mul(priceSell).div(1 ether);
            antBalance = antBalance.sub(ethWithdrawal);
            fiatBalance = fiatBalance.add(ethWithdrawal);

            c.mint(msg.sender, amount);

            return true;
        } else {
            return false;
        }
    }


    /**
     * @notice Exchanges crypto fiat to ETH.
     * @param _currency Contract address of crypto fiat being exchanged for ETH.
     * @param _tokenCount Number of crypto fiat tokens being exchanged for ETH.
     * @return A boolean that indicates if the operation was successful.
     */
    function fiatToEth(address _currency, uint _tokenCount) public returns (bool) {
        Currency c = Currency(_currency);

        if (c.destroy(msg.sender, _tokenCount)) {
            uint withdrawal = _tokenCount.mul(getCurrencyPrice(_currency)).div(1 ether);
            msg.sender.transfer(withdrawal);
            return true;
        } else {
            return false;
        }
    }


    /**
     * @notice Function to mint ANT from fiat.
     * @param _currency Address of the currency that will be used to mint ANT.
     * @param _tokenCount The amount of tokens to pay for minting.
     * @return A boolean that indicates if the operation was successful.
     */
    function fiatToAnt(address _currency, uint _tokenCount) public returns (bool) {
        Currency c = Currency(_currency);

        if (c.destroy(msg.sender, _tokenCount)) {
            uint investment = _tokenCount.mul(getCurrencyPrice(_currency)).div(getCurrencyPrice(getCurrencyAddress(0)));

            if (investment > 0) {
                totalDeposits = totalDeposits.add(investment);

                _mintAnt(investment);

                uint ethInvestment = _tokenCount.mul(getCurrencyPrice(_currency)).div(1 ether);
                fiatBalance = fiatBalance.sub(ethInvestment);
                _splitInvestment(ethInvestment, address(0));

                _updateSellPrice();

                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }


    /**
     * @notice Function to exchange crypto fiat for another crypto fiat.
     * @param _currencyFrom Contract address of the currency that's being exchanged from.
     * @param _currencyTo Contract address of the currency that's being exchanged to.
     * @param _tokenCount The amount of tokens you have to exchange.
     * @return A boolean that indicates if the operation was successful.
     */
    function fiatToFiat(address _currencyFrom, address _currencyTo, uint _tokenCount) public returns (bool) {
        Currency cf = Currency(_currencyFrom);

        if (cf.destroy(msg.sender, _tokenCount)) {
            Currency ct = Currency(_currencyTo);
            uint amount = _tokenCount.mul(getCurrencyPrice(_currencyFrom)).div(getCurrencyPrice(_currencyTo));
            ct.mint(msg.sender, amount);
            changestate = true;

            return true;
        } else {
            return false;
        }
    }


    /**
     * @notice Updates crypto fiat currency price.
     * @param _currency Crypto fiat currency address.
     * @param _price Crypto fiat currency price in ETH.
     */
    function updateCurrencyPrice(address _currency, uint _price) public onlyOwner {
        prices[_currency] = _price;
    }


    /**
     * @notice Returns fiat currency price in ETH.
     * @param _currency Address of the fiat currency.
     * @return Currency price as uint.
     */
    function getCurrencyPrice(address _currency) view public returns (uint) {
        return prices[_currency];
    }


    /**
     * @notice Returns number of crypto fiat currencies.
     * @return Number of crypto fiat currencies.
     */
    function currenciesCount() view public returns (uint) {
        return currencies.length;
    }


    /**
     * @notice Returns fiat currency contract address.
     * @param _position Crypto fiat currency index.
     * @return Fiat crypto currency contract address.
     */
    function getCurrencyAddress(uint _position) view public returns (address) {
        return currencies[_position];
    }


    /**
     * @notice Registers new fiat currency in ANT contract. 
     * @param _currency Crypto fiat currency address.
     * @param _price Crypto fiat currency price in ETH.
     * @return A boolean that indicates if the operation was successful. 
     */
    function registerCurrency(address _currency, uint _price) public onlyOwner returns (bool) {
        for (uint i = 0; i < currencies.length; i++) {
            if (currencies[i] == _currency) {
                return false;
            }
        }

        currencies.push(_currency);
        prices[_currency] = _price;

        return true;
    }


    /**
     * @notice Checks if ANT user exists.
     * @param _user Address of user to check.
     * @return A boolean that indicates if the users exists. 
     */
    function userExists(address _user) view public returns (bool) {
        for (uint i = 0; i < users.length; i++) {
            if (users[i] == _user) {
                return true;
            }
        }
        return false;
    }


    /**
     * @notice Counts ANT users.
     * @return Count of ANT users.
     */
    function usersCount() view public returns (uint) {
        return users.length;
    }


    /**
     * @notice Returns address of the user.
     * @param _index Index of the user.
     * @return User's address.
     */
    function userGet(uint _index) view public returns (address) {
        return users[_index];
    }


    /**
     * @notice Closes ANT contract passing ETH to the owner. 
     */
    function close() public onlyOwner {
        selfdestruct(owner);
        // owner.transfer(address(this).balance);
    }


    /**
     * @notice Upgrades ANT contract to new version.
     * @param _oldContract Old contract address.
     */
    function upgrade(address _oldContract) public onlyOwner {
        ANT oldAnt = ANT(_oldContract);
        uint cc = oldAnt.currenciesCount();
        uint uc = oldAnt.usersCount();

        for (uint i = 0; i < cc; i++) {
            address currency = oldAnt.getCurrencyAddress(i);
            oldAnt.transferCurrencyOwnership(currency, this);
            registerCurrency(currency, oldAnt.getCurrencyPrice(currency));
        }

        for (i = 0; i < uc; i++) {
            address user = oldAnt.userGet(i);
            users.push(user);
            balances[user] = oldAnt.balanceOf(user);
        }

        _totalSupply = oldAnt._totalSupply();
        switched = oldAnt.switched();
        priceBuy = oldAnt.priceBuy();
        priceSell = oldAnt.priceSell();
        priceStep = oldAnt.priceStep();
        totalDeposits = oldAnt.totalDeposits();
        fundingsNumber = oldAnt.fundingsNumber();
        tierSupply = oldAnt.tierSupply();
        holdingFactor = oldAnt.holdingFactor();
        drainFactor = oldAnt.drainFactor();
        antBalance = oldAnt.antBalance();
        fiatBalance = oldAnt.fiatBalance();
        tierCounter = oldAnt.tierCounter();

        oldAnt.close();
    }


    /**
     * @notice Transfers fiat crypto currency ownership.
     * @param _currency Address of the fiat currency contract.
     * @param _newOwner New owner's address.
     */
    function transferCurrencyOwnership(address _currency, address _newOwner) public onlyOwner {
        Currency c;
        c = Currency(_currency);
        c.transferOwnership(_newOwner);
        changestate = true;
    }

    /**
     * @notice Pulls ANT balance from previous contract version.
     * @param _owner Owner of the address.
     * @param _oldContract Address of the previous contract.
     */
    function pullBalance(address _owner, address _oldContract) public {
        ANT oldAnt = ANT(_oldContract);
        balances[_owner] = oldAnt.balanceOf(_owner);
    }


    // ------------------------------------------------------------------------
    // PRIVATE FUNCTIONS
    // ------------------------------------------------------------------------


    /**
     * @notice Mints new ANT tokens.
     * @param _investment Investment amount in EUR.
     */
    function _mintAnt(uint _investment) private {
        uint _inv = _investment;
        uint _tokenCount = 0;
        uint _tierSupply = tierSupply;
        uint _priceBuy = priceBuy;
        uint _priceStep = priceStep;
        uint _tierSupplyHolder = tierSupplyHolder;
        uint _tierCounter = tierCounter;
        uint _tierInvestment = 0;
        uint _drainFactor = drainFactor;

        while (_inv > 0) {
            _tierInvestment = _inv;

            if (_tierInvestment >= _tierSupply) {
                _tierInvestment = _tierSupply;            
                _inv = _inv.sub(_tierInvestment);
                _tierSupply = _tierSupplyHolder;
                _priceBuy = _priceBuy.add(_priceStep);

                _tierCounter++;

                _priceStep = _updatePriceStep(_priceStep, _tierCounter);
                if (!switched) {
                    _drainFactor = _updateDrainFactor(_tierCounter, _drainFactor);
                }
                _updateHoldingFactor(_tierCounter);
            } else {
                _inv = 0;
                _tierSupply = _tierSupply.sub(_tierInvestment);
            }

            _tokenCount = _tokenCount.add(_tierInvestment.mul(1 ether).div(_priceBuy));
        }

        tierSupply = _tierSupply;
        priceBuy = _priceBuy;
        priceStep = _priceStep;
        tierCounter = _tierCounter;
        drainFactor = _drainFactor;

        if (_tokenCount > 0) {
            mint(msg.sender, _tokenCount);
            fundingsNumber++;
            if (!userExists(msg.sender)) {
                users.push(msg.sender);
            }
        }
    }


    /**
     * @notice Updates price step.
     */
    function _updatePriceStep(uint _priceStep, uint _tierCounter) private pure returns (uint) {
        uint ps = _priceStep;
        if (ps > 100000000000 wei && _tierCounter % 1000 == 0) {
            ps /= 4;
        }
        return ps;
    }


    /**
     * @notice Updates drain factor.
     */
    function _updateDrainFactor(uint _tierCounter, uint _drainFactor) private pure returns (uint) {
        uint df = _drainFactor;
        if (df > 100 && _tierCounter % 10 == 0) {
            df--;
        }
        return df;
    }


    /**
     * @notice Updates holding factor.
     */
    function _updateHoldingFactor(uint _tierCounter) private {
        uint hf = holdingFactor;

        if (_tierCounter % 100 == 0) {
            if (switched) {
                // if (antBalance.mul(1 ether).div(getCurrencyPrice(getCurrencyAddress(0))).div(priceSell.mul(100).div(_totalSupply)) < 10) {
                if (increaseHoldingFactor) {
                    hf++;
                } else if (holdingFactor > 100) {
                    hf--;
                }
            } else {
                if (holdingFactor > 105) {
                    hf--;
                }
            }
        }

        holdingFactor = hf;
    }


    /**
     * @notice Checks if holding factor should be increased for backup purposes.
     */
    function _checkBackup() private {
        if (antBalance.mul(1 ether).div(getCurrencyPrice(getCurrencyAddress(0))).div(priceSell.mul(100).div(_totalSupply)) < 10) {
            increaseHoldingFactor = false;
        } else {
            increaseHoldingFactor = true;
        }
    }


    /**
     * @notice Updates ANT selling price.
     */
    function _updateSellPrice() private {
        if (switched) {
            priceSell = priceBuy.mul(95).div(100);
        } else {
            priceSell = antBalance.mul(1 ether).div(getCurrencyPrice(getCurrencyAddress(0))).mul(1 ether).div(_totalSupply).mul(1000).div(drainFactor);

            if (priceSell.mul(100).div(priceBuy) > 95) {
                priceSell = priceBuy.mul(95).div(100);
                if (totalDeposits > 100000 ether) {
                    switched = true;
                }
            }
        }
    }


    /**
     * @notice Splits investment between appropriate funds.
     * @param investment Investment amount.
     * @param _referral Referral user's address.
     * @return Investment in Euro.
     */
    function _splitInvestment(uint investment, address _referral) private returns (uint) {
        uint eurInvestment = investment.mul(1 ether).div(getCurrencyPrice(getCurrencyAddress(0)));
        uint crowdfundingInvestment = investment.mul(crowdfundingFactor).div(100);
        uint referralInvestment = investment.mul(referralFactor).div(100);
        uint antInvestment = investment.mul(holdingFactor).div(1000);

        owner.transfer(crowdfundingInvestment);

        if (_referral != address(0) && _referral != msg.sender) {
            _referral.transfer(referralInvestment);
        } else {
            antInvestment = antInvestment.add(referralInvestment);
        }

        antBalance = antBalance.add(antInvestment);
    
        return eurInvestment;
    }


    /**
     * @notice ANT constructor.
     */
    function ANT(uint _initialBalance) public payable {
        symbol = "ANT";
        name = "Anote";
        decimals = 18;
        mint(msg.sender, _initialBalance);
    }
}