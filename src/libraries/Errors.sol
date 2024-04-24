// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// FIXME: seggregate errors
library Errors {
  /*********************************************************** */
  /****************************RBAC*************************** */
  /*********************************************************** */
  string public constant CALLER_NOT_ADMIN = "CALLER_NOT_ADMIN"; // 'The caller of the function is not a pool admin'
  string public constant CALLER_NOT_OWNER = "CALLER_NOT_OWNER"; // 'The caller of the function is not a pool admin'
  string public constant ACCESS_RESTRICTED = "ACCESS_RESTRICTED"; // 'The caller of the function is not a pool admin'

  // ********************************************* STAKE *********************************************

  string public constant WRONG_LP = "WRONG_LP";
  string public constant NOT_CLAIMABLE_YET = "NOT_CLAIMABLE_YET";
  string public constant NOT_UNSTAKABLE_YET = "NOT_UNSTAKABLE_YET";
  string public constant LOW_LOCK_DURATION = "LOW_LOCK_DURATION";

  // ********************************************* LOW BALANCE && CALCULATION *********************************************

  string public constant LOW_BNB_BALANCE = "LOW_BNB_BALANCE";
  string public constant LOW_ALLOWANCE = "LOW_ALLOWANCE";
  string public constant INSUFFICIENT_AMOUNT = "INSUFFICIENT_AMOUNT";
  string public constant AMOUNT_ZERO = "AMOUNT_SHOULD_BE_GREATER_THAN_ZERO";
  string public constant LOW_BALANCE_IN_CONTRACT = "LOW_BALANCE_IN_CONTRACT";
  string public constant AOB = "ARRAY_INDEX_OUT_OF_BOUND";

  // ********************************************* POOL *********************************************

  string public constant POOL_NOT_CREATED = "POOL_IS_NOT_CREATED_YET";
  string public constant USER_IS_DISABLED = "USER_IS_DISABLED";
  string public constant USER_IS_LOCKED = "USER_IS_LOCKED_YET";


}
