#!bin/bash

left=()
right=()

filename="./input.txt"

if [[ ! -f "$filename" ]]; then
  echo "File not found"
  exit 1
fi

while IFS= read -r line; do
  # Split by space
  IFS=' ' read -r -a tokens <<< "$line"

  # Append to the arrays.
  left+=($((tokens[0])))
  right+=($((tokens[1])))
done < "$filename"

# Sort
left=($(printf "%s\n" "${left[@]}" | sort -n))
right=($(printf "%s\n" "${right[@]}" | sort -n))

# Function to count occurrences of an entry in an array
count_occurrences() {
  local array=("$@")         # All arguments are considered as the array
  local entry="${array[-1]}" # The last argument is the entry to count
  unset 'array[-1]'          # Remove the last element (the entry to count) from the array

  # Count occurrences
  local count=0
  for item in "${array[@]}"; do
    if [[ "$item" == "$entry" ]]; then
      ((count++))
    fi
  done

  echo "$count"
}

abs() {
  local num=$(($1))
  echo $([ $num -lt 0 ] && echo "$(( -num ))" || echo "$num")
}

total1=0
total2=0
for ((i=0; i < 1000; i++)); do
  left_int="${left[i]}"
  right_int="${right[i]}"

  abs_num=$(abs $((left_int - right_int)))
  total1=$((total1 + abs_num))

  count=$(count_occurrences "${right[@]}" "$left_int")
  total2=$((total2 + left_int * count))
done

echo "P1:" $total1 "P2:" $total2
