// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IERC721} from "openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

contract LoanFacet {
    event LoanOffered(
        address indexed lender,
        address indexed borrower,
        address indexed collateralNFT,
        uint256 collateralTokenId,
        uint256 amount,
        uint256 interestRate,
        uint256 dueDate,
        address repaymentToken
    );
    event LoanOfferCanceled(
        address indexed lender,
        address indexed borrower,
        address indexed collateralNFT,
        uint256 collateralTokenId,
        uint256 amount,
        uint256 interestRate,
        uint256 dueDate,
        address repaymentToken
    );
    event LoanAccepted(
        address indexed borrower,
        address indexed lender,
        address indexed collateralNFT,
        uint256 collateralTokenId,
        uint256 amount,
        uint256 interestRate,
        uint256 dueDate,
        address repaymentToken
    );
    event LoanRepaid(address indexed borrower, uint256 amount);
    event CollateralLocked(
        address indexed user,
        address indexed nftAddress,
        uint256 tokenId
    );
    event Liquidated(
        address indexed borrower,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    function offerLoan(
        uint256 amount,
        uint256 term,
        address collateralNFT,
        uint256 collateralTokenId,
        address repaymentToken,
        uint256 interestRate
    ) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.loans[msg.sender].amount == 0, "Active loan offer exists");
        uint256 dueDate = block.timestamp + term;
        ds.loans[msg.sender] = LibDiamond.Loan(
            msg.sender,
            amount,
            interestRate,
            dueDate,
            false,
            false,
            false,
            repaymentToken
        );
        ds.collaterals[msg.sender] = LibDiamond.Collateral(
            collateralNFT,
            collateralTokenId,
            true
        );
        IERC721(collateralNFT).transferFrom(
            msg.sender,
            address(this),
            collateralTokenId
        );
        emit CollateralLocked(msg.sender, collateralNFT, collateralTokenId);
        emit LoanOffered(
            msg.sender,
            msg.sender,
            collateralNFT,
            collateralTokenId,
            amount,
            interestRate,
            dueDate,
            repaymentToken
        );
    }

    function cancelLoanOffer() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Loan storage loan = ds.loans[msg.sender];
        require(loan.amount > 0, "No active loan offer");
        IERC721(ds.collaterals[msg.sender].nftAddress).transferFrom(
            address(this),
            msg.sender,
            ds.collaterals[msg.sender].tokenId
        );
        ds.collaterals[msg.sender].isDeposited = false;
        emit LoanOfferCanceled(
            msg.sender,
            msg.sender,
            ds.collaterals[msg.sender].nftAddress,
            ds.collaterals[msg.sender].tokenId,
            loan.amount,
            loan.interestRate,
            loan.dueDate,
            loan.repaymentToken
        );
        delete ds.loans[msg.sender];
    }

    function acceptLoan(address lender) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Loan storage loan = ds.loans[lender];
        require(loan.amount > 0, "No active loan offer");
        IERC20(loan.repaymentToken).transfer(lender, loan.amount);
        emit LoanAccepted(
            msg.sender,
            lender,
            ds.collaterals[lender].nftAddress,
            ds.collaterals[lender].tokenId,
            loan.amount,
            loan.interestRate,
            loan.dueDate,
            loan.repaymentToken
        );
        delete ds.loans[lender];
    }

    function repayLoan(address repaymentToken) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Loan storage loan = ds.loans[msg.sender];
        require(!loan.isRepaid, "Loan already repaid");
        uint256 repaymentAmount = loan.amount +
            ((loan.amount * loan.interestRate) / 100);
        require(
            IERC20(repaymentToken).balanceOf(msg.sender) >= repaymentAmount,
            "Insufficient payment"
        );
        IERC20(repaymentToken).transferFrom(
            msg.sender,
            address(this),
            repaymentAmount
        );
        loan.isRepaid = true;
        IERC721(ds.collaterals[msg.sender].nftAddress).transferFrom(
            address(this),
            msg.sender,
            ds.collaterals[msg.sender].tokenId
        );
        ds.collaterals[msg.sender].isDeposited = false;
        emit LoanRepaid(msg.sender, repaymentAmount);
    }

    function liquidate(address borrower) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Loan storage loan = ds.loans[borrower];
        require(block.timestamp > loan.dueDate, "Loan not overdue");
        require(!loan.isRepaid, "Loan already repaid");
        LibDiamond.Collateral storage collateral = ds.collaterals[borrower];
        require(collateral.isDeposited, "No collateral");
        IERC721(collateral.nftAddress).transferFrom(
            address(this),
            msg.sender,
            collateral.tokenId
        );
        collateral.isDeposited = false;
        emit Liquidated(borrower, collateral.nftAddress, collateral.tokenId);
    }
}
