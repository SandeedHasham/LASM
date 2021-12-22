// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "../math/SafeMath.sol";
import "hardhat/console.sol";
import "./CrowdSale.sol";

contract Manager is Context, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
   
    IERC20 token;
    address public crowdsale_addr ;
    address public presale_addr ;
    address public ico_addr ;


    uint256 private constant cap = 10  ** 18  ;
    uint256 public durationCap = block.timestamp + 94694400 * 1 seconds;
    uint256 totalSuply;
    uint256 public unlock;
    uint256 public spend;
    uint256 public psale;
       
    constructor(address token_,address owner_){
        transferOwnership(owner_);
        token = ERC20(token_);
        lock();
        spend=0;
        
    }
    

    receive () external payable {}

    function transferCheck(uint256 amount) internal view returns(bool){
        uint256 current = block.timestamp * 1 seconds;

        if(current < durationCap){
          //  uint256 remaining = cap - token.balanceOf(address(this));

            if(spend+amount <= unlock){
                return true;
        }
        else{
            return false;
        }
        
        }
       else{
           return true;
       }
    }
    function balance() public view returns(uint256){
        return token.balanceOf(address(this));
    }
    

    function lock() public {
        uint256 success = (cap*40)/100;
        unlock = cap - success;    
    }
// token.totalSupply()+amount <= cap-success
    function transfer(
        address recipient,
        uint256 amount
    ) public payable virtual onlyOwner {
        require(transferCheck(amount)==true , "cannot transfer :: TOKEN LOCKED");
         token.safeTransfer(recipient, amount);
         spend = spend + amount;
    }

   function create_Presale(address[] memory accounts,uint rate,address payable wallet_ ,uint256 min) public onlyOwner{
       Crowdsale preSale;
       psale = (cap*3)/100;
       preSale = new Crowdsale(accounts,rate,wallet_,IERC20(address(token)),payable (address(this)),min,psale);    
       presale_addr = address(preSale);
       transfer (presale_addr,psale);
    }

    function create_ICO(address[] memory accounts,uint rate,address payable wallet,uint256 min)public onlyOwner{
        Crowdsale ico;
        psale = (cap*12)/100;
        ico = new Crowdsale(accounts,rate,wallet,IERC20(address(token)),payable (address(this)),min,psale);
        ico_addr = address(ico);
        transfer (ico_addr,psale);
    } 
    
    } 

     

}

//all erc20 transfer functionality
//start-finalize preSale
//start-finalize ICO

