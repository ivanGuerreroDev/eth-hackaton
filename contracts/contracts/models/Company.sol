// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import './Worker.sol';

struct Company{
  uint256 id;
  address owner;
  string name;
  uint256 balance;
  uint256 totalWorkers;
  uint256 totalSalary;
  Worker[] workers;
}