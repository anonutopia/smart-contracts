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
 * @title AUSD Token 
 */
contract AUSD is MintableToken {

    /**
     * @notice AUSD constructor.
     */
    function AUSD() public {
        symbol = "AUSD";
        name = "CryptoDollar";
        decimals = 18;
    }
}