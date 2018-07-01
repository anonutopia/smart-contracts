pragma solidity ^0.4.21;



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
    modifier _onlyOwner {
        require(msg.sender == owner);
        _;
    }


    /**
     * @notice Transfers token ownership.
     * @param _newOwner Address of the new token owner.
     */
    function transferOwnership(address _newOwner) public _onlyOwner {
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
 * @title Anonutopia's main contract.
 */
contract Anonutopia is Owned {

    mapping(address => string) nicknames;


    /**
     * @notice Sets a nickname for some address. 
     * @param _nick User's nickname.
     */
    function setNickname(string _nick) public {
        nicknames[msg.sender] = _nick;
    }


    /**
     * @notice Gets a nickname of some address. 
     * @return User's nickname
     */
    function getNickname() public view returns (string) {
        return nicknames[msg.sender];
    }

}