pragma solidity ^0.4.15;

contract BettingContract {
	/* Standard state variables */
	address owner;
	address public gamblerA;
	address public gamblerB;
	address public oracle;
	uint[] private outcomes;

	/* Structs are custom data structures with self-defined parameters */
	struct Bet {
		uint outcome;
		uint amount;
		bool initialized;
	}

	/* Keep track of every gambler's bet */
	mapping (address => Bet) bets;
	/* Keep track of every player's winnings (if any) */
	mapping (address => uint) winnings;

	/* Add any events you think are necessary */
	event BetMade(address gambler);
	event BetClosed();

	/* Uh Oh, what are these? */
	modifier OwnerOnly() {
		require(msg.sender == owner);
		_;
	}
	modifier OracleOnly() {
		require(msg.sender == oracle);
		_;
	}

	/* Constructor function, where owner and outcomes are set */
	function BettingContract(uint[] _outcomes) {
		//The contract owner must define all possible outcomes from the start
		owner = msg.sender;
		outcomes = _outcomes;
	}

	/* Owner chooses their trusted Oracle */
	function chooseOracle(address _oracle) OwnerOnly() returns (address) {
		//The contract owner must be able to assign an oracle; the oracle cannot be a gambler or later place a bet
		oracle = _oracle;
	}

	/* Gamblers place their bets, preferably after calling checkOutcomes */
	function makeBet(uint _outcome) payable returns (bool) {
		//Each gambler can only bet once
		//The contract owner cannot be a gambler
		if(gamblerA==0 || gamblerB==0){
			if(msg.sender!=owner && msg.sender!=oracle && msg.sender!=gamblerA && msg.sender!=gamblerB){
				bets[msg.sender] = Bet(_outcome, msg.value, true);
				if(gamblerA!=0){
					gamblerA=msg.sender;
				} else {
					gamblerB=msg.sender;
				}
				BetMade(msg.sender);
				return true;
			}
		}
		return false;
	}

	/* The oracle chooses which outcome wins */
	function makeDecision(uint _outcome) OracleOnly() {
		//The oracle may choose the correct outcome only after all gamblers have placed their bets
		//If all gamblers bet on the same outcome, reimburse all gamblers their funds
		//If no gamblers bet on the correct outcome, the oracle wins the sum of the funds
		if(gamblerA!=0 || gamblerB!=0){
			uint outcomeA = bets[gamblerA].outcome;
			uint outcomeB = bets[gamblerB].outcome;
			if(outcomeA!=outcomeB){
				if(outcomeA!=_outcome && outcomeB!=_outcome){
					oracle.transfer(outcomeA+outcomeB);
				} else {
					if(outcomeA==_outcome){
						winnings[gamblerA]=bets[gamblerA].amount;
					}
					if(outcomeB==_outcome){
						winnings[gamblerB]=bets[gamblerB].amount;
					}
				}
			}
		}
		BetClosed();
	}

	/* Allow anyone to withdraw their winnings safely (if they have enough) */
	function withdraw(uint withdrawAmount) returns (uint remainingBal) {
		//WARNING: Avenue of attack via DDOS
		uint currentAmount = 0;
		currentAmount = winnings[msg.sender];
		if(withdrawAmount<=currentAmount){
			winnings[msg.sender]=currentAmount-withdrawAmount;
			msg.sender.transfer(withdrawAmount);
		}
		remainingBal = winnings[msg.sender];
		return remainingBal;
	}

	/* Allow anyone to check the outcomes they can bet on */
	function checkOutcomes() constant returns (uint[]) {
		return outcomes;
	}

	/* Allow anyone to check if they won any bets */
	function checkWinnings() constant returns(uint) {
		return winnings[msg.sender];
	}

	/* Call delete() to reset certain state variables. Which ones? That's upto you to decide */
	function contractReset() private {
		delete(bets[gamblerA]);
		delete(bets[gamblerB]);
		delete(winnings[gamblerA]);
		delete(winnings[gamblerB]);
		delete(owner);
		delete(gamblerA);
		delete(gamblerB);
		delete(oracle);
		delete(outcomes);
	}

	/* Fallback function */
	function() {
		revert();
	}
}
