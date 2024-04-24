// SPDX-License-Identifier: MIT-1.1
pragma solidity ^0.8.0;

library Time {
  uint256 public constant ONE_SECOND = 1;
  uint256 public constant ONE_MINUTE = 60 * ONE_SECOND;
  uint256 public constant ONE_HOUR = 60 * ONE_MINUTE;
  // uint256 public constant ONE_DAY = 24 * ONE_HOUR;
  uint256 public constant ONE_DAY = ONE_SECOND;
  uint256 public constant ONE_WEEK = 7 * ONE_DAY;
  // uint256 public constant ONE_MONTH_OF_30 = 30 * ONE_DAY;
  // uint256 public constant ONE_MONTH_OF_31 = 31 * ONE_DAY;
  uint256 public constant ONE_MONTH_OF_30 = 60 * ONE_DAY;
  uint256 public constant ONE_MONTH_OF_31 = 60 * ONE_DAY;
  uint256 public constant TWO_MONTH = ONE_MONTH_OF_31 + ONE_MONTH_OF_30;
  uint256 public constant THREE_MONTH = (2 * ONE_MONTH_OF_31) + (ONE_MONTH_OF_30);
  uint256 public constant FOUR_MONTH = (2 * ONE_MONTH_OF_31) + (2 * ONE_MONTH_OF_30);
  uint256 public constant FIVE_MONTH = (3 * ONE_MONTH_OF_31) + (2 * ONE_MONTH_OF_30);
  uint256 public constant SIX_MONTH = (3 * ONE_MONTH_OF_31) + (3 * ONE_MONTH_OF_30);
  uint256 public constant SEVEN_MONTH = (4 * ONE_MONTH_OF_31) + (3 * ONE_MONTH_OF_30);
  uint256 public constant EIGHT_MONTH = (4 * ONE_MONTH_OF_31) + (4 * ONE_MONTH_OF_30);
  uint256 public constant NINE_MONTH = (5 * ONE_MONTH_OF_31) + (4 * ONE_MONTH_OF_30);
  uint256 public constant TEN_MONTH = (5 * ONE_MONTH_OF_31) + (5 * ONE_MONTH_OF_30);
  uint256 public constant ELEVEN_MONTH = (6 * ONE_MONTH_OF_31) + (5 * ONE_MONTH_OF_30);
  uint256 public constant TWELVE_MONTH = (7 * ONE_MONTH_OF_31) + (5 * ONE_MONTH_OF_30);
  // uint256 public constant ONE_YEAR = 365 * ONE_DAY;
  uint256 public constant ONE_YEAR = 12 * 60 * ONE_DAY;
  uint256 public constant TWO_YEAR = 2 * ONE_YEAR;
  uint256 public constant ONE_LEAP_YEAR = 366 * ONE_DAY;
  uint256 public constant ONE_YEAR_RAW = 31536000;
  uint256 public constant FIVE_YEAR = 4 * ONE_YEAR + ONE_LEAP_YEAR;
}
