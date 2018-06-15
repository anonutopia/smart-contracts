pragma solidity ^0.4.21;



/**
 * @title Safe maths library for big numbers.
 */
library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }


    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }


    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }


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

    address public owner;


    event OwnershipTransferred(address indexed _from, address indexed _to);


    function Owned() public {
        owner = msg.sender;
    }


    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}



/**
 * @title ERC20 token contract.
 */
contract ERC20 is ERC20Interface, Owned {

    using SafeMath for uint;


    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;


    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
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
    function mint(address _to, uint256 _amount) hasMintPermission public returns (bool) {
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
    function destroy(address _from, uint256 _amount) hasMintPermission public returns (bool) {
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
     * @notice Anote buy price in EUR.
     */
    uint public priceBuy = 100 szabo;


    /**
     * @notice Anote sell price in EUR.
     */
    uint public priceSell = 0;


    /**
     * @notice Step for increasing Anote buy price.
     */
    uint public priceStep = 10000 szabo;


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
    uint public tierSupplyHolder = 64000 ether;


    /**
     * @notice Tier counter variable.
     */
    uint public tierSupply = tierSupplyHolder;


    /**
     * @notice This percentage goes for crowdfunding.
     */
    uint8 public crowdfundingFactor = 20;


    /**
     * @notice This percentage goes to funding referral.
     */
    uint8 public referralFactor = 10;


    /**
     * @notice This percentage is being held in the contract.
     */
    uint16 public holdingFactor = 500;


    /**
     * @notice This percentage of Anote has to be backuped up in EUR.
     */
    uint16 public drainFactor = 500;


    /**
     * @notice Crypto fiat prices.
     */
    mapping(address => uint) prices;


    /**
     * @notice Crypto fiat currencies.
     */
    address[] currencies;


    /**
     * @notice ANT users.
     */
    address[] users;


    /**
     * @notice AEUR crypt fiat contract address.
     */
    address constant AEURAddress = 0xc85C11976Df43eAb7b5C4F23D8De747320E03b2E;


    /**
     * @notice Variable used to make some functions state-changing.
     */
    bool transfered = false;


    /**
     * @notice Tier counter for increasing price.
     */
    uint8 tierCounterPrice = 0;


    /**
     * @notice Tier counter for decreasing holding factor.
     */
    uint8 tierCounterHolding = 0;


    /**
     * @notice Tier counter for decreasing backup factor.
     */
    uint8 tierCounterDrain = 0;


    // ------------------------------------------------------------------------
    // PUBLIC FUNCTIONS
    // ------------------------------------------------------------------------


    /**
     * @notice Creates ANT from ETH.
     * @param _referral Address of the referral user.
     * @return A boolean that indicates if the operation was successful.
     */
    function ethToAnt(address _referral) public payable returns (bool) {
        uint investment = msg.value.mul(1 ether).div(getCurrencyPrice(AEURAddress));
        
        if (investment > 0) {
            totalDeposits = totalDeposits.add(investment);

            uint tokenCount = _mintAnt(investment);
            _handleReferral(_referral, tokenCount);
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
            uint withdrawal = _tokenCount.mul(priceSell).div(1 ether).mul(getCurrencyPrice(AEURAddress)).div(1 ether);
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
            uint withdrawal = _tokenCount.mul(priceSell).div(1 ether).mul(getCurrencyPrice(AEURAddress)).div(1 ether);
            uint amount = withdrawal.mul(uint(10)**decimals).div(getCurrencyPrice(_currency));

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
     * @param _referral Address of the referral.
     * @return A boolean that indicates if the operation was successful.
     */
    function fiatToAnt(address _currency, uint _tokenCount) public returns (bool) {
        Currency c = Currency(_currency);

        if (c.destroy(msg.sender, _tokenCount)) {
            uint investment = tokenCount.mul(getCurrencyPrice(_currency)).div(getCurrencyPrice(AEURAddress));

            if (investment > 0) {
                totalDeposits = totalDeposits.add(investment);

                uint tokenCount = _mintAnt(investment);
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
            uint amount = _tokenCount.mul(getCurrencyPrice(_currencyFrom)).div(getCurrencyPrice(_currencyTo));

            ct.mint(msg.sender, amount);

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
     * @notice Closes ANT contract passing ETH to the owner. 
     */
    function close() public onlyOwner {
        selfdestruct(owner);
    }


    /**
     * @notice Upgrades ANT contract to new version.
     * @param _newContract New contract address.
     */
    function upgrade(address _newContract) public onlyOwner {
        ANT newAnt;
        newAnt = ANT(_newContract);

        for (uint i = 0; i < currencies.length; i++) {
            _transferCurrencyOwnership(currencies[i], _newContract);
            newAnt.registerCurrency(currencies[i], getCurrencyPrice(currencies[i]));
        }
        selfdestruct(_newContract);
    }


    // ------------------------------------------------------------------------
    // PRIVATE FUNCTIONS
    // ------------------------------------------------------------------------


    /**
     * @notice Mints new ANT tokens.
     * @param _investment Investment amount in EUR.
     * @return A boolean that indicates if the operation was successful.
     */
    function _mintAnt(uint _investment) private onlyOwner returns (uint) {
        uint investment = _investment;
        uint tokenCount = 0;

        while (investment > 0) {
            uint tierTokenCount = investment.div(priceBuy).mul(1 ether);
            if (tierTokenCount >= tierSupply) {
                tierTokenCount = tierSupply;
                investment = investment.sub(tierTokenCount.div(10**18).mul(priceBuy));
                
                tierSupply = tierSupplyHolder;
                priceBuy = priceBuy.add(priceStep);

                tierCounterPrice++;
                tierCounterHolding++;
                tierCounterDrain++;

                if (priceStep > 100000000 wei && tierCounterPrice == 1000) {
                    tierCounterPrice = 0;
                    priceStep /= 4;
                    if (tierSupplyHolder > 100 ether) {
                        tierSupplyHolder /= 2;
                    }
                }

                if (drainFactor > 10 && tierCounterDrain == 10) {
                    tierCounterDrain = 0;
                    drainFactor--;
                }

                if (switched) {
                    if (tierCounterHolding == 100) {
                        tierCounterHolding = 0;
                        if (address(this).balance.mul(1 ether).div(getCurrencyPrice(AEURAddress)).div(priceSell.mul(100).div(_totalSupply)) < 10) {
                            holdingFactor++;
                        } else if (holdingFactor > 10) {
                            holdingFactor--;
                        }
                    }
                } else {
                    if (holdingFactor > 105 && tierCounterHolding == 100) {
                        tierCounterHolding = 0;
                        holdingFactor--;
                    }
                }
            } else {
                investment = 0;
                tierSupply = tierSupply.sub(tierTokenCount);
            }
            tokenCount = tokenCount.add(tierTokenCount);
        }

        if (!userExists(msg.sender)) {
            users.push(msg.sender);
        }

        balances[msg.sender] = balances[msg.sender].add(tokenCount);

        emit Mint(msg.sender, tokenCount);
        _totalSupply = _totalSupply.add(tokenCount);
        owner.transfer(msg.value.mul(crowdfundingFactor).div(100));
        fundingsNumber++;

        return tokenCount;
    }


    /**
     * @notice Updates ANT selling price.
     */
    function _updateSellPrice() private onlyOwner {
        if (switched) {
            priceSell = priceBuy.mul(95).div(100);
        } else {
            priceSell = address(this).balance.mul(1 ether).div(getCurrencyPrice(AEURAddress)).mul(1 ether).div(_totalSupply).mul(1000).div(drainFactor);

            if (priceSell.mul(100).div(priceBuy) > 95 && _totalSupply > 64000 ether) {
                switched = true;
            }
        }
    }


    /**
     * @notice Updates referral's balance if needed. 
     * @param _referral Referral user's address.
     */
    function _handleReferral(address _referral, uint _tokenCount) private onlyOwner {
        if (_referral != address(0) && _referral != msg.sender) {
            balances[_referral] = balances[_referral].add(_tokenCount.div(5));
            _totalSupply = _totalSupply.add(_tokenCount.div(5));
            if (!userExists(_referral)) {
                users.push(_referral);
            }
            _referral.transfer(msg.value.mul(referralFactor).div(100));
        }
    }


    /**
     * @notice Transfers fiat crypto currency ownership.
     * @param _currency Address of the fiat currency contract.
     * @param _newOwner New owner's address.
     */
    function _transferCurrencyOwnership(address _currency, address _newOwner) private onlyOwner {
        Currency c;
        c = Currency(_currency);
        c.transferOwnership(_newOwner);
        transfered = true;
    }


    /**
     * @notice ANT constructor.
     */
    function ANT() public payable {
        symbol = "ANT";
        name = "Anote";
        decimals = 18;
    }
}