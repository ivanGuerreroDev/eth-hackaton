// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

struct Worker{
  address id;
  string name;
  string dni;
  // Salary is a uint de last 2 digits are decimals
  uint256 salary;
}