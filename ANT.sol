pragma solidity ^0.4.21;


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
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


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
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


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
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


// ----------------------------------------------------------------------------
// ERC20 Token
// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
// Currency contract for communication for real fiat currencies
// ----------------------------------------------------------------------------
contract Currency {
    function transferOwnership(address) public pure {}
    function acceptOwnership() public pure {}
    function decimals() public pure returns (uint8) {}
    function mint(address, uint256) public pure returns (bool) {}
    function destroy(address, uint256) public pure returns (bool) {}
}

contract Payable {
    
    // Constructor which allows us to fund contract on creation
    function Payable() public payable {
    }
    
    // `fallback` function called when eth is sent to Payable contract
    function () public payable {
    }
}

contract MintableToken is ERC20 {
    event Mint(address indexed to, uint256 amount);

    modifier hasMintPermission() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Function to mint tokens
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
}


// ----------------------------------------------------------------------------
// ANT Token
// ----------------------------------------------------------------------------
contract ANT is MintableToken, Payable {
    using SafeMath for uint;
    using SafeMath for uint8;

    mapping(address => uint) prices;
    address[] currencies;
    address[] users;
    address constant AEURAddress = 0xc85C11976Df43eAb7b5C4F23D8De747320E03b2E;

    bool transfered = false;
    uint8 tierCounterPrice = 0;
    uint8 tierCounterHolding = 0;
    uint8 tierCounterDrain = 0;

    bool public switched = false;
    uint public priceBuy = 100 szabo;
    uint public priceSell = 0;
    uint public priceStep = 10000 szabo;
    uint public totalDeposits = 0;
    uint public fundingsNumber = 0;
    uint public tierSupplyHolder = 64000 ether;
    uint public tierSupply = tierSupplyHolder;
    uint8 public crowdfundingFactor = 20;
    uint8 public referralFactor = 10;
    uint16 public holdingFactor = 500;
    uint16 public drainFactor = 500;

    function transferCurrencyOwnership(address _currency, address _newOwner) public onlyOwner {
        Currency c;
        c = Currency(_currency);
        c.transferOwnership(_newOwner);
        transfered = true;
    }

    function fundAndMint(address _referral) public payable returns (bool) {
        uint investment = msg.value.mul(1 ether).div(getCurrencyPrice(AEURAddress));
        totalDeposits = totalDeposits.add(investment);
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
        if (_referral != address(0) && _referral != msg.sender) {
            balances[_referral] = balances[_referral].add(tokenCount.div(5));
            _totalSupply = _totalSupply.add(tokenCount.div(5));
            if (!userExists(_referral)) {
                users.push(_referral);
            }
            _referral.transfer(msg.value.mul(referralFactor).div(100));
        }

        emit Mint(msg.sender, tokenCount);
        _totalSupply = _totalSupply.add(tokenCount);
        owner.transfer(msg.value.mul(crowdfundingFactor).div(100));
        fundingsNumber++;

        if (switched) {
            priceSell = priceBuy.mul(95).div(100);
        } else {
            priceSell = address(this).balance.mul(1 ether).div(getCurrencyPrice(AEURAddress)).mul(1 ether).div(_totalSupply).mul(1000).div(drainFactor);

            if (priceSell.mul(100).div(priceBuy) > 95 && _totalSupply > 64000 ether) {
                switched = true;
            }
        }

        return true;
    }

    function withdraw(uint tokenCount) public returns (bool) {
        if (balances[msg.sender] >= tokenCount) {
            uint withdrawal = tokenCount.mul(priceSell).div(1 ether).mul(getCurrencyPrice(AEURAddress)).div(1 ether);
            balances[msg.sender] = balances[msg.sender].sub(tokenCount);
            _totalSupply = _totalSupply.sub(tokenCount);
            msg.sender.transfer(withdrawal);
            return true;
        } else {
            return false;
        }
    }

    function createCryptoFiat(address _currency) public payable returns (bool) {
        Currency c;
        uint amount;
        uint8 decimals;

        c = Currency(_currency);
        decimals = c.decimals();
        amount = msg.value.mul(uint(10)**decimals).div(prices[_currency]);

        c.mint(msg.sender, amount);

        return true;
    }

    function destroyCryptoFiat(address _currency, uint _tokenCount) public returns (bool) {
        if (balances[msg.sender] >= _tokenCount) {
            Currency c;
            c = Currency(_currency);
            if (c.destroy(msg.sender, _tokenCount)) {
                uint withdrawal = _tokenCount.mul(getCurrencyPrice(AEURAddress)).div(1 ether);
                msg.sender.transfer(withdrawal);
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    function updateCurrencyPrice(address _currency, uint _price) public onlyOwner returns (bool) {
        prices[_currency] = _price;
    }

    function getCurrencyPrice(address _currency) view public returns (uint) {
        return prices[_currency];
    }

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

    function userExists(address user) view public returns (bool) {
        for (uint i = 0; i < users.length; i++) {
            if (users[i] == user) {
                return true;
            }
        }
        return false;
    }

    function usersCount() view public returns (uint) {
        return users.length;
    }

    function close() public onlyOwner {
        selfdestruct(owner);
    }

    function upgrade(address _newContract) public onlyOwner {
        ANT newAnt;
        newAnt = ANT(_newContract);

        for (uint i = 0; i < currencies.length; i++) {
            transferCurrencyOwnership(currencies[i], _newContract);
            newAnt.registerCurrency(currencies[i], getCurrencyPrice(currencies[i]));
        }
        selfdestruct(_newContract);
    }

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function ANT() public payable {
        symbol = "ANT";
        name = "Anote";
        decimals = 18;
    }
}