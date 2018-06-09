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
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
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
}

contract Payable {
    
    // Constructor which allows us to fund contract on creation
    function Payable() public payable {
    }
    
    // `fallback` function called when eth is sent to Payable contract
    function () public payable {
    }
}


// ----------------------------------------------------------------------------
// Anote Contract
// ----------------------------------------------------------------------------
contract Anote is Owned, Payable {
    using SafeMath for uint;

    mapping(address => uint) prices;
    address[] currencies;
    bool transfered = false;

    function transferCurrencyOwnership(address _currency, address _newOwner) public onlyOwner {
        Currency c;
        c = Currency(_currency);
        c.transferOwnership(_newOwner);
        transfered = true;
    }

    function fundAndMint(address _currency) public payable returns (bool) {
        Currency c;
        uint amount;
        uint8 decimals;

        c = Currency(_currency);
        decimals = c.decimals();
        amount = msg.value.mul(uint(10)**decimals).div(prices[_currency]);

        c.mint(msg.sender, amount);

        return true;
    }

    function updateCurrencyPrice(address _currency, uint _price) public returns (bool) {
        prices[_currency] = _price;
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
}