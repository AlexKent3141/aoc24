#include <cstdint>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

std::uint64_t concat(std::uint64_t x, std::uint64_t y) {
  std::uint64_t power_of_10 = 1;
  while (y >= power_of_10) power_of_10 *= 10;
  return x * power_of_10 + y;
}

bool can_solve(
  std::uint64_t target,
  const std::vector<int>& operands,
  bool with_concat,
  std::uint64_t current = 0,
  std::size_t offset = 0) {

  if (current == 0) {
    return can_solve(target, operands, with_concat, operands[0], 1);
  }

  if (offset == operands.size()) {
    return current == target;
  }

  if (can_solve(target, operands, with_concat, current * operands[offset], offset + 1)) {
    return true;
  }

  if (can_solve(target, operands, with_concat, current + operands[offset], offset + 1)) {
    return true;
  }

  if (with_concat && can_solve(
        target, operands, with_concat, concat(current, operands[offset]), offset + 1)) {
    return true;
  }

  return false;
}

int main() {
  std::ifstream fs("input.txt");

  std::uint64_t total1 = 0, total2 = 0;
  std::string line;
  while (std::getline(fs, line)) {
    std::istringstream iss(line);

    std::string next;
    iss >> next;
    const auto target = std::stoull(next.substr(0, next.size() - 1));

    std::vector<int> operands;
    while (iss >> next) operands.push_back(std::stoi(next));

    if (can_solve(target, operands, false)) {
      total1 += target;
      total2 += target;
    }
    else if (can_solve(target, operands, true)) {
      total2 += target;
    }
  }

  std::cout << "P1: " << total1 << " P2: " << total2 << "\n";
}
