// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


import "hardhat/console.sol";


contract Crowdsale is Context, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    // The token being sold
    IERC20 private _token;

    // Address where funds are collected
    address payable private _wallet;
    address payable public _manager;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 private _rate;

    // Amount of wei raised
    uint256 private _weiRaised;

    
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    
    
    mapping (address => uint) purchase;
    uint256 current = block.timestamp * 1 seconds;
    uint256 limitationtime = block.timestamp + 7776000   * 1 seconds;
     mapping(address => bool) private _whitelist;
    // address[] private _whitelist;
    //  bool public isFinalized = false;
    //  Manager manager;
    constructor (address[] memory accounts,uint256 rate_, address payable wallet_, IERC20 token_, address payable manager_) {
        require(rate_ > 0, "Crowdsale: rate is 0");
        
        require(address(token_) != address(0), "Crowdsale: token is the zero address");

        for (uint256 i = 0; i < accounts.length; i++) {
            _addPayee(accounts[i]);
        }
        _rate = rate_;
        _wallet = wallet_;
        _token = token_;
        _manager = manager_;
      
    }
    // function sale () public{
    //     uint buy ;
    // }


    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    fallback () external payable {
        buyTokens(_msgSender());
    }

    receive () external payable {
        buyTokens(_msgSender());
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public nonReentrant payable {
        require (_whitelist[_msgSender()] == true);
        require ( limitationtime > block.timestamp, "not running");
        
        uint256 weiAmount = msg.value;
       

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised.add(weiAmount);

       
        _updatePurchasingState(beneficiary, weiAmount);
            purchase[msg.sender]=tokens;
        _forwardFunds();
       
    }

    function claim() public payable {
        require (block.timestamp > limitationtime);

    // address investor = msg.sender;
    
    uint t = purchase[msg.sender];
    
    _processPurchase(msg.sender, t);
    // if(amount == 0) {
    //   throw;
    }
    function balance() public view returns(uint){
        return _token.balanceOf(address(this));
        // at.secfun(a)
        // return at.balanceOf(this)
    }

    function takeTokensBack() public  returns(bool) {
     uint remainingTokensInTheContract = _token.balanceOf(address(this));
     return _token.transfer(address(_manager),remainingTokensInTheContract);
       //selfdestruct(payable (address(this)));
    }

  

    // function end () external{
    //     if(block.timestamp >= limitationtime){
    //         address afr;
    //        return afr=address(manager);
    //     }else{

    //     }
    // }
    
    // function finalization() internal {
    //   token.transferOwnership(msg.sender);
    //   super.finalization();
    // }
    // function finalizeIfNeeded () internal {
    // if (!finalized && block.timestamp >= crowdsaleEndTime) {
    //     finalization ();
    //     finalized = true;
    // }


    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    // function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
    //     require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
    //     require(weiAmount != 0, "Crowdsale: weiAmount is 0");
    //     this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    // }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    // function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
    //     // solhint-disable-previous-line no-empty-blocks
    // }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }

     function _addPayee(address account) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        _whitelist[account]=true;
       
    }
      
}